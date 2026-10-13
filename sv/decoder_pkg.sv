package decoder_pkg;

    // ---- opcodes RV32I ----
    typedef enum logic [6:0] {
        OP_RTYPE  = 7'b0110011,
        OP_ITYPE  = 7'b0010011,
        OP_LOAD   = 7'b0000011,
        OP_STORE  = 7'b0100011,
        OP_BRANCH = 7'b1100011,
        OP_JAL    = 7'b1101111,
        OP_JALR   = 7'b1100111,
        OP_LUI    = 7'b0110111,
        OP_AUIPC  = 7'b0010111,
        OP_FENCE  = 7'b0001111,
        OP_SYSTEM = 7'b1110011
    } opcode_t;

    // ---- valores válidos de funct7 (7 bits completos) ----
    localparam logic [6:0] F7_BASE   = 7'b0000000;
    localparam logic [6:0] F7_ALT    = 7'b0100000;  // SUB, SRA, SRAI
    localparam logic [6:0] F7_MULDIV = 7'b0000001;  // RV32M: div/divu/rem/remu (Práctica 5)

    // ---- códigos de la ALU: { funct7 == F7_ALT, funct3 } ----
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0_000,
        ALU_SUB  = 4'b1_000,
        ALU_SLL  = 4'b0_001,
        ALU_SLT  = 4'b0_010,
        ALU_SLTU = 4'b0_011,
        ALU_XOR  = 4'b0_100,
        ALU_SRL  = 4'b0_101,
        ALU_SRA  = 4'b1_101,
        ALU_OR   = 4'b0_110,
        ALU_AND  = 4'b0_111
    } alu_op_t;

endpackage