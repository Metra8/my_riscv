// Core RV32I.
//
//  Fetch : pc -> addr_a ; la memoria registra la instrucción (IR) al final del ciclo.
//  Exec  : decodificación + lectura de registros + ALU + acceso a memoria de datos
//          + decisión de salto, todo en el ciclo en que la instrucción está en el IR.
//  WB    : (solo loads) el dato llega de la memoria un ciclo después y se escribe
//          por el segundo puerto del banco de registros.
//
// Riesgos:
//  - datos : ALU -> uso inmediato sin reenvío (el banco se escribe en el flanco);
//            load -> uso inmediato con reenvío del dato de write-back (sin paradas).
//  - control: un salto tomado anula (ir_valid = 0) la instrucción buscada tras él.
module core
    import riscv_pkg::*;
#(
    parameter int MEM_WIDTH  = 32,
    parameter int NUM_BYTES  = 4,
    parameter int ADDR_WIDTH = 17
) (
    input logic clk,
    input logic rst_n,

    // puerto A (instrucciones)
    output logic [ADDR_WIDTH-1:0] addr_a,
    output logic [MEM_WIDTH-1:0]  wdata_a,
    input  logic [MEM_WIDTH-1:0]  rdata_a,
    output logic                  we_a,
    output logic [NUM_BYTES-1:0]  be_a,

    // puerto B (datos)
    output logic [ADDR_WIDTH-1:0] addr_b,
    output logic [MEM_WIDTH-1:0]  wdata_b,
    input  logic [MEM_WIDTH-1:0]  rdata_b,
    output logic                  we_b,
    output logic [NUM_BYTES-1:0]  be_b,

    // instrucción ilegal (solo se señaliza, no hay excepción)
    output logic illegal_instr
);

    // ------------------------------------------------------------------
    // señales internas
    // ------------------------------------------------------------------
    logic [MEM_WIDTH-1:0] pc_ir;
    logic                 ir_valid;
    logic                 jump_en;
    logic [MEM_WIDTH-1:0] jump_base, jump_offset;

    logic [MEM_WIDTH-1:0] op1, op2, rs2_val;
    alu_op_t aluop;
    logic reg_write, mem_read, mem_write, is_branch, is_jump;
    logic                 dec_illegal;
    logic [          2:0] funct3;
    logic [          4:0] rd;

    logic [MEM_WIDTH-1:0] alu_result;
    logic alu_eq, alu_lt, alu_ltu;

    // write-back del load
    logic                 ld_valid;
    logic [          4:0] ld_rd;
    logic [          2:0] ld_funct3;
    logic [          1:0] ld_off;
    logic [MEM_WIDTH-1:0] ld_data;

    // ------------------------------------------------------------------
    // etapas
    // ------------------------------------------------------------------
    fetch #(
        .NUM_BITS  (MEM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fetch_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .jump_en    (jump_en),
        .jump_base  (jump_base),
        .jump_offset(jump_offset),
        .addr_a     (addr_a),
        .pc_ir      (pc_ir),
        .ir_valid   (ir_valid)
    );

    decoder #(
        .NUM_BITS(MEM_WIDTH)
    ) decoder_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .instr        (rdata_a),
        .pc_ir        (pc_ir),
        .we_alu       (ir_valid && reg_write && !mem_read),
        .wdata_alu    (alu_result),
        .we_mem       (ld_valid),
        .waddr_mem    (ld_rd),
        .wdata_mem    (ld_data),
        .op1          (op1),
        .op2          (op2),
        .aluop        (aluop),
        .reg_write    (reg_write),
        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .is_branch    (is_branch),
        .is_jump      (is_jump),
        .illegal_instr(dec_illegal),
        .funct3       (funct3),
        .rd           (rd),
        .rs2_val      (rs2_val),
        .jump_base    (jump_base),
        .jump_offset  (jump_offset)
    );

    alu #(
        .NUM_BITS(MEM_WIDTH)
    ) alu_inst (
        .op1   (op1),
        .op2   (op2),
        .aluop (aluop),
        .result(alu_result),
        .eq    (alu_eq),
        .lt    (alu_lt),
        .ltu   (alu_ltu)
    );

    // una instrucción anulada (ir_valid = 0) no tiene ningún efecto ni se cuenta
    assign illegal_instr = dec_illegal && ir_valid;

    // ------------------------------------------------------------------
    // saltos
    // ------------------------------------------------------------------
    logic br_taken;

    always_comb begin
        case (funct3)
            3'b000:  br_taken = alu_eq;  // beq
            3'b001:  br_taken = !alu_eq;  // bne
            3'b100:  br_taken = alu_lt;  // blt
            3'b101:  br_taken = !alu_lt;  // bge
            3'b110:  br_taken = alu_ltu;  // bltu
            3'b111:  br_taken = !alu_ltu;  // bgeu
            default: br_taken = 1'b0;
        endcase
    end

    assign jump_en = ir_valid && (is_jump || (is_branch && br_taken));

    // ------------------------------------------------------------------
    // memoria de datos (puerto B)
    // ------------------------------------------------------------------
    assign addr_b = alu_result[ADDR_WIDTH+1:2];  // dirección de palabra
    assign we_b = ir_valid && mem_write;

    // store: se replica el dato en todos los carriles y se activa el byte-enable
    always_comb begin
        case (funct3[1:0])
            2'b00: begin  // sb
                wdata_b = {4{rs2_val[7:0]}};
                be_b    = NUM_BYTES'(4'b0001 << alu_result[1:0]);
            end
            2'b01: begin  // sh
                wdata_b = {2{rs2_val[15:0]}};
                be_b    = alu_result[1] ? NUM_BYTES'(4'b1100) : NUM_BYTES'(4'b0011);
            end
            default: begin  // sw
                wdata_b = rs2_val;
                be_b    = '1;
            end
        endcase
    end

    // load: la memoria registra rdata_b, así que el dato llega al ciclo siguiente
    always_ff @(posedge clk) begin
        if (!rst_n) ld_valid <= 1'b0;
        else ld_valid <= ir_valid && mem_read;
        ld_rd     <= rd;
        ld_funct3 <= funct3;
        ld_off    <= alu_result[1:0];
    end

    logic [ 7:0] ld_byte;
    logic [15:0] ld_half;

    always_comb begin
        ld_byte = rdata_b[{ld_off, 3'b000}+:8];
        ld_half = rdata_b[{ld_off[1], 4'b0000}+:16];
        case (ld_funct3)
            3'b000:  ld_data = {{(MEM_WIDTH - 8) {ld_byte[7]}}, ld_byte};  // lb
            3'b001:  ld_data = {{(MEM_WIDTH - 16) {ld_half[15]}}, ld_half};  // lh
            3'b100:  ld_data = {{(MEM_WIDTH - 8) {1'b0}}, ld_byte};  // lbu
            3'b101:  ld_data = {{(MEM_WIDTH - 16) {1'b0}}, ld_half};  // lhu
            default: ld_data = rdata_b;  // lw
        endcase
    end

    // puerto A: solo lectura de instrucciones
    assign wdata_a = '0;
    assign we_a    = 1'b0;
    assign be_a    = '0;

    // bits de la dirección que no llegan a la memoria (no hay más memoria)
    logic unused_ok;
    assign unused_ok = &{1'b0, alu_result[MEM_WIDTH-1:ADDR_WIDTH+2]};

endmodule
