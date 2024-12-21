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
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [32:0] fish_clock1, fish_clock2, fish_clock3;
reg [10:0] control_user;
wire [9:0]  pos1, pos2, pos3, pos4;
wire        fish_region1, fish_region2, fish_region3;

// declare SRAM control signals
wire [16:0] sram_addr_bg, sram_addr_fish1, sram_addr_fish2, sram_addr_fish3;
wire [11:0] data_in;
wire [11:0] data_out_bg, data_out_fish1, data_out_fish2, data_out_fish3;
wire        sram_we, sram_en;

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
  
// Application-specific VGA signals
reg  [17:0] pixel_addr_bg, pixel_addr_fish1, pixel_addr_fish2, pixel_addr_fish3;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS1   = 64; // Vertical location of the fish in the sea image.
localparam FISH_VPOS2   = 64;
localparam FISH_VPOS3   = 128;
localparam FISH_VPOS4   = 100;
localparam FISH_W      = 64; // Width of the fish.
//localparam FISH_W2      = 64;
localparam FISH_W3      = 29;
localparam FISH_H1      = 32; // Height of the fish.
localparam FISH_H2      = 44;
localparam FISH_H3      = 32;
reg [17:0] fish1_addr[0:7];   // Address array for up to 8 fish images.
reg [17:0] fish2_addr[0:7];   // Address array for up to 8 fish images.
reg [17:0] fish3_addr[0:7];   // Address array for up to 8 fish images.
wire btn_level, btn_pressed, btn_level1, btn_pressed1;
reg  prev_btn_level, prev_btn_level1;
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish1_addr[0] = 18'd0;         /* Addr for fish image #1 */
  fish1_addr[1] = FISH_W*FISH_H1; /* Addr for fish image #2 */
  fish1_addr[2] = FISH_W*FISH_H1*2; /* Addr for fish image #2 */
  fish1_addr[3] = FISH_W*FISH_H1*3; /* Addr for fish image #2 */
  fish1_addr[4] = FISH_W*FISH_H1*4; /* Addr for fish image #2 */
  fish1_addr[5] = FISH_W*FISH_H1*5; /* Addr for fish image #2 */
  fish1_addr[6] = FISH_W*FISH_H1*6; /* Addr for fish image #2 */
  fish1_addr[7] = FISH_W*FISH_H1*7; /* Addr for fish image #2 */
  fish2_addr[0] = 18'd0;         /* Addr for fish image #1 */
  fish2_addr[1] = FISH_W*FISH_H2; /* Addr for fish image #2 */
  fish2_addr[2] = FISH_W*FISH_H2*2; /* Addr for fish image #2 */
  fish2_addr[3] = FISH_W*FISH_H2*3; /* Addr for fish image #2 */
  fish2_addr[4] = FISH_W*FISH_H2*4; /* Addr for fish image #2 */
  fish2_addr[5] = FISH_W*FISH_H2*5; /* Addr for fish image #2 */
  fish2_addr[6] = FISH_W*FISH_H2*6; /* Addr for fish image #2 */
  fish2_addr[7] = FISH_W*FISH_H2*7; /* Addr for fish image #2 */
  fish3_addr[0] = 18'd0;         /* Addr for fish image #1 */
  fish3_addr[1] = FISH_W3*FISH_H3; /* Addr for fish image #2 */
  fish3_addr[2] = FISH_W3*FISH_H3*2; /* Addr for fish image #2 */
  fish3_addr[3] = FISH_W3*FISH_H3*3; /* Addr for fish image #2 */
  fish3_addr[4] = FISH_W3*FISH_H3*4; /* Addr for fish image #2 */
  fish3_addr[5] = FISH_W3*FISH_H3*5; /* Addr for fish image #2 */
  fish3_addr[6] = FISH_W3*FISH_H3*6; /* Addr for fish image #2 */
  fish3_addr[7] = FISH_W3*FISH_H3*7; /* Addr for fish image #2 */
end

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

debounce btn_db0(
    .clk(clk),
    .btn_input(usr_btn[0]),
    .btn_output(btn_level)
);

debounce btn_db1(
    .clk(clk),
    .btn_input(usr_btn[1]),
    .btn_output(btn_level1)
);
always @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        prev_btn_level <= 0;
        prev_btn_level1 <= 0;
    end else begin
        prev_btn_level <= btn_level;
        prev_btn_level1 <= btn_level1;
    end
end
assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;
assign btn_pressed1 = (btn_level1 == 1 && prev_btn_level1 == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram_bg #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H), .FILE("images_bg.mem"))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en), 
          .addr(sram_addr_bg), .data_i(data_in), .data_o(data_out_bg));
sram_bg #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H1*8), .FILE("images_fish1.mem"))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en), 
          .addr(sram_addr_fish1), .data_i(data_in), .data_o(data_out_fish1));
sram_bg #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H2*8), .FILE("images_fish2.mem"))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en), 
          .addr(sram_addr_fish2), .data_i(data_in), .data_o(data_out_fish2));
sram_bg #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W3*FISH_H3*8), .FILE("images_fish3.mem"))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en), 
          .addr(sram_addr_fish3), .data_i(data_in), .data_o(data_out_fish3));



assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_bg = pixel_addr_bg;
assign sram_addr_fish1 = pixel_addr_fish1;
assign sram_addr_fish2 = pixel_addr_fish2;
assign sram_addr_fish3 = pixel_addr_fish3;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos1 = fish_clock1[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos2 = fish_clock2[30:19];
//assign pos3 = fish_clock3[32:21];
assign pos3 = control_user[10:0];
reg fish_flag1, fish_flag2, fish_flag3;
always @(posedge clk) begin
  if (~reset_n) begin
    fish_clock1 <= 0;
    fish_clock2[30:20] <= VBUF_W;
    fish_clock3[32:22] <= VBUF_W;
    fish_flag1 <= 0;
    fish_flag2 <= 1;
    //fish_flag3 <= 1;
  end else begin
    if(fish_clock1[31:21] >= VBUF_W) fish_flag1 <= 1;
    else if(fish_clock1[31:21] <= FISH_W) fish_flag1 <= 0;
    if(fish_flag1 == 0) fish_clock1 <= fish_clock1 + 1;
    else fish_clock1 <= fish_clock1 - 1;
    if(fish_clock2[30:20] >= VBUF_W) fish_flag2 <= 1;
    else if(fish_clock2[30:20] <= FISH_W) fish_flag2 <= 0;
    if(fish_flag2 == 0) fish_clock2 <= fish_clock2 + 1;
    else fish_clock2 <= fish_clock2 - 1;
    //if(fish_clock3[32:22] >= VBUF_W) fish_flag3 <= 1;
    //else if(fish_clock3[32:22] <= FISH_W3) fish_flag3 <= 0;
    //if(fish_flag3 == 0) fish_clock3 <= fish_clock3 + 1;
    //else fish_clock3 <= fish_clock3 - 1;
    fish_clock3 <= fish_clock3 + 1;
  end
end
// End of the animation clock code.
// ------------------------------------------------------------------------
reg [32:0] move;
reg [6:0] move_count;
always @(posedge clk) begin
  if (~reset_n) begin
    control_user[10:1] <= FISH_W3;
    fish_flag3 <= 0;
    move <= 0;
    move_count <= 30;
  end else begin
    if(btn_pressed1 == 1) begin
        move_count <= 0;
        fish_flag3 <= 1;
    end else if(btn_pressed == 1) begin
        move_count <= 0;
        fish_flag3 <= 0;
    end
    if(move == 1000000)begin
        move <= 0;
        if(control_user[10:1] > FISH_W3 && fish_flag3 == 1 && move_count < 30) begin
              control_user <= control_user - 1;
              move_count <= move_count + 1;
        end else if(control_user[10:1] < VBUF_W && fish_flag3 == 0 && move_count < 30)begin 
            if(move == 1000000)begin
                control_user <= control_user + 1;
                move_count <= move_count + 1;
            end
        end
    end else move <= move + 1;
  end
end
// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region1 =
           pixel_y >= (FISH_VPOS1<<1) && pixel_y < (FISH_VPOS1+FISH_H1)<<1 &&
           (pixel_x + 127) >= pos1 && pixel_x < pos1 + 1;
assign fish_region2 =
           pixel_y >= (FISH_VPOS2<<1) && pixel_y < (FISH_VPOS2+FISH_H2)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;
assign fish_region3 =
           pixel_y >= (FISH_VPOS3<<1) && pixel_y < (FISH_VPOS3+FISH_H3)<<1 &&
           (pixel_x + 57) >= pos3 && pixel_x < pos3 + 1;
           
always @ (posedge clk) begin
  if (~reset_n)begin
    pixel_addr_bg <= 0;
    pixel_addr_fish1 <= 0;
    pixel_addr_fish2 <= 0;
    pixel_addr_fish3 <= 0;
  end else begin
    pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    if (fish_region1) begin
        if(fish_flag1 == 0)pixel_addr_fish1 <= fish1_addr[fish_clock1[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS1)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos1)>>1);
        else pixel_addr_fish1 <= fish1_addr[fish_clock1[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS1)*FISH_W +
                      (FISH_W - 1 - ((pixel_x +(FISH_W*2-1)-pos1)>>1));
    end else
        // Scale up a 320x240 image for the 640x480 display.
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        pixel_addr_fish1 <= fish1_addr[0];
    if (fish_region2) begin
        if(fish_flag2 == 0)pixel_addr_fish2 <= fish2_addr[fish_clock2[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS2)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos2)>>1);
        else pixel_addr_fish2 <= fish2_addr[fish_clock2[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS2)*FISH_W +
                      (FISH_W - 1 - ((pixel_x +(FISH_W*2-1)-pos2)>>1));
    end else
        // Scale up a 320x240 image for the 640x480 display.
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        pixel_addr_fish2 <= fish2_addr[0];
    if (fish_region3) begin
        if(fish_flag3 == 1)pixel_addr_fish3 <= fish3_addr[fish_clock3[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS3)*FISH_W3 +
                      ((pixel_x +(FISH_W3*2-1)-pos3)>>1);
        else pixel_addr_fish3 <= fish3_addr[fish_clock3[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS3)*FISH_W3 +
                      (FISH_W3 - 1 - ((pixel_x +(FISH_W3*2-1)-pos3)>>1));
    end else
        // Scale up a 320x240 image for the 640x480 display.
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        pixel_addr_fish3 <= fish3_addr[0];
    
  end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next <= 12'h000; // Synchronization period, must set RGB values to zero. 
  else if(data_out_fish1 != 12'h0f0)
    rgb_next <= data_out_fish1;
  else if(data_out_fish2 != 12'h0f0)
    rgb_next <= data_out_fish2;
  else if(data_out_fish3 != 12'h0f0)
    rgb_next <= data_out_fish3;
  else
    rgb_next <= data_out_bg; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule


