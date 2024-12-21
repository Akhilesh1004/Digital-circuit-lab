`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  
  // tri-state LED
  output [3:0] rgb_led_r,
  output [3:0] rgb_led_g,
  output [3:0] rgb_led_b
);

localparam [3:0] S_MAIN_INIT = 4'b0000, S_MAIN_IDLE = 4'b0001,
                 S_MAIN_WAIT_START = 4'b0010, S_MAIN_READ_START = 4'b0011,
                 S_MAIN_FIND = 4'b0100, S_MAIN_WAIT_END = 4'b0101,
                 S_MAIN_READ_END = 4'b0110, S_MAIN_SEARCH = 4'b0111,
                 S_MAIN_SHOW = 4'b1000, S_MAIN_DATA1 = 4'b1001,
                 S_MAIN_DATA2 = 4'b1010;

// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [5:0] send_counter;
reg  [3:0] P, P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  done_flag; // Signals the completion of reading one SD sector.

//buffer for text
reg  [4*8-1:0] buffer = "    ";
reg  [9*8-1:0] buffer_start = "         ";
reg  [7*8-1:0] buffer_end = "       ";
reg [2:0] first_t;

//time
reg [31:0] period;
reg [3:0] count;

//LED
reg [4:0] ans_count[0:5]; // 0 for red, 1 for green, 2 for blue, 3 for yellow, 4 for purple, 5 for other
reg [3:0] red, green, blue;
reg [3:0] red_out, green_out, blue_out;
reg [19:0] pwm;
assign rgb_led_r = red_out;
assign rgb_led_g = green_out;
assign rgb_led_b = blue_out;

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req, update_flag;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = {3'b000, update_flag};

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk, negedge reset_n) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk, negedge reset_n) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT_START;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT_START: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ_START;
    S_MAIN_READ_START: // wait for the input data to enter the SRAM buffer
      if (sd_counter == 512) P_next = S_MAIN_FIND;
      else P_next = S_MAIN_READ_START;
    S_MAIN_FIND: // wait for the input data to enter the buffer
      if (buffer_start == "DCL_START") P_next <= S_MAIN_SEARCH;
      else if (sd_counter == 512) P_next <= S_MAIN_WAIT_START;
      else P_next <= S_MAIN_DATA1;
    S_MAIN_DATA1: // read byte 0 of the superblock from sram[]
      P_next = S_MAIN_FIND;
    S_MAIN_WAIT_END: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ_END;
    S_MAIN_READ_END: // wait for the input data to enter the SRAM buffer
      if (sd_counter == 512) P_next = S_MAIN_SEARCH;
      else P_next = S_MAIN_READ_END;
    S_MAIN_SEARCH: // read byte 0 of the superblock from sram[]
      if (buffer_end == "DCL_END") P_next = S_MAIN_SHOW;
      else if (sd_counter == 512) P_next <= S_MAIN_WAIT_END;
      else if ((update_flag == 1 || first_t < 4)) P_next <= S_MAIN_DATA2;
      else P_next = S_MAIN_SEARCH;
    S_MAIN_DATA2: // read byte 0 of the superblock from sram[]
      P_next = S_MAIN_SEARCH;
    S_MAIN_SHOW:
      P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_WAIT_START || P == S_MAIN_WAIT_END);
  rd_addr = blk_addr;
end

always @(posedge clk, negedge reset_n) begin
  if (~reset_n || first_t < 4) begin
    period <= 0;
    count <= 0;
    update_flag <= 0;
  end else if(period != 100_000_000) begin
    period <= period+1;
    update_flag <= 0;
  end else begin
    period <= 0;
    if(count != 1) count <= count+1;
    else begin
        count <= 0;
        update_flag <= 1;
    end
  end
end

always @(posedge clk, negedge reset_n) begin
  if (~reset_n || P == S_MAIN_IDLE) 
    blk_addr <= 32'h2000;
  else if(P == S_MAIN_WAIT_START || P == S_MAIN_WAIT_END) 
    blk_addr <= blk_addr + 1; // In lab 8, change this line to scan all blocks 
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk, negedge reset_n) begin
  if (~reset_n) 
    data_byte <= 8'b0;
  else
    data_byte <= data_out; // In lab 8, change this line to scan all blocks 
end

always @(posedge clk, negedge reset_n) begin
  if (~reset_n || (P == S_MAIN_READ_START && P_next == S_MAIN_FIND) || 
        (P == S_MAIN_READ_END && P_next == S_MAIN_SEARCH) || 
        P_next == S_MAIN_WAIT_START || P_next == S_MAIN_WAIT_END)
    sd_counter <= 0;
  else if ((P == S_MAIN_READ_START && sd_valid) || (P == S_MAIN_READ_END && sd_valid) ||
           (P == S_MAIN_FIND && P_next == S_MAIN_DATA1) || (P == S_MAIN_SEARCH && P_next == S_MAIN_DATA2))
    sd_counter <= sd_counter + 1;
  //else if (first_t == 3) sd_counter <= sd_counter - 1;
end

// FSM ouput logic: Retrieves the content of sram[] for display
always @(posedge clk, negedge reset_n) begin
  if (~reset_n) begin
    ans_count[0] <= 8'd0;
    ans_count[1] <= 8'd0;
    ans_count[2] <= 8'd0;
    ans_count[3] <= 8'd0;
    ans_count[4] <= 8'd0;
    ans_count[5] <= 8'd0;
  end else if(sram_en && P == S_MAIN_DATA2 && P_next == S_MAIN_SEARCH) begin
    if(data_byte == "R" || data_byte == "r") ans_count[0] <= ans_count[0]+1;
    else if(data_byte == "G" || data_byte == "g") ans_count[1] <= ans_count[1]+1;
    else if(data_byte == "B" || data_byte == "b") ans_count[2] <= ans_count[2]+1;
    else if(data_byte == "Y" || data_byte == "y") ans_count[3] <= ans_count[3]+1;
    else if(data_byte == "P" || data_byte == "p") ans_count[4] <= ans_count[4]+1;
    else ans_count[5] <= ans_count[5]+1;
  end
end

always @(posedge clk, negedge reset_n) begin
  if (~reset_n) begin
    buffer <= 32'h0;
    buffer_end <= 56'h0;
    buffer_start <= 72'h0;
    first_t <= 0;
  end
  else if (sram_en && P == S_MAIN_DATA1 && P_next == S_MAIN_FIND ) buffer_start <= {buffer_start[63:0], data_byte};
  else if (P == S_MAIN_DATA2 && P_next == S_MAIN_SEARCH) begin
    buffer <= {buffer[23:0], data_byte};
    buffer_end <= {buffer_end[47:0], data_byte};
    if(first_t < 4) first_t <= first_t + 1;
  end
end

always @(posedge clk, negedge reset_n) begin
  if (~reset_n)begin
    red <= 4'b0000;
    green <= 4'b0000;
    blue <= 4'b0000;
    red_out <= 4'b0000;
    green_out <= 4'b0000;
    blue_out <= 4'b0000;
    pwm <= 0;
  end
  else begin
    if(pwm != 1000000) pwm <= pwm+1;
    else pwm <= 0;
    if(pwm <= 50000)begin
      red_out <= red;
      green_out <= green;
      blue_out <= blue;
    end else begin
      red_out <= 4'b0000;
      green_out <= 4'b0000;
      blue_out <= 4'b0000;
    end
    if (P == S_MAIN_SEARCH && first_t == 4)begin
      if(buffer[31:24] == "R" || buffer[31:24] == "r")begin
        red[0] <= 1;
        green[0] <= 0;
        blue[0] <= 0;
      end 
      else if(buffer[31:24] == "G" || buffer[31:24] == "g")begin
        red[0] <= 0;
        green[0] <= 1;
        blue[0] <= 0;
      end
      else if(buffer[31:24] == "B" || buffer[31:24] == "b")begin
        red[0] <= 0;
        green[0] <= 0;
        blue[0] <= 1;
      end
      else if(buffer[31:24] == "Y" || buffer[31:24] == "y")begin
        red[0] <= 1;
        green[0] <= 1;
        blue[0] <= 0;
      end
      else if(buffer[31:24] == "P" || buffer[31:24] == "p")begin
        red[0] <= 1;
        green[0] <= 0;
        blue[0] <= 1;
      end
      else begin
        red[0] <= 0;
        green[0] <= 0;
        blue[0] <= 0;
      end
      if(buffer[23:16] == "R" || buffer[23:16] == "r")begin
        red[1] <= 1;
        green[1] <= 0;
        blue[1] <= 0;
      end
      else if(buffer[23:16] == "G" || buffer[23:16] == "g")begin
        red[1] <= 0;
        green[1] <= 1;
        blue[1] <= 0;
      end
      else if(buffer[23:16] == "B" || buffer[23:16] == "b")begin
        red[1] <= 0;
        green[1] <= 0;
        blue[1] <= 1;
      end
      else if(buffer[23:16] == "Y" || buffer[23:16] == "y")begin
        red[1] <= 1;
        green[1] <= 1;
        blue[1] <= 0;
      end
      else if(buffer[23:16] == "P" || buffer[23:16] == "p")begin
        red[1] <= 1;
        green[1] <= 0;
        blue[1] <= 1;
      end
      else begin
        red[1] <= 0;
        green[1] <= 0;
        blue[1] <= 0;
      end
      if(buffer[15:8] == "R" || buffer[15:8] == "r")begin
        red[2] <= 1;
        green[2] <= 0;
        blue[2] <= 0;
      end
      else if(buffer[15:8] == "G" || buffer[15:8] == "g")begin
        red[2] <= 0;
        green[2] <= 1;
        blue[2] <= 0;
      end
      else if(buffer[15:8] == "B" || buffer[15:8] == "b")begin
        red[2] <= 0;
        green[2] <= 0;
        blue[2] <= 1;
      end
      else if(buffer[15:8] == "Y" || buffer[15:8] == "y")begin
        red[2] <= 1;
        green[2] <= 1;
        blue[2] <= 0;
      end
      else if(buffer[15:8] == "P" || buffer[15:8] == "p")begin
        red[2] <= 1;
        green[2] <= 0;
        blue[2] <= 1;
      end
      else begin
        red[2] <= 0;
        green[2] <= 0;
        blue[2] <= 0;
      end
      if(buffer[7:0] == "R" || buffer[7:0] == "r")begin
        red[3] <= 1;
        green[3] <= 0;
        blue[3] <= 0;
      end
      else if(buffer[7:0] == "G" || buffer[7:0] == "g")begin
        red[3] <= 0;
        green[3] <= 1;
        blue[3] <= 0;
      end
      else if(buffer[7:0] == "B" || buffer[7:0] == "b")begin
        red[3] <= 0;
        green[3] <= 0;
        blue[3] <= 1;
      end
      else if(buffer[7:0] == "Y" || buffer[7:0] == "y")begin
        red[3] <= 1;
        green[3] <= 1;
        blue[3] <= 0;
      end
      else if(buffer[7:0] == "P" || buffer[7:0] == "p")begin
        red[3] <= 1;
        green[3] <= 0;
        blue[3] <= 1;
      end
      else begin
        red[3] <= 0;
        green[3] <= 0;
        blue[3] <= 0;
      end
    end
  end
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
function [7:0] num_to_ascii;
    input [7:0]num;
    begin
        if(num < 10) num_to_ascii = "0"+num;
        else num_to_ascii = "7"+num;
    end
endfunction

always @(posedge clk, negedge reset_n) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end
  else if (P == S_MAIN_FIND) begin
    row_A <= "searching for   ";
    row_B <= "title           ";
  end
  else if (P == S_MAIN_SEARCH) begin
    row_A <= "calculating...  ";
    row_B <= "                ";
    //row_B <= {buffer, "      ", num_to_ascii(ans_count[0]), num_to_ascii(ans_count[1]), num_to_ascii(ans_count[2]), 
    //            num_to_ascii(ans_count[3]), num_to_ascii(ans_count[4]), num_to_ascii(ans_count[5])};
  end
  else if (P == S_MAIN_SHOW) begin
    //row_A <= {"RGBPYX   ", buffer_end};
    row_A <= "RGBPYX          ";
    row_B <= {num_to_ascii(ans_count[0]), num_to_ascii(ans_count[1]), num_to_ascii(ans_count[2]), 
                num_to_ascii(ans_count[3]), num_to_ascii(ans_count[4]), num_to_ascii(ans_count[5]-7),
                "          "};
  end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule

