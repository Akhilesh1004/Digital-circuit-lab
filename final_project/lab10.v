`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
wire  [3 * 20 * 14 :0] stage_out;
wire [1:0] score;
reg [1:0] diff;
reg start;
wire over;
reg  [7:0] move_x, move_y;
wire [7:0]  grid_x, grid_y;
wire [3:0] char_x, char_y;
reg  prev_btn_level, prev_btn_level1, prev_btn_level2, prev_btn_level3;


// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(

wire [16:0] sram_addr_bg;
wire [11:0] data_in;
wire [11:0] data_out_bg;
wire        sram_we, sram_en;
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram_bg (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_bg), .data_i(data_in), .data_o(data_out_bg));
// End of the SRAM memory block.
// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

assign grid_x = pixel_x >> 5;
assign grid_y = pixel_y >> 5;
assign char_x = pixel_x[4:1];
assign char_y = pixel_y[4:1];
assign sram_we = usr_btn[2]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_bg = (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.

localparam space = 0, Sc = 1, cc = 2, oc = 3, rc = 4, ec = 5, dotdot = 6, zero = 7, one = 8, two = 9, three = 10, four = 11, 
           five = 12, six = 13, seven = 14, eight = 15, nine = 16, Ec = 17, Ac = 18, Yc = 19, Hc = 20, Dc = 21, Wc = 22,
           Nc = 23, Oc = 24, Rc = 25, Mc = 26, Lc = 27, Gc = 28, Tc = 29, Vc = 30;


snake snek
(
.clk(clk),
.start(start),
.usr_btn(usr_btn),
.rst(reset_n),
.diff(diff),

.stage_out(stage_out),
.scorechange(score),
.over(over)
);

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;
reg [15:0] font [30:0][15:0]; // 16x16 font bitmaps for ASCII characters
reg [4:0] char_code [54:0];
reg [15:0] apple [15:0];
reg [15:0] body [15:0];
reg [15:0] head [15:0];

initial begin
    start = 0;
    // ' '
    font[space][0]  = 16'b0000000000000000;
    font[space][1]  = 16'b0000000000000000;
    font[space][2]  = 16'b0000000000000000;
    font[space][3]  = 16'b0000000000000000;
    font[space][4]  = 16'b0000000000000000;
    font[space][5]  = 16'b0000000000000000;
    font[space][6]  = 16'b0000000000000000;
    font[space][7]  = 16'b0000000000000000;
    font[space][8]  = 16'b0000000000000000;
    font[space][9]  = 16'b0000000000000000;
    font[space][10] = 16'b0000000000000000;
    font[space][11] = 16'b0000000000000000;
    font[space][12] = 16'b0000000000000000;
    font[space][13] = 16'b0000000000000000;
    font[space][14] = 16'b0000000000000000;
    font[space][15] = 16'b0000000000000000;
     // 'S'
    font[Sc][0]  = 16'b0000000000000000;
    font[Sc][1]  = 16'b0000111111100000;
    font[Sc][2]  = 16'b0001111111110000;
    font[Sc][3]  = 16'b0011100000111000;
    font[Sc][4]  = 16'b0011100000000000;
    font[Sc][5]  = 16'b0011111111100000;
    font[Sc][6]  = 16'b0001111111110000;
    font[Sc][7]  = 16'b0000000001111000;
    font[Sc][8]  = 16'b0000000000111000;
    font[Sc][9]  = 16'b0000000000111000;
    font[Sc][10] = 16'b0011100001111000;
    font[Sc][11] = 16'b0011111111110000;
    font[Sc][12] = 16'b0001111111100000;
    font[Sc][13] = 16'b0000000000000000;
    font[Sc][14] = 16'b0000000000000000;
    font[Sc][15] = 16'b0000000000000000;
    
    // 'c'
    font[cc][0]  = 16'b0000000000000000;
    font[cc][1]  = 16'b0000000000000000;
    font[cc][2]  = 16'b0000000000000000;
    font[cc][3]  = 16'b0000111111100000;
    font[cc][4]  = 16'b0001111111110000;
    font[cc][5]  = 16'b0011100000111000;
    font[cc][6]  = 16'b0011000000000000;
    font[cc][7]  = 16'b0011000000000000;
    font[cc][8]  = 16'b0011100000111000;
    font[cc][9]  = 16'b0001111111110000;
    font[cc][10] = 16'b0000111111100000;
    font[cc][11] = 16'b0000000000000000;
    font[cc][12] = 16'b0000000000000000;
    font[cc][13] = 16'b0000000000000000;
    font[cc][14] = 16'b0000000000000000;
    font[cc][15] = 16'b0000000000000000;

    // 'o'
    font[oc][0]  = 16'b0000000000000000;
    font[oc][1]  = 16'b0000000000000000;
    font[oc][2]  = 16'b0000000000000000;
    font[oc][3]  = 16'b0000111111100000;
    font[oc][4]  = 16'b0001111111110000;
    font[oc][5]  = 16'b0011100000111000;
    font[oc][6]  = 16'b0011000000011000;
    font[oc][7]  = 16'b0011000000011000;
    font[oc][8]  = 16'b0011000000011000;
    font[oc][9]  = 16'b0011100000111000;
    font[oc][10] = 16'b0001111111110000;
    font[oc][11] = 16'b0000111111100000;
    font[oc][12] = 16'b0000000000000000;
    font[oc][13] = 16'b0000000000000000;
    font[oc][14] = 16'b0000000000000000;
    font[oc][15] = 16'b0000000000000000;

    // 'r'
    font[rc][0]  = 16'b0000000000000000;
    font[rc][1]  = 16'b0000000000000000;
    font[rc][2]  = 16'b0000000000000000;
    font[rc][3]  = 16'b0011101110000000;
    font[rc][4]  = 16'b0011111111110000;
    font[rc][5]  = 16'b0011110000110000;
    font[rc][6]  = 16'b0011000000000000;
    font[rc][7]  = 16'b0011000000000000;
    font[rc][8]  = 16'b0011000000000000;
    font[rc][9]  = 16'b0011000000000000;
    font[rc][10] = 16'b0011000000000000;
    font[rc][11] = 16'b0000000000000000;
    font[rc][12] = 16'b0000000000000000;
    font[rc][13] = 16'b0000000000000000;
    font[rc][14] = 16'b0000000000000000;
    font[rc][15] = 16'b0000000000000000;

    // 'e'
    font[ec][0]  = 16'b0000000000000000;
    font[ec][1]  = 16'b0000000000000000;
    font[ec][2]  = 16'b0000000000000000;
    font[ec][3]  = 16'b0000111111100000;
    font[ec][4]  = 16'b0001111111110000;
    font[ec][5]  = 16'b0011100000111000;
    font[ec][6]  = 16'b0011111111111000;
    font[ec][7]  = 16'b0011111111111000;
    font[ec][8]  = 16'b0011000000000000;
    font[ec][9]  = 16'b0011100000111000;
    font[ec][10] = 16'b0001111111110000;
    font[ec][11] = 16'b0000111111100000;
    font[ec][12] = 16'b0000000000000000;
    font[ec][13] = 16'b0000000000000000;
    font[ec][14] = 16'b0000000000000000;
    font[ec][15] = 16'b0000000000000000;

    // ':'
    font[dotdot][0]  = 16'b0000000000000000;
    font[dotdot][1]  = 16'b0000000000000000;
    font[dotdot][2]  = 16'b0000000000000000;
    font[dotdot][3]  = 16'b0000110000000000;
    font[dotdot][4]  = 16'b0000110000000000;
    font[dotdot][5]  = 16'b0000000000000000;
    font[dotdot][6]  = 16'b0000000000000000;
    font[dotdot][7]  = 16'b0000110000000000;
    font[dotdot][8]  = 16'b0000110000000000;
    font[dotdot][9]  = 16'b0000000000000000;
    font[dotdot][10] = 16'b0000000000000000;
    font[dotdot][11] = 16'b0000000000000000;
    font[dotdot][12] = 16'b0000000000000000;
    font[dotdot][13] = 16'b0000000000000000;
    font[dotdot][14] = 16'b0000000000000000;
    font[dotdot][15] = 16'b0000000000000000;
     // '0'
    font[zero][0]  = 16'b0000000000000000;
    font[zero][1]  = 16'b0000111111100000;
    font[zero][2]  = 16'b0001111111110000;
    font[zero][3]  = 16'b0011100000111000;
    font[zero][4]  = 16'b0011100000111000;
    font[zero][5]  = 16'b0011001100011000;
    font[zero][6]  = 16'b0011001100011000;
    font[zero][7]  = 16'b0011000000011000;
    font[zero][8]  = 16'b0011000000011000;
    font[zero][9]  = 16'b0011001100011000;
    font[zero][10] = 16'b0011001100011000;
    font[zero][11] = 16'b0011100000111000;
    font[zero][12] = 16'b0001111111110000;
    font[zero][13] = 16'b0000111111100000;
    font[zero][14] = 16'b0000000000000000;
    font[zero][15] = 16'b0000000000000000;

    // '1'
    font[one][0]  = 16'b0000000000000000;
    font[one][1]  = 16'b0000001100000000;
    font[one][2]  = 16'b0000111100000000;
    font[one][3]  = 16'b0001111100000000;
    font[one][4]  = 16'b0011001100000000;
    font[one][5]  = 16'b0000001100000000;
    font[one][6]  = 16'b0000001100000000;
    font[one][7]  = 16'b0000001100000000;
    font[one][8]  = 16'b0000001100000000;
    font[one][9]  = 16'b0000001100000000;
    font[one][10] = 16'b0000001100000000;
    font[one][11] = 16'b0011111111100000;
    font[one][12] = 16'b0011111111100000;
    font[one][13] = 16'b0000000000000000;
    font[one][14] = 16'b0000000000000000;
    font[one][15] = 16'b0000000000000000;

    // '2'
    font[two][0]  = 16'b0000000000000000;
    font[two][1]  = 16'b0001111111000000;
    font[two][2]  = 16'b0011111111100000;
    font[two][3]  = 16'b0110000000110000;
    font[two][4]  = 16'b0110000000110000;
    font[two][5]  = 16'b0000000000110000;
    font[two][6]  = 16'b0000000001100000;
    font[two][7]  = 16'b0000000011000000;
    font[two][8]  = 16'b0000000111000000;
    font[two][9]  = 16'b0000001110000000;
    font[two][10] = 16'b0000011100000000;
    font[two][11] = 16'b0011111111110000;
    font[two][12] = 16'b0011111111110000;
    font[two][13] = 16'b0000000000000000;
    font[two][14] = 16'b0000000000000000;
    font[two][15] = 16'b0000000000000000;

    // '3'
    font[three][0]  = 16'b0000000000000000;
    font[three][1]  = 16'b0001111111000000;
    font[three][2]  = 16'b0011111111100000;
    font[three][3]  = 16'b0110000000110000;
    font[three][4]  = 16'b0110000000110000;
    font[three][5]  = 16'b0000000000110000;
    font[three][6]  = 16'b0000011111110000;
    font[three][7]  = 16'b0000011111110000;
    font[three][8]  = 16'b0000000000111000;
    font[three][9]  = 16'b0110000000111000;
    font[three][10] = 16'b0110000000111000;
    font[three][11] = 16'b0110000000110000;
    font[three][12] = 16'b0011111111100000;
    font[three][13] = 16'b0001111111000000;
    font[three][14] = 16'b0000000000000000;
    font[three][15] = 16'b0000000000000000;

    // '4'
    font[four][0]  = 16'b0000000000000000;
    font[four][1]  = 16'b0000000011100000;
    font[four][2]  = 16'b0000000111100000;
    font[four][3]  = 16'b0000001111100000;
    font[four][4]  = 16'b0000011011100000;
    font[four][5]  = 16'b0000110011100000;
    font[four][6]  = 16'b0001100011100000;
    font[four][7]  = 16'b0011000011100000;
    font[four][8]  = 16'b0111111111111000;
    font[four][9]  = 16'b0111111111111000;
    font[four][10] = 16'b0000000011100000;
    font[four][11] = 16'b0000000011100000;
    font[four][12] = 16'b0000000011100000;
    font[four][13] = 16'b0000000000000000;
    font[four][14] = 16'b0000000000000000;
    font[four][15] = 16'b0000000000000000;

    // '5'
    font[five][0]  = 16'b0000000000000000;
    font[five][1]  = 16'b0011111111100000;
    font[five][2]  = 16'b0011111111100000;
    font[five][3]  = 16'b0011100000000000;
    font[five][4]  = 16'b0011100000000000;
    font[five][5]  = 16'b0011111111000000;
    font[five][6]  = 16'b0011111111100000;
    font[five][7]  = 16'b0000000001110000;
    font[five][8]  = 16'b0000000000111000;
    font[five][9]  = 16'b0000000000111000;
    font[five][10] = 16'b0110000000111000;
    font[five][11] = 16'b0110000001110000;
    font[five][12] = 16'b0011111111100000;
    font[five][13] = 16'b0001111111000000;
    font[five][14] = 16'b0000000000000000;
    font[five][15] = 16'b0000000000000000;

    // '6'
    font[six][0]  = 16'b0000000000000000;
    font[six][1]  = 16'b0000111111000000;
    font[six][2]  = 16'b0011111111100000;
    font[six][3]  = 16'b0011100001110000;
    font[six][4]  = 16'b0111000000110000;
    font[six][5]  = 16'b0111000000000000;
    font[six][6]  = 16'b0111111111000000;
    font[six][7]  = 16'b0111111111100000;
    font[six][8]  = 16'b0111000000111000;
    font[six][9]  = 16'b0111000000011000;
    font[six][10] = 16'b0111000000011000;
    font[six][11] = 16'b0011100000111000;
    font[six][12] = 16'b0011111111110000;
    font[six][13] = 16'b0000111111100000;
    font[six][14] = 16'b0000000000000000;
    font[six][15] = 16'b0000000000000000;

    // '7'
    font[seven][0]  = 16'b0000000000000000;
    font[seven][1]  = 16'b0111111111110000;
    font[seven][2]  = 16'b0111111111110000;
    font[seven][3]  = 16'b0000000000110000;
    font[seven][4]  = 16'b0000000001110000;
    font[seven][5]  = 16'b0000000011100000;
    font[seven][6]  = 16'b0000000111000000;
    font[seven][7]  = 16'b0000001110000000;
    font[seven][8]  = 16'b0000011100000000;
    font[seven][9]  = 16'b0000111000000000;
    font[seven][10] = 16'b0001110000000000;
    font[seven][11] = 16'b0011100000000000;
    font[seven][12] = 16'b0011100000000000;
    font[seven][13] = 16'b0000000000000000;
    font[seven][14] = 16'b0000000000000000;
    font[seven][15] = 16'b0000000000000000;

    // '8'
    font[eight][0]  = 16'b0000000000000000;
    font[eight][1]  = 16'b0000111111100000;
    font[eight][2]  = 16'b0011111111110000;
    font[eight][3]  = 16'b0011100000111000;
    font[eight][4]  = 16'b0011100000111000;
    font[eight][5]  = 16'b0011111111110000;
    font[eight][6]  = 16'b0000111111100000;
    font[eight][7]  = 16'b0011111111110000;
    font[eight][8]  = 16'b0011100000111000;
    font[eight][9]  = 16'b0011100000111000;
    font[eight][10] = 16'b0011100000111000;
    font[eight][11] = 16'b0011111111110000;
    font[eight][12] = 16'b0000111111100000;
    font[eight][13] = 16'b0000000000000000;
    font[eight][14] = 16'b0000000000000000;
    font[eight][15] = 16'b0000000000000000;

    // '9'
    font[nine][0]  = 16'b0000000000000000;
    font[nine][1]  = 16'b0000111111100000;
    font[nine][2]  = 16'b0011111111110000;
    font[nine][3]  = 16'b0011100000111000;
    font[nine][4]  = 16'b0111000000111000;
    font[nine][5]  = 16'b0111000000111000;
    font[nine][6]  = 16'b0011100001111000;
    font[nine][7]  = 16'b0011111111111000;
    font[nine][8]  = 16'b0001111110111000;
    font[nine][9]  = 16'b0000000000111000;
    font[nine][10] = 16'b0000000001110000;
    font[nine][11] = 16'b0011100011110000;
    font[nine][12] = 16'b0011111111100000;
    font[nine][13] = 16'b0000111111000000;
    font[nine][14] = 16'b0000000000000000;
    font[nine][15] = 16'b0000000000000000;
    
     // 'E'
    font[Ec][0]  = 16'b0000000000000000;
    font[Ec][1]  = 16'b0011111111110000;
    font[Ec][2]  = 16'b0011111111110000;
    font[Ec][3]  = 16'b0011000000000000;
    font[Ec][4]  = 16'b0011000000000000;
    font[Ec][5]  = 16'b0011111111100000;
    font[Ec][6]  = 16'b0011111111100000;
    font[Ec][7]  = 16'b0011000000000000;
    font[Ec][8]  = 16'b0011000000000000;
    font[Ec][9]  = 16'b0011000000000000;
    font[Ec][10] = 16'b0011111111110000;
    font[Ec][11] = 16'b0011111111110000;
    font[Ec][12] = 16'b0000000000000000;
    font[Ec][13] = 16'b0000000000000000;
    font[Ec][14] = 16'b0000000000000000;
    font[Ec][15] = 16'b0000000000000000;

    // 'A'
    font[Ac][0]  = 16'b0000000000000000;
    font[Ac][1]  = 16'b0000001110000000;
    font[Ac][2]  = 16'b0000011111000000;
    font[Ac][3]  = 16'b0000110011100000;
    font[Ac][4]  = 16'b0001100000110000;
    font[Ac][5]  = 16'b0011000000011000;
    font[Ac][6]  = 16'b0011000000011000;
    font[Ac][7]  = 16'b0111111111111100;
    font[Ac][8]  = 16'b0111111111111100;
    font[Ac][9]  = 16'b0110000000001100;
    font[Ac][10] = 16'b0110000000001100;
    font[Ac][11] = 16'b0110000000001100;
    font[Ac][12] = 16'b0000000000000000;
    font[Ac][13] = 16'b0000000000000000;
    font[Ac][14] = 16'b0000000000000000;
    font[Ac][15] = 16'b0000000000000000;
    
     // 'Y'
    font[Yc][0]  = 16'b0000000000000000;
    font[Yc][1]  = 16'b0110000000110000;
    font[Yc][2]  = 16'b0111000001110000;
    font[Yc][3]  = 16'b0011100011100000;
    font[Yc][4]  = 16'b0001110111000000;
    font[Yc][5]  = 16'b0000111110000000;
    font[Yc][6]  = 16'b0000011100000000;
    font[Yc][7]  = 16'b0000011100000000;
    font[Yc][8]  = 16'b0000011100000000;
    font[Yc][9]  = 16'b0000011100000000;
    font[Yc][10] = 16'b0000011100000000;
    font[Yc][11] = 16'b0000011100000000;
    font[Yc][12] = 16'b0000000000000000;
    font[Yc][13] = 16'b0000000000000000;
    font[Yc][14] = 16'b0000000000000000;
    font[Yc][15] = 16'b0000000000000000;
    
    font[Hc][0]  = 16'b0000000000000000;
    font[Hc][1]  = 16'b0011000000011000;
    font[Hc][2]  = 16'b0011000000011000;
    font[Hc][3]  = 16'b0011000000011000;
    font[Hc][4]  = 16'b0011000000011000;
    font[Hc][5]  = 16'b0011111111111000;
    font[Hc][6]  = 16'b0011111111111000;
    font[Hc][7]  = 16'b0011000000011000;
    font[Hc][8]  = 16'b0011000000011000;
    font[Hc][9]  = 16'b0011000000011000;
    font[Hc][10] = 16'b0011000000011000;
    font[Hc][11] = 16'b0011000000011000;
    font[Hc][12] = 16'b0000000000000000;
    font[Hc][13] = 16'b0000000000000000;
    font[Hc][14] = 16'b0000000000000000;
    font[Hc][15] = 16'b0000000000000000;
    
    
    font[Dc][0]  = 16'b0000000000000000;
    font[Dc][1]  = 16'b0011111111100000;
    font[Dc][2]  = 16'b0011111111110000;
    font[Dc][3]  = 16'b0011000000111000;
    font[Dc][4]  = 16'b0011000000011000;
    font[Dc][5]  = 16'b0011000000011000;
    font[Dc][6]  = 16'b0011000000011000;
    font[Dc][7]  = 16'b0011000000011000;
    font[Dc][8]  = 16'b0011000000011000;
    font[Dc][9]  = 16'b0011000000111000;
    font[Dc][10] = 16'b0011111111110000;
    font[Dc][11] = 16'b0011111111100000;
    font[Dc][12] = 16'b0000000000000000;
    font[Dc][13] = 16'b0000000000000000;
    font[Dc][14] = 16'b0000000000000000;
    font[Dc][15] = 16'b0000000000000000;
    
    
    font[Wc][0]  = 16'b0000000000000000;
    font[Wc][1]  = 16'b0110000000001100;
    font[Wc][2]  = 16'b0110000000001100;
    font[Wc][3]  = 16'b0110000000001100;
    font[Wc][4]  = 16'b0110000110001100;
    font[Wc][5]  = 16'b0110000110001100;
    font[Wc][6]  = 16'b0110000110001100;
    font[Wc][7]  = 16'b0110011011001100;
    font[Wc][8]  = 16'b0110110011101100;
    font[Wc][9]  = 16'b0011110001111000;
    font[Wc][10] = 16'b0011100000111000;
    font[Wc][11] = 16'b0011000000011000;
    font[Wc][12] = 16'b0000000000000000;
    font[Wc][13] = 16'b0000000000000000;
    font[Wc][14] = 16'b0000000000000000;
    font[Wc][15] = 16'b0000000000000000;
    
    // 'N'
    font[Nc][0]  = 16'b0000000000000000;
    font[Nc][1]  = 16'b0110000000011000;
    font[Nc][2]  = 16'b0111000000011000;
    font[Nc][3]  = 16'b0111100000011000;
    font[Nc][4]  = 16'b0110110000011000;
    font[Nc][5]  = 16'b0110011000011000;
    font[Nc][6]  = 16'b0110001100011000;
    font[Nc][7]  = 16'b0110000110011000;
    font[Nc][8]  = 16'b0110000011011000;
    font[Nc][9]  = 16'b0110000001111000;
    font[Nc][10] = 16'b0110000000111000;
    font[Nc][11] = 16'b0110000000011000;
    font[Nc][12] = 16'b0000000000000000;
    font[Nc][13] = 16'b0000000000000000;
    font[Nc][14] = 16'b0000000000000000;
    font[Nc][15] = 16'b0000000000000000;

    // 'O'
    font[Oc][0]  = 16'b0000000000000000;
    font[Oc][1]  = 16'b0000111111100000;
    font[Oc][2]  = 16'b0001111111110000;
    font[Oc][3]  = 16'b0011100000111000;
    font[Oc][4]  = 16'b0011000000011000;
    font[Oc][5]  = 16'b0110000000001100;
    font[Oc][6]  = 16'b0110000000001100;
    font[Oc][7]  = 16'b0110000000001100;
    font[Oc][8]  = 16'b0110000000001100;
    font[Oc][9]  = 16'b0011000000011000;
    font[Oc][10] = 16'b0011100000111000;
    font[Oc][11] = 16'b0001111111110000;
    font[Oc][12] = 16'b0000111111100000;
    font[Oc][13] = 16'b0000000000000000;
    font[Oc][14] = 16'b0000000000000000;
    font[Oc][15] = 16'b0000000000000000;

    // 'R'
    font[Rc][0]  = 16'b0000000000000000;
    font[Rc][1]  = 16'b0011111111100000;
    font[Rc][2]  = 16'b0011111111110000;
    font[Rc][3]  = 16'b0011000000110000;
    font[Rc][4]  = 16'b0011000000110000;
    font[Rc][5]  = 16'b0011111111110000;
    font[Rc][6]  = 16'b0011111111100000;
    font[Rc][7]  = 16'b0011000011000000;
    font[Rc][8]  = 16'b0011000001100000;
    font[Rc][9]  = 16'b0011000001110000;
    font[Rc][10] = 16'b0011000000111000;
    font[Rc][11] = 16'b0011000000011000;
    font[Rc][12] = 16'b0000000000000000;
    font[Rc][13] = 16'b0000000000000000;
    font[Rc][14] = 16'b0000000000000000;
    font[Rc][15] = 16'b0000000000000000;

    // 'M'
    font[Mc][0]  = 16'b0000000000000000;
    font[Mc][1]  = 16'b0110000000001100;
    font[Mc][2]  = 16'b0111000000011100;
    font[Mc][3]  = 16'b0111100000111100;
    font[Mc][4]  = 16'b0110110001101100;
    font[Mc][5]  = 16'b0110011011001100;
    font[Mc][6]  = 16'b0110001110001100;
    font[Mc][7]  = 16'b0110000110001100;
    font[Mc][8]  = 16'b0110000000001100;
    font[Mc][9]  = 16'b0110000000001100;
    font[Mc][10] = 16'b0110000000001100;
    font[Mc][11] = 16'b0110000000001100;
    font[Mc][12] = 16'b0000000000000000;
    font[Mc][13] = 16'b0000000000000000;
    font[Mc][14] = 16'b0000000000000000;
    font[Mc][15] = 16'b0000000000000000;

    // 'L'
    font[Lc][0]  = 16'b0000000000000000;
    font[Lc][1]  = 16'b0011000000000000;
    font[Lc][2]  = 16'b0011000000000000;
    font[Lc][3]  = 16'b0011000000000000;
    font[Lc][4]  = 16'b0011000000000000;
    font[Lc][5]  = 16'b0011000000000000;
    font[Lc][6]  = 16'b0011000000000000;
    font[Lc][7]  = 16'b0011000000000000;
    font[Lc][8]  = 16'b0011000000000000;
    font[Lc][9]  = 16'b0011000000000000;
    font[Lc][10] = 16'b0011111111110000;
    font[Lc][11] = 16'b0011111111110000;
    font[Lc][12] = 16'b0000000000000000;
    font[Lc][13] = 16'b0000000000000000;
    font[Lc][14] = 16'b0000000000000000;
    font[Lc][15] = 16'b0000000000000000;
    
    font[Gc][0]  = 16'b0000000000000000;
    font[Gc][1]  = 16'b0000111111100000;
    font[Gc][2]  = 16'b0001111111110000;
    font[Gc][3]  = 16'b0011100000111000;
    font[Gc][4]  = 16'b0011000000011000;
    font[Gc][5]  = 16'b0110000000000000;
    font[Gc][6]  = 16'b0110000000000000;
    font[Gc][7]  = 16'b0110000111111100;
    font[Gc][8]  = 16'b0110000111111100;
    font[Gc][9]  = 16'b0110000000011000;
    font[Gc][10] = 16'b0111000000011000;
    font[Gc][11] = 16'b0011100000111000;
    font[Gc][12] = 16'b0001111111110000;
    font[Gc][13] = 16'b0000111111100000;
    font[Gc][14] = 16'b0000000000000000;
    font[Gc][15] = 16'b0000000000000000;
    
    font[Tc][0]  = 16'b0000000000000000;
    font[Tc][1]  = 16'b0111111111111100;
    font[Tc][2]  = 16'b0111111111111100;
    font[Tc][3]  = 16'b0000000110000000;
    font[Tc][4]  = 16'b0000000110000000;
    font[Tc][5]  = 16'b0000000110000000;
    font[Tc][6]  = 16'b0000000110000000;
    font[Tc][7]  = 16'b0000000110000000;
    font[Tc][8]  = 16'b0000000110000000;
    font[Tc][9]  = 16'b0000000110000000;
    font[Tc][10] = 16'b0000000110000000;
    font[Tc][11] = 16'b0000000110000000;
    font[Tc][12] = 16'b0000000000000000;
    font[Tc][13] = 16'b0000000000000000;
    font[Tc][14] = 16'b0000000000000000;
    font[Tc][15] = 16'b0000000000000000;
    
    font[Vc][0]  = 16'b0000000000000000;
    font[Vc][1]  = 16'b0110000000001100;
    font[Vc][2]  = 16'b0110000000001100;
    font[Vc][3]  = 16'b0110000000001100;
    font[Vc][4]  = 16'b0011000000011000;
    font[Vc][5]  = 16'b0011000000011000;
    font[Vc][6]  = 16'b0011000000011000;
    font[Vc][7]  = 16'b0001100000110000;
    font[Vc][8]  = 16'b0001100000110000;
    font[Vc][9]  = 16'b0000110001100000;
    font[Vc][10] = 16'b0000110001100000;
    font[Vc][11] = 16'b0000011111000000;
    font[Vc][12] = 16'b0000011111000000;
    font[Vc][13] = 16'b0000000110000000;
    font[Vc][14] = 16'b0000000000000000;
    font[Vc][15] = 16'b0000000000000000;

    apple[0]  = 16'b0000000000000000;
    apple[1]  = 16'b0000000000000000;
    apple[2]  = 16'b0000000001100000;
    apple[3]  = 16'b0000000011000000;
    apple[4]  = 16'b0000000010000000;
    apple[5]  = 16'b0000111111110000;
    apple[6]  = 16'b0001111111111000;
    apple[7]  = 16'b0001111111111000;
    apple[8]  = 16'b0001111111111000;
    apple[9]  = 16'b0001111111111000;
    apple[10] = 16'b0000111111111000;
    apple[11] = 16'b0000111111110000;
    apple[12] = 16'b0000111111110000;
    apple[13] = 16'b0000011001100000;
    apple[14] = 16'b0000000000000000;
    apple[15] = 16'b0000000000000000;

    head[0]  = 16'b0000000000000000;
    head[1]  = 16'b0000000000000000;
    head[2]  = 16'b0000011111100000;
    head[3]  = 16'b0000111111110000;
    head[4]  = 16'b0001100110011000;
    head[5]  = 16'b0011100110011100;
    head[6]  = 16'b0011100110011100;
    head[7]  = 16'b0011111111111100;
    head[8]  = 16'b0011111111111100;
    head[9]  = 16'b0011000000001100;
    head[10] = 16'b0011100000011100;
    head[11] = 16'b0001110000111000;
    head[12] = 16'b0000111111110000;
    head[13] = 16'b0000011111100000;
    head[14] = 16'b0000000000000000;
    head[15] = 16'b0000000000000000;

    body[0]  = 16'b0000000000000000;
    body[1]  = 16'b0000000000000000;
    body[2]  = 16'b0000011111100000;
    body[3]  = 16'b0000111111110000;
    body[4]  = 16'b0001111111111000;
    body[5]  = 16'b0011111111111100;
    body[6]  = 16'b0011111111111100;
    body[7]  = 16'b0011111111111100;
    body[8]  = 16'b0011111111111100;
    body[9]  = 16'b0011111111111100;
    body[10] = 16'b0011111111111100;
    body[11] = 16'b0001111111111000;
    body[12] = 16'b0000111111110000;
    body[13] = 16'b0000011111100000;
    body[14] = 16'b0000000000000000;
    body[15] = 16'b0000000000000000;
    
    char_code[0] = Sc;
    char_code[1] = cc;
    char_code[2] = oc;
    char_code[3] = rc;
    char_code[4] = ec;
    char_code[5] = dotdot;
    char_code[6] = zero;
    char_code[7] = zero;
    char_code[8] = zero;
    char_code[9] = Gc;
    char_code[10] = Ac;
    char_code[11] = Mc;
    char_code[12] = Ec;
    char_code[13] = space;
    char_code[14] = Sc;
    char_code[15] = Tc;
    char_code[16] = Ac;
    char_code[17] = Rc;
    char_code[18] = Tc;
    char_code[19] = Ec;
    char_code[20] = Ac;
    char_code[21] = Sc;
    char_code[22] = Yc;
    char_code[23] = space;
    char_code[24] = Sc;
    char_code[25] = Wc;
    char_code[26] = one;
    char_code[27] = Nc;
    char_code[28] = oc;
    char_code[29] = Rc;
    char_code[30] = Mc;
    char_code[31] = Ac;
    char_code[32] = Lc;
    char_code[33] = space;
    char_code[34] = Sc;
    char_code[35] = Wc;
    char_code[36] = two;
    char_code[37] = Hc;
    char_code[38] = Ac;
    char_code[39] = Rc;
    char_code[40] = Dc;
    char_code[41] = space;
    char_code[42] = Sc;
    char_code[43] = Wc;
    char_code[44] = three;
    char_code[45] = Gc;
    char_code[46] = Ac;
    char_code[47] = Mc;
    char_code[48] = Ec;
    char_code[49] = space;
    char_code[50] = Oc;
    char_code[51] = Vc;
    char_code[52] = Ec;
    char_code[53] = Rc;
end


always @(posedge clk, negedge reset_n) begin
    if (!reset_n) begin
        start <= 0;
        diff = 0;
    end
    else if (~start && ~usr_sw[1]) begin
        diff = 0;
        start <= 1;
    end
    else if (~start && ~usr_sw[2]) begin
        diff = 1;
        start <= 1;
    end
    else if (~start && ~usr_sw[3]) begin
        diff = 2;
        start <= 1;
    end
end
reg [3:0] count_score;
reg[31:0] show_counter;
always @(posedge clk, negedge reset_n) begin
    if (!reset_n) begin
        show_counter <= 0;
    end else begin
        if(show_counter == 80000001 || count_score != 5) begin
          show_counter <= 0;
        end else begin
          show_counter <= show_counter + 1;
        end
    end
end

// Dynamic score update
// Dynamic score update
reg [3:0]usr_led_reg;
assign usr_led = usr_led_reg;
always @(posedge clk, negedge reset_n) begin
    if (!reset_n) begin
        char_code[8] <= zero;
        char_code[7] <= zero;
        char_code[6] <= zero;
        count_score <= 0;
    end
    else begin
      usr_led_reg <= count_score;
      if(show_counter == 80000000) count_score <= 0;
      if(score == 1)begin
        count_score <= count_score+1;
        if(char_code[8] == nine)begin
            char_code[8] <= zero;
            if(char_code[7] == nine)begin
                char_code[7] <= zero;
                char_code[6] <= (char_code[6] == nine)?char_code[6]:char_code[6]+1;
            end else char_code[7] <= char_code[7] + 1;
        end else char_code[8] <= char_code[8] + 1;
      end else if (score == 2) begin
        if(char_code[8] == zero)begin
            char_code[8] <= nine;
            if(char_code[7] == zero)begin
                char_code[7] <= nine;
                char_code[6] <= (char_code[6] == zero)?char_code[6]:char_code[6]-1;
            end else char_code[7] <= char_code[7] - 1;
        end else char_code[8] <= char_code[8] - 1;
      end
    end
end


// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(start == 0 && over == 0)begin
      if (grid_y == 5 && grid_x >= 5 && grid_x <= 14)
        if(font[char_code[grid_x+4]][char_y][15-char_x] == 1)rgb_next <= 12'h0f0;
        else rgb_next <= 12'h222;
      else if (grid_y == 6 && grid_x >= 6 && grid_x <= 13)
        if(font[char_code[grid_x+13]][char_y][15-char_x] == 1)rgb_next <= 12'h0f0;
        else rgb_next <= 12'h222;
      else if (grid_y == 7 && grid_x >= 5 && grid_x <= 14)
        if(font[char_code[grid_x+22]][char_y][15-char_x] == 1)rgb_next <= 12'h0f0;
        else rgb_next <= 12'h222;
      else if (grid_y == 8 && grid_x >= 6 && grid_x <= 13)
        if(font[char_code[grid_x+31]][char_y][15-char_x] == 1)rgb_next <= 12'h0f0;
        else rgb_next <= 12'h222;
      else rgb_next <= 12'h222;
  end else if (start == 1 && over == 0) begin
       //game start
      if (count_score == 5)
        rgb_next <= data_out_bg;
      else if (grid_x < 20 && grid_y < 14 && stage_out[(grid_y*20 + grid_x)*3 +: 3] == 1)
        if(head[char_y][15-char_x] == 1)rgb_next <= 12'hff0;
        else rgb_next <= 12'h222;
      else if (grid_x < 20 && grid_y < 14 && stage_out[(grid_y*20 + grid_x)*3 +: 3] == 2)
        if(body[char_y][15-char_x] == 1)rgb_next <= 12'hff0;
        else rgb_next <= 12'h222;
      else if (grid_x < 20 && grid_y < 14 && stage_out[(grid_y*20 + grid_x)*3 +: 3] == 3)
        rgb_next <= 12'hfff;
      else if (grid_x < 20 && grid_y < 14 && stage_out[(grid_y*20 + grid_x)*3 +: 3] == 4)
        if(apple[char_y][15-char_x] == 1)rgb_next <= 12'hf00;
        else rgb_next <= 12'h222;
      else if (grid_x < 9 && grid_y == 14)begin
        if(font[char_code[grid_x]][char_y][15-char_x] == 1)rgb_next <= 12'h0f0;
        else rgb_next <= 12'h222;
  end else
    rgb_next <= 12'h222; // RGB value at (pixel_x, pixel_y)
  end else if (over == 1) begin
     if(grid_y == 7 && grid_x >= 6 && grid_x <= 14)
        if(font[char_code[grid_x+39]][char_y][15-char_x] == 1)rgb_next <= 12'h0f0;
        else rgb_next <= 12'h222;
     else rgb_next <= 12'h222;
  end else
    rgb_next <= 12'h222; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
