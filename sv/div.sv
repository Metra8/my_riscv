
module divisor #(

	parameter int NUMBITS = 32

)(

	input logic [NUMBITS-1:0] 	DIVISOR,
	input logic [NUMBITS-1:0] 	DIVIDEND,
	output logic [NUMBITS-1:0] 	C,
	output logic [NUMBITS-1:0] 	R

);


	logic [NUMBITS-1:0] P;					//REGISTROS DE OPERACION
	logic [NUMBITS-1:0] A;
	assign P = '0;
	assign A = DIVIDEND;


	always_comb						//ALGORITMO DE DIVISION CON RESTAURACION, SE REPITE NUMBITS VECES
	begin

		for (int i = 0; i < NUMBITS; i++) begin

			P = P << 1;				//DESPLAZAMIENTO DEL PAR DE REGISTROS P:A
			P[0] = A[NUMBITS-1];
			A = A << 1;
			P = P - DIVISOR;			//RESTAR DIVISOR DE P

			if (P[NUMBITS-1] == 1) begin		//LSB DE A ES 0 CUANDO EL RESULTADO ES NEGATIVO, SE HACE RESTAURACION
				A[0] = 0;
				P = P + DIVISOR;
			end else begin				//LSB DE A ES 1 CUANDO EL RESULTADO NO ES NEGATIVO
				A[0] = 1;
			end

		end
	end

	assign C = A;
	assign R = P;


endmodule

