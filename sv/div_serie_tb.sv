
module div_serie_tb #(

parameter int NUMBITS = 32

);

	logic               Clk;
	logic [NUMBITS-1:0] Dividendo;
    	logic [NUMBITS-1:0] Divisor;
    	logic               Valid;
   	logic [NUMBITS-1:0] Cociente;
   	logic [NUMBITS-1:0] Resto;
    	logic               Ready;
	logic               Done;

	serial_nrd divisorserie (

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
		Dividendo = 32'(17);
		Divisor = 32'(3);
		$display("Dividendo = %0d ; Divisor = %0d", Dividendo, Divisor);
		Valid = 1'b1;
		#10 Valid = 1'b0;

	end

	initial begin
		$monitor("Cociente: %0d ; Resto: %0d ; tiempo: %0t", Cociente, Resto, $time);
	end


	initial begin

		Clk = 1'b0;
		forever begin
		#5 Clk = ~Clk;
		end
	end

	property endodiv (Done);
	@(posedge Clk) ((Valid == 1'b0) |-> (Done == 1'b0));
	endproperty

	assert property(endodiv(Done))
	else $stop;

endmodule
