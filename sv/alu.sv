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

    assign eq  = (op1 == op2);
    assign lt  = ($signed(op1) < $signed(op2));
    assign ltu = (op1 < op2);

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
