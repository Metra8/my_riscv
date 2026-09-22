module memory #(
    parameter int MEM_WIDTH = 32,
    parameter int NUM_BYTES = 4,
    parameter int ADDR_WIDTH = 17,
)(
    input   logic                       clk,
    //instrucciones
    input   logic [ADDR_WIDTH-1 : 0]    addr_a,
    input   logic [MEM_WIDTH-1 : 0]     wdata_a,
    output  logic [MEM_WIDTH-1 : 0]     rdata_a,
    input   logic                       we_a,
    input   logic [3:0]                 be_a,

    //datos
    input   logic [ADDR_WIDTH-1 : 0]    addr_b,
    input   logic [MEM_WIDTH-1 : 0]     wdata_b,
    output  logic [MEM_WIDTH-1 : 0]     rdata_b,
    input   logic                       we_b,
    input   logic [3:0]                 be_b

    logic [MEM_WIDTH-1 : 0] mem [0 : (2**(ADDR_WIDTH) -1)];

);
    
endmodule

//cosas que tiene que tener
//El tamaño total de la memoria es 2** ADDR_WIDTH x MEM_WIDTH
//los dos puertos disponen de we (está hecho)
//permite lectura y escritura (rdata y wdata) (ya está hecho)

always_ff @(posedge clk ) begin

    //instrucciones
    if (we_a) begin
       //no hay be en instrucciones
        for(int i = 0; i<NUM_BYTES; i++) begin
            if (be_a[i]) begin
                mem[addr_a][i*8 +:8]
                //+: es el operador de part-select indexado, de forma que:
                //vector[base + ancho -1 : base]
            end
        end
    end
    
    //datos


end
