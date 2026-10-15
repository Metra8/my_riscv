import riscv_pkg::*;

module alu
#(
    parameter int NUM_BITS = 32
)(

	input logic [NUM_BITS-1:0] 	op1,
	input logic [NUM_BITS-1:0] 	op2,
	input alu_op_t				aluop,
	input logic					Cin,	//Carry In

	output logic [NUM_BITS-1:0]	result,
	output logic 				eq,		//resultado es 0
	output logic				lt,		//resultado es < 0 (complemento a 2)
	output logic				ltu,	//resultado es < 0 (operandos sin signo)
	output logic				Cout,
	output logic				Ov		//Overflow
);

// Operaciones con un bit extra (NUM_BITS + 1)
    logic [NUM_BITS:0] ext_op1_u, ext_op2_u, res_sub_u; // Sin signo
    logic [NUM_BITS:0] ext_op1_s, ext_op2_s, res_sub_s; // Con signo (complemento a 2)

    // Extensión sin signo (añadiendo un 0 a la izquierda)
    assign ext_op1_u = {1'b0, op1};
    assign ext_op2_u = {1'b0, op2};
    assign res_sub_u = ext_op1_u - ext_op2_u;

    // Extensión con signo (repitiendo el bit más significativo / bit de signo)
    assign ext_op1_s = {op1[NUM_BITS-1], op1};
    assign ext_op2_s = {op2[NUM_BITS-1], op2};
    assign res_sub_s = ext_op1_s - ext_op2_s;

    // Cálculo de las señales de salto / comparación
    assign eq  = (result == '0);
    assign ltu = res_sub_u[NUM_BITS]; // El bit extra indica si hubo préstamo (borrow)
    assign lt  = res_sub_s[NUM_BITS]; // El bit extra indica el signo del resultado extendido

	//En esencia, un 1 en el bit extra de res_sub_s indica que op1 < op2 en complemento a 2, mientras que un 1 en el bit extra de res_sub_u indica que op1 < op2 sin signo.

always_comb begin
    unique case(aluop) //usamos unique porque estamos seguros de que aluop no puede tomar otros valores

        ALU_ADD: result = op1 + op2;

        ALU_SUB: result = op1 - op2;

        ALU_SLL: result = op1 << op2[4:0];   //shift logical - RISCV especifica que el max shift es 31 por lo que solo tomamos 5 bits

        ALU_SRL: result = op1 >> op2[4:0];   //shift logical - RISCV especifica que el max shift es 31 por lo que solo tomamos 5 bits

        ALU_SLT: result = { {NUM_BITS-1{1'b0}}, lt }; //complemento a dos

        ALU_SLTU: result = { {NUM_BITS-1{1'b0}}, ltu }; //unsigned

        ALU_XOR: result = op1 ^ op2;

        ALU_SRA: result = $signed(op1) >>> op2[4:0];   //shift aritmético con el operando >>> - primero convertimos el operando a signed para preservar el signo.
        ALU_OR: result = op1 | op2;

        ALU_AND: result = op1 & op2;

		default: result = '0; // Valor por defecto para evitar latches
	endcase
end
endmodule