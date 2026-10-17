// Testbench del sistema: core + memoria (doble puerto).
// El programa termina escribiendo en el "mailbox" (dirección de byte 0x10000):
//   0x900D -> PASS ; cualquier otro valor -> nº del test que ha fallado.
module riscv_tb #(
    parameter int    MEM_WIDTH  = 32,
    parameter int    NUM_BYTES  = 4,
    parameter int    ADDR_WIDTH = 17,
    parameter string HEX_FILE   = "hex/program.hex",
    parameter int    MAX_CYCLES = 20000,
    // nº de instrucciones ilegales (válidas) que debe señalizar el programa
    parameter int    EXPECT_ILLEGAL = 0
) ();

    localparam logic [ADDR_WIDTH-1:0] MAILBOX_ADDR = ADDR_WIDTH'('h10000 >> 2);
    localparam logic [ MEM_WIDTH-1:0] PASS_VALUE   = 32'h0000_900D;

    logic clk;
    logic rst_n;

    // puerto A (instrucciones)
    logic [ADDR_WIDTH-1:0] addr_a;
    logic [MEM_WIDTH-1:0] wdata_a, rdata_a;
    logic                  we_a;
    logic [ NUM_BYTES-1:0] be_a;
    // puerto B (datos)
    logic [ADDR_WIDTH-1:0] addr_b;
    logic [MEM_WIDTH-1:0] wdata_b, rdata_b;
    logic                 we_b;
    logic [NUM_BYTES-1:0] be_b;

    logic                 illegal_instr;

    core #(
        .MEM_WIDTH (MEM_WIDTH),
        .NUM_BYTES (NUM_BYTES),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) RISCV_CORE (
        .clk          (clk),
        .rst_n        (rst_n),
        .addr_a       (addr_a),
        .wdata_a      (wdata_a),
        .rdata_a      (rdata_a),
        .we_a         (we_a),
        .be_a         (be_a),
        .addr_b       (addr_b),
        .wdata_b      (wdata_b),
        .rdata_b      (rdata_b),
        .we_b         (we_b),
        .be_b         (be_b),
        .illegal_instr(illegal_instr)
    );

    memory #(
        .MEM_WIDTH (MEM_WIDTH),
        .NUM_BYTES (NUM_BYTES),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INIT_FILE (HEX_FILE)
    ) RISCV_MEM (
        .clk    (clk),
        .addr_a (addr_a),
        .wdata_a(wdata_a),
        .rdata_a(rdata_a),
        .we_a   (we_a),
        .be_a   (be_a),
        .addr_b (addr_b),
        .wdata_b(wdata_b),
        .rdata_b(rdata_b),
        .we_b   (we_b),
        .be_b   (be_b)
    );

    // reloj: 100 MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // reset: activo en bajo durante 4 ciclos
    initial begin
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        #1 rst_n = 1'b1;
    end

    // instrucción ilegal: se cuenta (solo se señaliza, no hay excepción)
    int illegal_count;
    always @(posedge clk)
        if (!rst_n) illegal_count <= 0;
        else if (illegal_instr) begin
            illegal_count <= illegal_count + 1;
            $display("[%0t] AVISO: instruccion ilegal en pc=0x%08h", $time,
                     RISCV_CORE.fetch_inst.pc_ir);
        end

    // fin de programa: mailbox + comprobación del nº de ilegales
    always @(posedge clk) begin
        if (we_b && addr_b == MAILBOX_ADDR) begin
            if (wdata_b != PASS_VALUE) $display("[%0t] *** FAIL: test %0d ***", $time, wdata_b);
            else if (illegal_count != EXPECT_ILLEGAL)
                $display(
                    "[%0t] *** FAIL: %0d ilegales (esperadas %0d) ***",
                    $time,
                    illegal_count,
                    EXPECT_ILLEGAL
                );
            else $display("[%0t] *** PASS ***", $time);
            $finish;
        end
    end

    // timeout
    initial begin
        repeat (MAX_CYCLES) @(posedge clk);
        $display("*** TIMEOUT: el programa no ha terminado ***");
        $finish;
    end

endmodule
