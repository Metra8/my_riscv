module div_seg_tb #(parameter int NUMBITS = 32);

    localparam int N = 8;   // divisiones que se envian seguidas

    logic               Clk = 1'b0;
    logic               Valid = 1'b0;
    logic [NUMBITS-1:0] Dividendo = '0, Divisor = 1;
    logic [NUMBITS-1:0] Cociente, Resto;
    logic               Ready, Done;

    // Casos de prueba (divisores distintos de 0)
    logic [NUMBITS-1:0] a_t [N] = '{17, 69560, 0, 3, 100, 255, 1000000, 12345};
    logic [NUMBITS-1:0] b_t [N] = '{3, 3356,   5, 7, 10,  16,  999,     1};

    int k = 0;         // resultados recibidos
    int errores = 0;

    pipeline_nrd #(.NUMBITS(NUMBITS)) dut (
        .Clk(Clk), .Dividendo(Dividendo), .Divisor(Divisor), .Valid(Valid),
        .Cociente(Cociente), .Resto(Resto), .Ready(Ready), .Done(Done)
    );

    always #5 Clk = ~Clk;

    // Envio: una division por ciclo, sin huecos
    initial begin
        $display("TEST INICIADO");
        @(negedge Clk);
        for (int i = 0; i < N; i++) begin
            Dividendo = a_t[i];
            Divisor   = b_t[i];
            Valid     = 1'b1;
            @(negedge Clk);
        end
        Valid = 1'b0;

        // Esperar a que salgan todas
        repeat (NUMBITS + 5) @(posedge Clk);

        if (k != N) begin
            errores++;
            $display("ERROR: esperaba %0d resultados y llegaron %0d", N, k);
        end
        if (errores == 0) $display("TEST OK");
        else              $display("TEST FALLIDO: %0d errores", errores);
        $finish;
    end

    // Recepcion: cada Done=1 es el siguiente resultado, en el mismo orden
    always @(posedge Clk) begin
        if (Done && k < N) begin
            if (Cociente !== a_t[k] / b_t[k] || Resto !== a_t[k] % b_t[k]) begin
                errores++;
                $display("ERROR: %0d / %0d -> C=%0d R=%0d (esperado C=%0d R=%0d)",
                         a_t[k], b_t[k], Cociente, Resto, a_t[k] / b_t[k], a_t[k] % b_t[k]);
            end else begin
                $display("OK:    %0d / %0d -> C=%0d R=%0d", a_t[k], b_t[k], Cociente, Resto);
            end
            k++;
        end
    end

endmodule
