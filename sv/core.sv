module core #(
    parameter int MEM_WIDTH  = 32,
    parameter int NUM_BYTES  = 4,
    parameter int ADDR_WIDTH = 17
)(
    input  logic                     clk,
    input  logic                     rst_n,

    // puerto A (instrucciones)
    output logic [ADDR_WIDTH-1:0]    addr_a,
    output logic [MEM_WIDTH-1:0]     wdata_a,
    input  logic [MEM_WIDTH-1:0]     rdata_a,
    output logic                     we_a,
    output logic [NUM_BYTES-1:0]     be_a,

    // puerto B (datos)
    output logic [ADDR_WIDTH-1:0]    addr_b,
    output logic [MEM_WIDTH-1:0]     wdata_b,
    input  logic [MEM_WIDTH-1:0]     rdata_b,
    output logic                     we_b,
    output logic [NUM_BYTES-1:0]     be_b
);

    fetch #(
        .NUM_BITS   (MEM_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) fetch_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .addr_a (addr_a)
    );

    // puerto A: nada escribe instrucciones todavía
    assign wdata_a = '0;
    assign we_a    = 1'b0;
    assign be_a    = '0;

    // puerto B: sin uso hasta el "DecExe"
    assign addr_b  = '0;
    assign wdata_b = '0;
    assign we_b    = 1'b0;
    assign be_b    = '0;

endmodule