/*/ ============================================================================
  Division sin restauracion - arquitectura PARALELA <--> Todo combinacional
  Clk y Valid no se usan (se dejan para que la interfaz sea igual en las 3).
  Numeros SIN signo (el decodificador pasa valores absolutos en div/rem).
================================================================================
*/
module parallel_nrd #(
    parameter int NUMBITS = 32
)(
    input  logic               Clk,        // sin usar
    input  logic [NUMBITS-1:0] Dividendo,
    input  logic [NUMBITS-1:0] Divisor,
    input  logic               Valid,      // sin usar
    output logic [NUMBITS-1:0] Cociente,
    output logic [NUMBITS-1:0] Resto,
    output logic               Ready,
    output logic               Done
);

    logic [NUMBITS:0]   R, B;
    logic [NUMBITS-1:0] C;
    logic               neg;

    always_comb begin
        // Paso 1: cargar (R,C) = P
        B = {1'b0, Divisor};
        R = '0;
        C = Dividendo;

        // Pasos 2-4: n iteraciones (el for se desenrolla en n copias de hardware)
        for (int i = 0; i < NUMBITS; i++) begin
            neg = R[NUMBITS];                     // signo de R antes de desplazar
            R   = {R[NUMBITS-1:0], C[NUMBITS-1]}; // desplazar (R,C) a la izquierda
            C   = {C[NUMBITS-2:0], 1'b0};
            if (neg) R = R + B;                   // R negativo -> sumar B
            else     R = R - B;                   // R positivo -> restar B
            C[0] = ~R[NUMBITS];                   // bit cociente: 1 si R>=0, 0 si R<0
        end

        // Paso 5: correccion del resto
        if (R[NUMBITS]) R = R + B;
    end

    assign Cociente = C;
    assign Resto    = R[NUMBITS-1:0];
    assign Ready    = 1'b1;
    assign Done     = 1'b1;

endmodule
