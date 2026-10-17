module core #(
    parameter int MEM_WIDTH  = 32,
    parameter int NUM_BYTES  = 4,
    parameter int ADDR_WIDTH = 17
) (
    input logic clk,
    input logic rst_n,

    // puerto A (instrucciones)
    output logic [ADDR_WIDTH-1:0] addr_a,
    output logic [ MEM_WIDTH-1:0] wdata_a,
    input  logic [ MEM_WIDTH-1:0] rdata_a,
    output logic                  we_a,
    output logic [ NUM_BYTES-1:0] be_a,

    // puerto B (datos)
    output logic [ADDR_WIDTH-1:0] addr_b,
    output logic [ MEM_WIDTH-1:0] wdata_b,
    input  logic [ MEM_WIDTH-1:0] rdata_b,
    output logic                  we_b,
    output logic [ NUM_BYTES-1:0] be_b,

    // excepción de instrucción ilegal (solo se señaliza)
    output logic illegal_instr
);

    logic [MEM_WIDTH-1:0] pc_ir;
    logic                 ir_valid;
    logic                 jump_en;
    logic [MEM_WIDTH-1:0] jump_base, jump_offset;

    fetch #(
        .NUM_BITS  (MEM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fetch_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .jump_en    (jump_en),
        .jump_base  (jump_base),
        .jump_offset(jump_offset),
        .addr_a     (addr_a),
        .pc_ir      (pc_ir),
        .ir_valid   (ir_valid)
    );

    decoder #(
        .NUM_BITS  (MEM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) decoder_inst (
        .clk          (clk),
        .rst          (~rst_n),
        .valid        (ir_valid),
        .instr        (rdata_a),
        .pc_ir        (pc_ir),
        .jump_en      (jump_en),
        .jump_base    (jump_base),
        .jump_offset  (jump_offset),
        .addr_b       (addr_b),
        .wdata_b      (wdata_b),
        .rdata_b      (rdata_b),
        .we_b         (we_b),
        .be_b         (be_b),
        .illegal_instr(illegal_instr)
    );

    // puerto A: solo lectura de instrucciones
    assign wdata_a = '0;
    assign we_a    = 1'b0;
    assign be_a    = '0;

endmodule
