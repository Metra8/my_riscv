module regfile #(
    parameter int     NUM_BITS  = 32,
    parameter int NUM_REGS  = 32
)(
    input   logic                     clk,
    input   logic                     rst,
    //reg source
    input   logic [4:0]               rs1,
    input   logic [4:0]               rs2,
    //reg destination
    output  logic [NUM_BITS-1 : 0]    rd1,
    output  logic [NUM_BITS-1 : 0]    rd2,

    //doble puerto:
    //** debe diseñar dos interfaces de escritura independientes, uno para
    //** escribir el resultado de la ejecución y otro para escribir el dato
    //** de instrucciones load en la etapa de write-back

    //alu (ejecución)
    input  logic                  we_alu,
    input  logic [4:0]            waddr_alu,
    input  logic [NUM_BITS-1:0]   wdata_alu,

    //load (write-back)
    input  logic                  we_mem,
    input  logic [4:0]            waddr_mem,
    input  logic [NUM_BITS-1:0]   wdata_mem
    
);
    
    //registro de [32][32]
    logic [NUM_BITS-1 : 0] register [NUM_REGS-1 : 0];

    //escritura síncrona (memoria persistente)-
    always_ff @(posedge clk) begin
        if (rst) begin
            //técnicamente aquí no hace falta begin/end
            for (int i = 0; i < NUM_REGS; i++) begin
                register[i] <= '0;
            end
        end else begin
            if (we_alu) register[waddr_alu] <= wdata_alu;
            if (we_mem) register[waddr_mem] <= wdata_mem;
        end
    end

    //lectura combinacional (sin reloj)
    //para asignaciones simples no hace falta always_comb
    //si nos piden el registro '0' damos x0 (siempre '0's)
    assign rd1 = (rs1 == '0) ? '0 : register[rs1];
    assign rd2 = (rs2 == '0) ? '0 : register[rs2];

endmodule