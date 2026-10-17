module fetch #(
    parameter int NUM_BITS   = 32,
    parameter int ADDR_WIDTH = 17
) (
    input logic clk,
    input logic rst_n,

    // saltos: destino = base + offset (lo calcula el decodificador)
    input logic                  jump_en,
    input logic [NUM_BITS-1 : 0] jump_base,
    input logic [NUM_BITS-1 : 0] jump_offset,

    output logic [ADDR_WIDTH-1 : 0] addr_a,
    // PC de la instrucción que hay ahora mismo en el IR (rdata_a)
    output logic [  NUM_BITS-1 : 0] pc_ir,
    // 1 = la instrucción del IR es válida; 0 = anulada (hueco de salto / arranque)
    output logic                    ir_valid
);

    logic [NUM_BITS-1 : 0] pc, pc_ir_r, pc_next;
    logic [NUM_BITS-1 : 0] jump_target;

    // el bit 0 se fuerza a 0 (necesario en jalr; en el resto ya es 0)
    assign jump_target = (jump_base + jump_offset) & {{(NUM_BITS - 1) {1'b1}}, 1'b0};
    assign pc_next     = jump_en ? jump_target : pc + NUM_BITS'(4);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc       <= '0;
            pc_ir_r  <= '0;
            ir_valid <= 1'b0;
        end else begin
            pc       <= pc_next;  // [FIX] antes: pc + 4 -> los saltos no hacían nada
            pc_ir_r  <= pc;  // PC de la instrucción que llegará al IR
            // Riesgo de control: la instrucción que se está buscando en este ciclo
            // es la secuencial (pc+4) y llegará al IR en el siguiente. Si hay salto,
            // hay que anularla.
            ir_valid <= !jump_en;
        end
    end

    // combinacional: índice de palabra (se descartan los 2 bits de byte)
    assign addr_a = pc[ADDR_WIDTH+1:2];
    assign pc_ir  = pc_ir_r;

    //-------------- Funcionamiento fetch --------------
    // ciclo t   : pc = A+4 -> addr_a -> la memoria registra rdata_a (IR) al final del ciclo
    //             mientras tanto se ejecuta la instrucción A (en el IR)
    // si A salta: pc <= destino, y la instrucción A+4 que entra en el IR queda con
    //             ir_valid = 0 (se decodifica pero sin efectos)
    // arranque  : tras el reset el IR contiene mem[0] pero aún no es "nueva":
    //             ir_valid = 0 evita ejecutar la instrucción 0 dos veces.
endmodule
