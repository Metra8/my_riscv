module alu
    import riscv_pkg::*;
#(
    parameter int NUM_BITS = 32
) (
    input  logic    [NUM_BITS-1:0] op1,
    input  logic    [NUM_BITS-1:0] op2,
    input  alu_op_t                aluop,
    output logic    [NUM_BITS-1:0] result,
    output logic                   eq,      // op1 == op2        (beq/bne)
    output logic                   lt,      // op1 <  op2 signed (blt/bge)
    output logic                   ltu      // op1 <  op2 unsigned (bltu/bgeu)
);

    // restas con un bit extra: el bit más alto da el signo / el acarreo
    logic [NUM_BITS:0] diff_s, diff_u;

    assign diff_u = {1'b0, op1} - {1'b0, op2};
    assign diff_s = {op1[NUM_BITS-1], op1} - {op2[NUM_BITS-1], op2};

    assign eq     = (diff_u[NUM_BITS-1:0] == '0);
    assign lt     = diff_s[NUM_BITS];
    assign ltu    = diff_u[NUM_BITS];

    always_comb begin
        unique case (aluop)
            ALU_ADD:  result = op1 + op2;
            ALU_SUB:  result = op1 - op2;
            ALU_SLL:  result = op1 << op2[4:0];
            ALU_SLT:  result = {{(NUM_BITS - 1) {1'b0}}, lt};
            ALU_SLTU: result = {{(NUM_BITS - 1) {1'b0}}, ltu};
            ALU_XOR:  result = op1 ^ op2;
            ALU_SRL:  result = op1 >> op2[4:0];
            ALU_SRA:  result = $signed(op1) >>> op2[4:0];
            ALU_OR:   result = op1 | op2;
            ALU_AND:  result = op1 & op2;
            default:  result = '0;
        endcase
    end

endmodule
