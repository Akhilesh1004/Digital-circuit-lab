module sram_fish
#(parameter DATA_WIDTH = 8, ADDR_WIDTH = 16, RAM_SIZE = 65536, FILE = "images.mem")
 (input clk, input en,
  input we1,
  input  [ADDR_WIDTH-1 : 0] addr1,
  input  [DATA_WIDTH-1 : 0] data_i1,
  output reg [DATA_WIDTH-1 : 0] data_o1,
  input we2,
  input  [ADDR_WIDTH-1 : 0] addr2,
  input  [DATA_WIDTH-1 : 0] data_i2,
  output reg [DATA_WIDTH-1 : 0] data_o2,
  input we3,
  input  [ADDR_WIDTH-1 : 0] addr3,
  input  [DATA_WIDTH-1 : 0] data_i3,
  output reg [DATA_WIDTH-1 : 0] data_o3);

// Declareation of the memory cells
(* ram_style = "block" *) reg [DATA_WIDTH-1 : 0] RAM [RAM_SIZE - 1:0];

integer idx;

// ------------------------------------
// SRAM cell initialization
// ------------------------------------
// Initialize the sram cells with the values defined in "image.dat."
initial begin
    $readmemh(FILE, RAM);
end

// ------------------------------------
// SRAM read operation
// ------------------------------------
always@(posedge clk)
begin
  if (en & we1)begin
    data_o1 <= data_i1;
     RAM[addr1] <= data_i1;
  end else
    data_o1 <= RAM[addr1];
end

always@(posedge clk)
begin
  if (en & we2)begin
    data_o2 <= data_i2;
     RAM[addr2] <= data_i2;
  end else
    data_o2 <= RAM[addr2];
end

always@(posedge clk)
begin
  if (en & we3)begin
    data_o3 <= data_i3;
     RAM[addr3] <= data_i3;
  end else
    data_o3 <= RAM[addr3];
end
endmodule