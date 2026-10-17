module decoder
    import riscv_pkg::*;
#(
    parameter int NUM_BITS = 32
) (
    input logic clk,
    input logic rst_n,

    input logic [NUM_BITS-1:0] instr,  // IR: rdata_a
    input logic [NUM_BITS-1:0] pc_ir,  // PC de la instrucción del IR

    // escritura del resultado de la ALU (instrucción del IR, ya validada por el core)
    input logic                we_alu,
    input logic [NUM_BITS-1:0] wdata_alu,

    // write-back de un load (instrucción anterior). Además de escribir en el
    // banco, se REENVÍA a los operandos: así un load seguido de una instrucción
    // que usa su resultado no necesita parada.
    input logic                we_mem,
    input logic [         4:0] waddr_mem,
    input logic [NUM_BITS-1:0] wdata_mem,

    output logic    [NUM_BITS-1:0] op1,
    output logic    [NUM_BITS-1:0] op2,
    output alu_op_t                aluop,

    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic is_branch,
    output logic is_jump,
    output logic illegal_instr,

    output logic [2:0] funct3,
    output logic [4:0] rd,

    // dato a guardar en un store (rs2 reenviado)
    output logic [NUM_BITS-1:0] rs2_val,

    // destino de salto = jump_base + jump_offset (la suma la hace fetch)
    output logic [NUM_BITS-1:0] jump_base,
    output logic [NUM_BITS-1:0] jump_offset
);

    // extracción de campos fijos
    opcode_t opcode;
    logic [4:0] rs1_addr, rs2_addr;
    logic [6:0] funct7;
    logic       alt;  // funct7 == 0100000 (SUB, SRA, SRAI)

    assign opcode   = opcode_t'(instr[6:0]);
    assign rd       = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7   = instr[31:25];
    assign alt      = (funct7 == F7_ALT);

    // generación del inmediato
    logic [NUM_BITS-1:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm;

    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    always_comb begin
        case (opcode)
            OP_ITYPE, OP_LOAD, OP_JALR: imm = imm_i;
            OP_STORE:                   imm = imm_s;
            OP_BRANCH:                  imm = imm_b;
            OP_LUI, OP_AUIPC:           imm = imm_u;
            OP_JAL:                     imm = imm_j;
            default:                    imm = imm_i;
        endcase
    end

    // ---- banco de registros ----
    logic [NUM_BITS-1:0] rdata1, rdata2;

    regfile #(
        .NUM_BITS(NUM_BITS)
    ) regfile_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .rs1      (rs1_addr),
        .rs2      (rs2_addr),
        .rd1      (rdata1),
        .rd2      (rdata2),
        .we_alu   (we_alu),
        .waddr_alu(rd),
        .wdata_alu(wdata_alu),
        .we_mem   (we_mem),
        .waddr_mem(waddr_mem),
        .wdata_mem(wdata_mem)
    );

    // ---- reenvío del write-back del load (riesgo de datos load-uso) ----
    // El resultado de una ALU se escribe en el flanco y lo ve la instrucción
    // siguiente; el de un load llega un ciclo más tarde, así que se reenvía.
    logic [NUM_BITS-1:0] rs1_val;

    assign rs1_val = (we_mem && waddr_mem != 5'd0 && waddr_mem == rs1_addr) ? wdata_mem : rdata1;
    assign rs2_val = (we_mem && waddr_mem != 5'd0 && waddr_mem == rs2_addr) ? wdata_mem : rdata2;

    // ---- operandos de la ALU ----
    always_comb begin
        case (opcode)
            OP_LUI:                    op1 = '0;
            OP_AUIPC, OP_JAL, OP_JALR: op1 = pc_ir;
            default:                   op1 = rs1_val;
        endcase

        case (opcode)
            OP_RTYPE, OP_BRANCH: op2 = rs2_val;
            OP_JAL, OP_JALR:     op2 = NUM_BITS'(4);  // dirección de retorno = pc_ir + 4
            default:             op2 = imm;
        endcase
    end

    // ---- destino de salto: branch/jal = pc + imm ; jalr = rs1 + imm ----
    assign jump_base   = (opcode == OP_JALR) ? rs1_val : pc_ir;
    assign jump_offset = imm;

    // código de operación de la ALU: { funct7 == 0100000, funct3 }
    always_comb begin
        case (opcode)
            OP_RTYPE: aluop = alu_op_t'({alt, funct3});
            // en tipo I el bit "alt" solo cuenta en los shifts a la derecha
            OP_ITYPE:
            aluop = (funct3 == 3'b101) ? alu_op_t'({alt, funct3}) : alu_op_t'({1'b0, funct3});
            OP_BRANCH: aluop = ALU_SUB;  // eq/lt/ltu salen de la comparación
            default: aluop = ALU_ADD;  // load, store, jal, jalr, lui, auipc
        endcase
    end

    // ---- CONTROL ----
    logic legal;

    always_comb begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        is_branch = 1'b0;
        is_jump   = 1'b0;
        legal     = 1'b1;

        case (opcode)
            OP_RTYPE: begin
                reg_write = 1'b1;
                // funct7=0000000 para todas; 0100000 solo SUB/SRA.
                // Cualquier otro funct7 es ilegal (incluido RV32M, 0000001)
                legal = (funct7 == F7_BASE) || (alt && (funct3 == 3'b000 || funct3 == 3'b101));
            end

            OP_ITYPE: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b001:  legal = (funct7 == F7_BASE);  // SLLI
                    3'b101:  legal = (funct7 == F7_BASE) || alt;  // SRLI / SRAI
                    default: legal = 1'b1;  // addi, slti, sltiu, xori, ori, andi
                endcase
            end

            OP_LOAD: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                legal     = (funct3 inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101});  // lb lh lw lbu lhu
            end

            OP_STORE: begin
                mem_write = 1'b1;
                legal     = (funct3 inside {3'b000, 3'b001, 3'b010});  // sb sh sw
            end

            OP_BRANCH: begin
                is_branch = 1'b1;
                legal     = !(funct3 inside {3'b010, 3'b011});  // beq bne blt bge bltu bgeu
            end

            OP_JAL: begin
                reg_write = 1'b1;
                is_jump   = 1'b1;
            end

            OP_JALR: begin
                reg_write = 1'b1;
                is_jump   = 1'b1;
                legal     = (funct3 == 3'b000);
            end

            OP_LUI, OP_AUIPC: reg_write = 1'b1;

            // FENCE: legal, sin efecto en este diseño
            OP_FENCE: legal = (funct3 == 3'b000);

            // ECALL / EBREAK: legales pero sin efecto
            OP_SYSTEM: legal = (instr[31:21] == 11'b0) && (instr[19:7] == 13'b0);

            default: legal = 1'b0;
        endcase

        illegal_instr = !legal;

        // una instrucción ilegal no tiene efecto
        if (!legal) begin
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            is_branch = 1'b0;
            is_jump   = 1'b0;
        end
    end

endmodule
