module div_parallel_tb #(parameter int NUMBITS = 32);

    logic               Clk = 1'b0;     // no se usa en el paralelo
    logic               Valid = 1'b0;   // no se usa en el paralelo
    logic [NUMBITS-1:0] Dividendo, Divisor;
    logic [NUMBITS-1:0] Cociente, Resto;
    logic               Ready, Done;

    int errores = 0;

    parallel_nrd #(.NUMBITS(NUMBITS)) dut (
        .Clk(Clk), .Dividendo(Dividendo), .Divisor(Divisor), .Valid(Valid),
        .Cociente(Cociente), .Resto(Resto), .Ready(Ready), .Done(Done)
    );

    // Aplica una division y compara con los operadores / y %
    task automatic probar(input logic [NUMBITS-1:0] a, input logic [NUMBITS-1:0] b);
        Dividendo = a;
        Divisor   = b;
        #1;  // es combinacional: basta con esperar un poco
        if (Cociente !== a / b || Resto !== a % b) begin
            errores++;
            $display("ERROR: %0d / %0d -> C=%0d R=%0d (esperado C=%0d R=%0d)",
                     a, b, Cociente, Resto, a / b, a % b);
        end else begin
            $display("OK:    %0d / %0d -> C=%0d R=%0d", a, b, Cociente, Resto);
        end
    endtask

    initial begin
        $display("TEST INICIADO");

        // Casos dirigidos
        probar(NUMBITS'(69560), NUMBITS'(3356));
        probar(NUMBITS'(17),    NUMBITS'(3));
        probar(NUMBITS'(0),     NUMBITS'(5));
        probar(NUMBITS'(5),     NUMBITS'(5));
        probar(NUMBITS'(3),     NUMBITS'(7));      // dividendo < divisor
        probar('1,              NUMBITS'(1));      // maximo / 1
        probar('1,              '1);               // maximo / maximo
        probar({1'b1, {(NUMBITS-1){1'b0}}}, NUMBITS'(3));

        // Casos aleatorios (divisor distinto de 0)
        repeat (200) begin
            logic [NUMBITS-1:0] a, b;
            a = NUMBITS'($urandom);
            b = NUMBITS'($urandom);
            if (b == 0) b = 1;
            probar(a, b);
        end

        if (errores == 0) $display("TEST OK: todo correcto");
        else              $display("TEST FALLIDO: %0d errores", errores);
        $finish;
    end

endmodule
