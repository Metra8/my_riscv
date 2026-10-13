
import decoder_pkg::*;

module alu #(

    parameter int NUM_BITS = 32

)(

	input logic [NUM_BITS : 0] 	op1,
	input logic [NUM_BITS : 0] 	op2,
	input alu_op_t			aluop,

	output logic [NUM_BITS : 0]	result,
	output logic 			eq,	//resultado es 0
	output logic			lt,	//resultado es < 0 (complemento a 2)
	output logic			ltu	//resultado es < 0 (operandos sin signo)

);


	always_comb
	begin

		unique case(aluop)
		
		ALU_ADD: begin
			
			result = op1 + op2;

		end
		
		ALU_SUB: begin

			result = op1 - op2;

		end

		ALU_SLL: begin

			result = op1 << op2;

		end

		ALU_SRL: begin

			result = op1 >> op2;

		end

		ALU_SRA: begin

			result = op1 >>> op2;

		end

		ALU_SLT: begin

			result = (op1 < 2)?1:0;

		end

		ALU_SLTU: begin

			result = (op1 < 2)?1:0;

		end
		endcase

	end


endmodule