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

    // excepción de instrucción ilegal (solo se señaliza)
    output logic illegal_instr
);

    logic [MEM_WIDTH-1:0] pc_ir;
    logic                 ir_valid;
    logic                 jump_en;
    logic [MEM_WIDTH-1:0] jump_base, jump_offset;


    logic [MEM_WIDTH-1:0] op1, op2;
    alu_op_t       aluop;
    logic          reg_write;
    logic          mem_read;
    logic          mem_write;
    logic          is_branch;
    logic          is_jump;
    logic    [2:0] funct3;
    logic    [4:0] rd;
    // ----------------------------------------------

    fetch #(
        .NUM_BITS  (MEM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fetch_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .jump_en(       jump_en),
        .jump_base(     jump_base),
        .jump_offset    (jump_offset),
        .addr_a         (addr_a),
        .pc_ir(         pc_ir),
        .ir_valid       (ir_valid)
    );

    decoder #(
        .NUM_BITS(MEM_WIDTH)
    ) decoder_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .instr         (rdata_a),
        .pc_ir         (pc_ir),
        .op1           (op1),
        .op2           (op2),
        .aluop         (aluop),
        .reg_write     (reg_write),
        .mem_read      (mem_read),
        .mem_write     (mem_write),
        .is_branch     (is_branch),
        .is_jump       (is_jump),
        .illegal_instr (illegal_instr),
        .funct3        (funct3),
        .rd            (rd)
    );

    // saltos: aún sin implementar (TODO P3: el destino vendrá de la ALU / decoder)
    assign jump_en     = 1'b0;
    assign jump_base   = '0;
    assign jump_offset = '0;

    // puerto B (datos): aún sin implementar (TODO P3/P4: load/store)
    assign addr_b      = '0;
    assign wdata_b     = '0;
    assign we_b        = 1'b0;
    assign be_b        = '0;

    // señales que todavía no consume ninguna etapa (borrar al conectarlas)
    logic unused_ok;
    assign unused_ok = &{1'b0, rdata_b, ir_valid, op1, op2, aluop, reg_write, mem_read,
                         mem_write, is_branch, is_jump, funct3, rd};

    // puerto A: solo lectura de instrucciones
    assign wdata_a = '0;
    assign we_a = 1'b0;
    assign be_a = '0;

endmodule
