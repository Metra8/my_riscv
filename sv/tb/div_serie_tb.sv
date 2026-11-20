module div_serie_tb #(parameter int NUMBITS = 32);

    logic               Clk = 1'b0;
    logic               Valid = 1'b0;
    logic [NUMBITS-1:0] Dividendo = '0, Divisor = '1;
    logic [NUMBITS-1:0] Cociente, Resto;
    logic               Ready, Done;

    int errores = 0;

    serial_nrd #(.NUMBITS(NUMBITS)) dut (
        .Clk(Clk), .Dividendo(Dividendo), .Divisor(Divisor), .Valid(Valid),
        .Cociente(Cociente), .Resto(Resto), .Ready(Ready), .Done(Done)
    );

    // Reloj
    always #5 Clk = ~Clk;

    // Lanza una division, espera a Done y compara
    task automatic dividir(input logic [NUMBITS-1:0] a, input logic [NUMBITS-1:0] b);
        @(negedge Clk);
        wait (Ready);                       // no empezar si esta ocupado
        Dividendo = a;
        Divisor   = b;
        Valid     = 1'b1;
        @(negedge Clk);                     // Valid dura un ciclo (flanco de carga en medio)
        Valid     = 1'b0;
        wait (Done === 1'b1);               // Done sube al terminar (se pone a 0 al cargar)
        #1;
        if (Cociente !== a / b || Resto !== a % b) begin
            errores++;
            $display("ERROR: %0d / %0d -> C=%0d R=%0d (esperado C=%0d R=%0d) t=%0t",
                     a, b, Cociente, Resto, a / b, a % b, $time);
        end else begin
            $display("OK:    %0d / %0d -> C=%0d R=%0d t=%0t", a, b, Cociente, Resto, $time);
        end
    endtask

    initial begin
        $display("TEST INICIADO");

        dividir(NUMBITS'(17),    NUMBITS'(3));
        dividir(NUMBITS'(69560), NUMBITS'(3356));
        dividir(NUMBITS'(0),     NUMBITS'(5));
        dividir(NUMBITS'(3),     NUMBITS'(7));
        dividir('1,              NUMBITS'(1));
        dividir('1,              '1);

        repeat (50) begin
            logic [NUMBITS-1:0] a, b;
            a = NUMBITS'($urandom);
            b = NUMBITS'($urandom);
            if (b == 0) b = 1;
            dividir(a, b);
        end

        if (errores == 0) $display("TEST OK: todo correcto");
        else              $display("TEST FALLIDO: %0d errores", errores);
        $finish;
    end

    // Watchdog por si Done no llega nunca
    initial begin
        #10_000_000;
        $display("TIMEOUT: Done no llego");
        $finish;
    end

    // Ready debe estar a 0 mientras divide: tras cargar, Ready baja hasta Done
    assert property (@(posedge Clk) (Valid && Ready) |=> !Ready)
        else $error("Ready no baja tras aceptar una division");

endmodule
