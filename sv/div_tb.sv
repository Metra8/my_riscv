
module div_tb #(parameter int NUMBITS = 32);

	logic               Clk;
	logic [NUMBITS-1:0] Dividendo;
    	logic [NUMBITS-1:0] Divisor;
    	logic               Valid;
   	logic [NUMBITS-1:0] Cociente;
   	logic [NUMBITS-1:0] Resto;
    	logic               Ready;
	logic               Done;

	parallel_nrd divisorparalelo (

		.Clk(Clk),
		.Dividendo(Dividendo),
		.Divisor(Divisor),
		.Valid(Valid),
		.Cociente(Cociente),
		.Resto(Resto),
		.Ready(Ready),
		.Done(Done)
	);


	initial begin

		$display("TEST INICIADO");
		Dividendo = 32'(69560);
		Divisor = 32'(3356);
		$display("Dividendo = %0d ; Divisor = %0d", Dividendo, Divisor);
	end
	initial begin
		$monitor("Cociente: %0d ; Resto: %0d ; tiempo: %0t", Cociente, Resto, $time);
	end

endmodule
