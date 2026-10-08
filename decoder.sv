module decoder
    import decoder_pkg::*;
#(
    parameter int NUM_BITS = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic [NUM_BITS-1:0]   instr,   // IR: rdata_a
    input  logic [NUM_BITS-1:0]   pc_ir,   // output pc

    output logic [NUM_BITS-1:0]   op1,
    output logic [NUM_BITS-1:0]   op2,
    output alu_op_t               aluop,

    output logic                  reg_write,
    output logic                  mem_read,
    output logic                  mem_write,
    output logic                  is_branch,
    output logic                  is_jump,
    output logic                  illegal_instr,

    output logic [2:0]            funct3,
    output logic [4:0]            rd
);

    // extracción de campos fijos
    opcode_t    opcode;
    logic [4:0] rs1_addr, rs2_addr;
    logic [6:0] funct7;
    // simplificar funct7
    logic       alt;        // funct7 == 0100000 (SUB, SRA, SRAI)

    // seguir formato de instrucciones para reg
    assign opcode   = opcode_t'(instr[6:0]);
    assign rd       = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7   = instr[31:25];
    assign alt      = (funct7 == F7_ALT);

    // generación del inmediato
    logic [NUM_BITS-1:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm;

    // extensión de signo
    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    // asignación
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

    // lectura del banco de registros
    logic [NUM_BITS-1:0] rdata1, rdata2;

    regfile #(
        .NUM_BITS (NUM_BITS)
    ) regfile_inst (
        .clk        (clk),
        .rst        (rst),
        .rs1        (rs1_addr),
        .rs2        (rs2_addr),
        .rd1        (rdata1),
        .rd2        (rdata2),
        // TODO (P3): conectar al resultado real de la ALU / dato de load
        .we_alu     (1'b0),
        .waddr_alu  (rd),
        .wdata_alu  ('0),
        .we_mem     (1'b0),
        .waddr_mem  (rd),
        .wdata_mem  ('0)
    );

    // ---- ALU ----

    // selección de operandos futura ALU
    always_comb begin
        case (opcode)
            OP_LUI:                    op1 = '0;
            OP_AUIPC, OP_JAL, OP_JALR: op1 = pc_ir;
            default:                   op1 = rdata1;
        endcase

        case (opcode)
            OP_RTYPE, OP_BRANCH: op2 = rdata2;
            OP_JAL, OP_JALR:     op2 = 32'd4;   // dirección de retorno = pc_ir + 4
            default:             op2 = imm;
        endcase
    end

    // código de operación de la ALU: { funct7 == 0100000, funct3 }
    always_comb begin
        case (opcode)
            OP_RTYPE:  aluop = alu_op_t'({alt, funct3});
            // en tipo I el bit "alt" solo cuenta en los shifts a la derecha;
            // en el resto forma parte del inmediato (addi no puede volverse sub)
            OP_ITYPE:  aluop = (funct3 == 3'b101) ? alu_op_t'({alt, funct3})
                                                  : alu_op_t'({1'b0, funct3});
            OP_BRANCH: aluop = ALU_SUB;   // eq/lt/ltu salen de la resta (Práctica 3)
            default:   aluop = ALU_ADD;   // load, store, jal, jalr, lui, auipc
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
                // ADD/SLL/SLT/SLTU/XOR/SRL/OR/AND con funct7=0000000,
                // SUB/SRA con funct7=0100000. Cualquier otro funct7 es ilegal
                // (incluido 0000001: RV32M, se añadirá en la Práctica 5)
                legal = (funct7 == F7_BASE) ||
                        (alt && (funct3 == 3'b000 || funct3 == 3'b101));
            end

            OP_ITYPE: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b001:  legal = (funct7 == F7_BASE);            // SLLI
                    3'b101:  legal = (funct7 == F7_BASE) || alt;     // SRLI / SRAI
                    default: legal = 1'b1;                           // addi, slti, sltiu, xori, ori, andi
                endcase
            end

            OP_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                legal     = (funct3 inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101}); // lb lh lw lbu lhu
            end

            OP_STORE: begin
                mem_write = 1'b1;
                legal     = (funct3 inside {3'b000, 3'b001, 3'b010});                  // sb sh sw
            end

            OP_BRANCH: begin
                is_branch = 1'b1;
                legal     = !(funct3 inside {3'b010, 3'b011});                         // beq bne blt bge bltu bgeu
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
            OP_FENCE:  legal = (funct3 == 3'b000);

            // ECALL / EBREAK: legales pero sin efecto
            OP_SYSTEM: legal = (instr[31:21] == 11'b0) && (instr[19:7] == 13'b0);

            default:   legal = 1'b0;
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