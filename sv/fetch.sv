module fetch #(
    parameter int     NUM_BITS  = 32,
    parameter int     ADDR_WIDTH = 17
)(
    input   logic   clk,
    input   logic rst_n,
    output  logic [ADDR_WIDTH-1 : 0] addr_a
);

  //PC va sumando +4 siempre cada ciclo de reloj
  //como con 3 bits llegamos hasta 15 pues ponemos 4
  logic [NUM_BITS-1 : 0] pc;

    always_ff @(posedge clk) begin
        if (!rst_n)
            pc <= '0;
        else
            pc <= pc + 4;
    end 

    //los 2 bits usados para pedir el byte {0, 1, 2, 3} se descartan
    //de ahí el :2
    // **esto de aquí es combinacional**, por qué no ponemos un always_comb??
    assign addr_a = pc[ADDR_WIDTH+1:2];
    //[18 :2] -> 17 bits = ancho de addr_width

    //-------------- Funcionamiento fetch --------------
    // el pc se fuerza a '0'
    // en cada flanco de subida sube +4 de 4 bytes, por qué?
    // porque cada instrucción son 4 bytes, avanzar a la siguiente instr
    // se coge el valor actual de pc (se actualiza de forma comb)
    // se descartan los dos bits menos significativos
    // los bits restantes (17 en este caso) forman addr_a
    // addr_a es el índice de palabra que se envía al puerto A de la memoria



endmodule