/*============================================================================
Division sin restauracion - arquitectura SEGMENTADA
Latencia n ciclos, una division nueva por ciclo.
Cada etapa lleva su propio B y su bit de validez (sin estado
global). Done es un pulso por resultado.
Numeros SIN signo (el decodificador pasa valores absolutos en div/rem).
==============================================================================
*/
module pipeline_nrd #(
    parameter int NUMBITS = 32
)(
    input  logic               Clk,
    input  logic [NUMBITS-1:0] Dividendo,
    input  logic [NUMBITS-1:0] Divisor,
    input  logic               Valid,
    output logic [NUMBITS-1:0] Cociente,
    output logic [NUMBITS-1:0] Resto,
    output logic               Ready,
    output logic               Done
);

    // Registros de salida de cada etapa
    logic [NUMBITS:0]   Rq [0:NUMBITS-1];
    logic [NUMBITS-1:0] Cq [0:NUMBITS-1];
    logic [NUMBITS:0]   Bq [0:NUMBITS-1];
    logic               Vq [0:NUMBITS-1];

    initial for (int k = 0; k < NUMBITS; k++) Vq[k] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < NUMBITS; i++) begin : g_etapa

            // Entradas de la etapa
            logic [NUMBITS:0]   Rin, Bin;
            logic [NUMBITS-1:0] Cin;
            logic               Vin;

            if (i == 0) begin : g_entrada          // paso 1: (R,C) = P
                assign Rin = '0;
                assign Cin = Dividendo;
                assign Bin = {1'b0, Divisor};
                assign Vin = Valid;
            end else begin : g_interna             // viene de la etapa anterior
                assign Rin = Rq[i-1];
                assign Cin = Cq[i-1];
                assign Bin = Bq[i-1];
                assign Vin = Vq[i-1];
            end

            // Una iteracion (pasos 2 y 3), combinacional
            logic [NUMBITS:0]   Rsh, Rout;
            logic [NUMBITS-1:0] Cout;

            always_comb begin
                Rsh = {Rin[NUMBITS-1:0], Cin[NUMBITS-1]};
                if (Rin[NUMBITS]) Rout = Rsh + Bin;
                else              Rout = Rsh - Bin;
                Cout = {Cin[NUMBITS-2:0], ~Rout[NUMBITS]};
            end

            // Registro de segmentacion
            always_ff @(posedge Clk) begin
                Rq[i] <= Rout;
                Cq[i] <= Cout;
                Bq[i] <= Bin;
                Vq[i] <= Vin;
            end
        end
    endgenerate

    // Salidas, con el paso 5 (correccion del resto)
    logic [NUMBITS:0] Rfin;
    assign Rfin     = Rq[NUMBITS-1][NUMBITS] ? (Rq[NUMBITS-1] + Bq[NUMBITS-1]) : Rq[NUMBITS-1];
    assign Cociente = Cq[NUMBITS-1];
    assign Resto    = Rfin[NUMBITS-1:0];
    assign Done     = Vq[NUMBITS-1];
    assign Ready    = 1'b1;

endmodule
