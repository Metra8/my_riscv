
include fetch.sv;

module RISCV_Core #(

	parameter int MEM_WIDTH=32,
	parameter int ADDR_WIDTH=17,
	parameter int NUM_BYTES=4

)(

	input logic clk,
	input logic rst_n,

	//Puertos de instrucciones

	output logic [ADDR_WIDTH-1 : 0] addr_ins,
	output logic [MEM_WIDTH-1 : 0] wdata_ins,
	input logic [MEM_WIDTH-1 : 0] rdata_ins,
	output logic we_ins,
	output logic [NUM_BYTES : 0] be_ins,

	//Puertos de datos

	output logic [ADDR_WIDTH-1 : 0] addr_dat,
	output logic [MEM_WIDTH-1 : 0] wdata_dat,
	input logic [MEM_WIDTH-1 : 0] rdata_dat,
	output logic we_dat,
	output logic [NUM_BYTES : 0] be_dat

);

	//Instanciacion del fetch

	fetch #() RISCV_FETCH(

		.clk(clk),
		.rst_n(rst_n),
		.addr_a(addr_ins)
	
	);


endmodule

