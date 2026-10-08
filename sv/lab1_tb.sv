
module fetch_tb #(

    parameter int MEM_WIDTH  = 32,
    parameter int NUM_BYTES  = 4,
    parameter int ADDR_WIDTH = 17

)(

);


	//definicion de señales de interconexion

	logic clk;
	logic reset;
    	logic [ADDR_WIDTH-1 : 0] addr;
	logic [ MEM_WIDTH-1 : 0] wdata;
	logic [ MEM_WIDTH-1 : 0] rdata;
	logic                    we;
	logic [ NUM_BYTES-1 : 0] be;
	
	//Instanciacion y conexionado de core y memoria

	core #(.MEM_WIDTH(MEM_WIDTH), .NUM_BYTES(NUM_BYTES), .ADDR_WIDTH(ADDR_WIDTH))

	RISCV_CORE (

		.clk(clk),
		.rst_n(reset),
		.addr_a(addr),
		.wdata_a(wdata),
		.rdata_a(rdata),
		.we_a(we),
		.be_a(be)

	);

	memory #(.MEM_WIDTH(MEM_WIDTH), .NUM_BYTES(NUM_BYTES), .ADDR_WIDTH(ADDR_WIDTH))

	RISCV_MEM (

		.clk(clk),
		.addr_a(addr),
		.wdata_a(wdata),
		.rdata_a(rdata),
		.we_a(we),
		.be_a(be)

	);


	//generacion de señal de reloj
	//conmuta clk cada 5 ns, fclk = 100 MHz

	always #5 clk = ~clk;


endmodule