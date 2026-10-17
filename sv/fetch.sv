module fetch #(
    parameter int NUM_BITS   = 32,
    parameter int ADDR_WIDTH = 17
) (
    input logic clk,
    input logic rst_n,

    //saltos: destino = base + offset
    input logic                  jump_en,
    input logic [NUM_BITS-1 : 0] jump_base,
    input logic [NUM_BITS-1 : 0] jump_offset,

    output logic [ADDR_WIDTH-1 : 0] addr_a,
    //pc instruction register
    output logic [  NUM_BITS-1 : 0] pc_ir
);

    //PC va sumando +4 siempre cada ciclo de reloj
    //como con 3 bits llegamos hasta 15 pues ponemos 4
    //pc_ir_ir es pc_ir pero registered (_r)
    logic [NUM_BITS-1 : 0] pc, pc_ir_r, pc_next;
    logic [NUM_BITS-1 : 0] jump_target;

    //bit 0 a 0 jalr
    assign jump_target = (jump_base + jump_offset) & ~NUM_BITS'(1);
    assign pc_next = jump_en ? NUM_BITS'(jump_target) : pc + NUM_BITS'(4);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc <= '0;
            pc_ir_r <= '0;
        end else begin
            pc <= pc + 4;
            pc_ir_r <= pc;
        end
    end

    //los 2 bits usados para pedir el byte {0, 1, 2, 3} se descartan
    //de ahí el :2
    // **esto de aquí es combinacional**
    assign addr_a = pc[ADDR_WIDTH+1:2];
    //[18 :2] -> 17 bits = ancho de addr_width
    assign pc_ir  = NUM_BITS'(pc_ir_r);

    //-------------- Funcionamiento fetch --------------
    // el pc se fuerza a '0'
    // en cada flanco de subida sube +4 de 4 bytes, por qué?
    // porque cada instrucción son 4 bytes, avanzar a la siguiente instr
    // se coge el valor actual de pc (se actualiza de forma comb)
    // se descartan los dos bits menos significativos
    // los bits restantes (17 en este caso) forman addr_a
    // addr_a es el índice de palabra que se envía al puerto A de la memoria
endmodule
