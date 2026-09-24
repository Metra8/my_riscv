module memory #(
    parameter int     MEM_WIDTH  = 32,
    parameter int     NUM_BYTES  = 4,
    parameter int     ADDR_WIDTH = 17,
    //idealmente el hex file se pasa en el tb
    parameter string  INIT_FILE = "" 
) (
    input logic clk,

    //instrucciones
    input  logic [ADDR_WIDTH-1 : 0] addr_a,
    input  logic [ MEM_WIDTH-1 : 0] wdata_a,
    output logic [ MEM_WIDTH-1 : 0] rdata_a,
    input  logic                    we_a,
    input  logic [ NUM_BYTES-1 : 0] be_a,

    //datos
    input  logic [ADDR_WIDTH-1 : 0] addr_b,
    input  logic [ MEM_WIDTH-1 : 0] wdata_b,
    output logic [ MEM_WIDTH-1 : 0] rdata_b,
    input  logic                    we_b,
    input  logic [ NUM_BYTES-1 : 0] be_b
);

  // memoria en sí, tamaño de 2^addr_width -1, cada elemento de tamaño
  // mem width-1; se escribe así porque el tamaño es unpacked pero el
  // tamaño de cada elemento es packed
  logic [MEM_WIDTH-1 : 0] mem[0 : (2**(ADDR_WIDTH) -1)];
  // [MEM_WIDTH-1 : 0] es packed, [0 : (2**(ADDR_WIDTH) -1)] es unpacked

  //precarga con fichero (opcional)
  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end


  // cosas que tiene que tener:
  // El tamaño total de la memoria es 2** ADDR_WIDTH x MEM_WIDTH
  // los dos puertos disponen de we
  // permite lectura y escritura (rdata y wdata)

  always_ff @(posedge clk) begin
    // instrucciones
    if (we_a) begin
      // no suele usarse be en instrucciones normalmente, siempre escribes
      // la instr completa
      for (int i = 0; i < NUM_BYTES; i++) begin
        if (be_a[i]) begin
          mem[addr_a][i*8+:8] <= wdata_a[i*8+:8];
          // +: es el operador de part-select indexado, de forma que:
          // vector[base + ancho -1 : base] = vector[base +: ancho]
          // de normal sería:
          // mem[addr_a][i*8 + 8 - 1 : i*8]; con i=0, i=1:
          // mem[addr_a][7:0]; mem[addr_a][15:8];
        end
      end
      rdata_a <= mem[addr_a];
    end

  // datos
    if (we_b) begin
      for (int i = 0; i < NUM_BYTES; i++) begin
        if (be_b[i]) begin
          mem[addr_b][i*8+:8] <= wdata_b[i*8+:8];
        end
      end
    end
    rdata_b <= mem[addr_b];

  end

endmodule
