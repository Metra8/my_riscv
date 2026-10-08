//Bus generico a memoria

interface membus #(

    	parameter int     MEM_WIDTH  = 32,
    	parameter int     NUM_BYTES  = 4,
    	parameter int     ADDR_WIDTH = 17
	
	)(
	

	logic [ADDR_WIDTH-1 : 0] addr,
    	logic [ MEM_WIDTH-1 : 0] wdata,
    	logic [ MEM_WIDTH-1 : 0] rdata,
    	logic                    we,
    	logic [ NUM_BYTES-1 : 0] be

);

endinterface: membus
