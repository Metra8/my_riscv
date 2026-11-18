/*============================================================================
Division sin restauracion - arquitectura SERIE <--> ciclos por division.
Numeros SIN signo (el decodificador pasa valores absolutos en div/rem).
==============================================================================
*/
module serial_nrd #(
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

    // Registro (R,C): R = n+1 bits con signo, C = n bits. B = divisor en n+1 bits.
    logic [NUMBITS:0]   R, B;
    logic [NUMBITS-1:0] C;
    logic [$clog2(NUMBITS)-1:0] cnt;
    logic busy = 1'b0;
    initial Done = 1'b0;

    // ---- Una iteracion (pasos 2 y 3), combinacional ----
    logic [NUMBITS:0]   Rsh, Rn;
    logic [NUMBITS-1:0] Cn;

    always_comb begin
        Rsh = {R[NUMBITS-1:0], C[NUMBITS-1]};     // desplazar (R,C) a la izquierda
        if (R[NUMBITS]) Rn = Rsh + B;             // R negativo -> sumar B
        else            Rn = Rsh - B;             // R positivo -> restar B
        Cn = {C[NUMBITS-2:0], ~Rn[NUMBITS]};      // bit cociente: 1 si R>=0, 0 si R<0
    end

    // ---- Control ----
    assign Ready = ~busy;

    always_ff @(posedge Clk) begin
        if (Valid && Ready) begin                 // paso 1: cargar (R,C) = P
            R    <= '0;
            C    <= Dividendo;
            B    <= {1'b0, Divisor};
            cnt  <= '0;
            busy <= 1'b1;
            Done <= 1'b0;
        end else if (busy) begin                  // pasos 2-4
            R   <= Rn;
            C   <= Cn;
            cnt <= cnt + 1'b1;
            if (cnt == NUMBITS-1) begin
                busy <= 1'b0;
                Done <= 1'b1;                     // se mantiene hasta la siguiente division
            end
        end
    end

    // ---- Salidas, con el paso 5 (correccion del resto) ----
    logic [NUMBITS:0] Rfin;
    assign Rfin     = R[NUMBITS] ? (R + B) : R;
    assign Cociente = C;
    assign Resto    = Rfin[NUMBITS-1:0];

endmodule
