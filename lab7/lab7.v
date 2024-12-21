`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_WAIT = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_POOL = 3'b010, S_MAIN_CALC = 3'b011,
                 S_MAIN_UPDATE = 3'b100, S_MAIN_SHOW = 3'b101;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN = 199; // length of the prompt message
localparam MEM_SIZE   = PROMPT_LEN;

// declare system variables
wire [1:0]  btn_level, btn_pressed;
wire print_done, print_enable;
reg [$clog2(MEM_SIZE):0] send_counter;
reg  prev_btn_level;
//reg [3:0] led;
reg  [2:0]  P, P_next;
reg [1:0] Q, Q_next;
reg [7:0] data[0:MEM_SIZE-1];
reg  [7:0]  user_data;
reg  [0:PROMPT_LEN*8-1] matrix_msg = {
    "The matrix operation result is:\015\012", //33
    "[00000,00000,00000,00000,00000]\015\012", //1, 7, 13, 19, 25
    "[00000,00000,00000,00000,00000]\015\012",
    "[00000,00000,00000,00000,00000]\015\012",
    "[00000,00000,00000,00000,00000]\015\012",
    "[00000,00000,00000,00000,00000]\015\012",
    8'h00
};
//Update
integer idx;
reg [3:0] i, j, k2;
reg update_done;
// Calculate
reg [25*19-1:0] C_mat;
reg [3:0] row2, col2, k;
reg calc_done;
reg [19:0] temp;
// Pooling 
reg [25*8-1:0] A_pool;
reg [25*8-1:0] B_pool;
reg [3:0] row, col, k1;
reg [7:0] max_valA, max_valB;
reg pool_done;
// Read matrix A B
reg [49*8-1:0] A_mat;
reg [49*8-1:0] B_mat;
reg [5:0] addr1, addr1_d;
reg read_done;
reg [3:0] row_idx, col_idx;
reg  [11:0] user_addrA, user_addrB;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire is_num_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;

// declare SRAM control signals
wire [10:0] sram_addrA, sram_addrB;
wire [7:0]  data_in;
wire [7:0]  data_A, data_B;
wire        sram_we, sram_en;

//assign usr_led = led;
assign usr_led = 4'b0000;

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level[1];
end

assign btn_pressed = (btn_level[1] & ~prev_btn_level);


/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//

reg [8:0] data_index, C_mat_index;

always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < PROMPT_LEN; idx = idx + 1) data[idx] = matrix_msg[idx*8 +: 8];
    //led <= 4'b0000;
  end
  else if(P == S_MAIN_WAIT) begin
    i <= 1;
    j <= 0;
    k2 <= 0;
    update_done <= 0;
    data_index <= 0;
    C_mat_index <= 0;
  end
  else if(P == S_MAIN_UPDATE) begin
    if(!update_done)begin
        if(k2 != 0) begin
            if(k2 == 5)data[data_index] <= "0"+C_mat[C_mat_index +: 3];
            else data[data_index] <= ((C_mat[C_mat_index +: 4] > 9)? "7" : "0") + C_mat[C_mat_index +: 4];
        end
        //if(i == 4 && j == 0 && k2 == 5) led <= {C_mat[C_mat_index +: 3],1'b0};
        if(k2 < 5) begin
            data_index <= ((i * 33) + ((5-k2) + j * 6));
            C_mat_index <= (((i-1) * 5 + j)*19 + 4*k2 );
            k2 <= k2 + 1;
        end else begin
            k2 <= 0;
            j <= j+1;
            if(j == 4)begin
                j <= 0;
                i <= i+1;
                if(i == 5)update_done <= 1;
            end
        end
     end
  end
end

// FSM output logics: print string control signals.
assign print_enable = (P != S_MAIN_SHOW && P_next == S_MAIN_SHOW);
assign print_done = (tx_byte == 8'h0);

// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte  = data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
    if (~reset_n) send_counter <= PROMPT_STR;
    if(P_next == S_MAIN_SHOW)send_counter <= send_counter + (Q_next == S_UART_INCR);
    else send_counter <= PROMPT_STR;
end

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ramA(
    .clk(clk),
    .we(sram_we),
    .en(sram_en),
    .addr(sram_addrA),
    .data_i(data_in),
    .data_o(data_A)
);

sram ramB(
    .clk(clk),
    .we(sram_we),
    .en(sram_en),
    .addr(sram_addrB),
    .data_i(data_in),
    .data_o(data_B)
);

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addrA = user_addrA[11:0];
assign sram_addrB = user_addrB[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_WAIT;
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_WAIT:
        if(btn_pressed == 1)P_next <= S_MAIN_READ;
        else P_next <= S_MAIN_WAIT;
    S_MAIN_READ:
        if (read_done) P_next <= S_MAIN_POOL;
        else P_next <= S_MAIN_READ;
    S_MAIN_POOL:
        if(pool_done) P_next <= S_MAIN_CALC;
        else P_next <= S_MAIN_POOL;
    S_MAIN_CALC:
        if(calc_done) P_next <= S_MAIN_UPDATE;
        else P_next <= S_MAIN_CALC;
    S_MAIN_UPDATE:
        if(update_done) P_next <= S_MAIN_SHOW;
        else P_next <= S_MAIN_UPDATE;
    S_MAIN_SHOW:
        if (print_done) P_next <= S_MAIN_WAIT;
        else P_next <= S_MAIN_SHOW;
  endcase
end


// Read matrix A B

always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_WAIT) begin
    addr1 <= 0;
    addr1_d <= 0;
    A_mat <= 0;
    B_mat <= 0;
    read_done <= 0;
    user_addrA <= 0;
    user_addrB <= 49;
  end
  else if(P == S_MAIN_READ)begin
    addr1_d <= addr1;
    if (addr1 <= 49) begin
      user_addrA <= user_addrA + 1;
      user_addrB <= user_addrB + 1;
      addr1 <= addr1 + 1;
      if(addr1 > 0)begin
        row_idx = (addr1_d) % 7;
        col_idx = (addr1_d) / 7;
        A_mat[(row_idx * 7 + col_idx) * 8 +: 8] <= data_A;
        B_mat[(row_idx * 7 + col_idx) * 8 +: 8] <= data_B;
      end
    end else begin
      read_done <= 1;
    end
  end
end

// Pooling 

reg [3:0] block_row, block_col;

always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_WAIT) begin
    row <= 0;
    col <= 0;
    k1 <= 0;
    pool_done <= 0;
    max_valA <= 0;
    max_valB <= 0;
  end
  else if(P == S_MAIN_POOL)begin
    if (row < 5 && col < 5) begin
        if(k1 < 9) begin
            // Max-pooling for A_mat
            block_row = (k1 / 3);
            block_col = (k1 % 3);
            if (A_mat[((row + block_row) * 7 + (col + block_col)) * 8 +: 8] > max_valA) max_valA <= A_mat[((row + block_row) * 7 + (col + block_col)) * 8 +: 8];
    
            // Max-pooling for B_mat
            if (B_mat[((row + block_row) * 7 + (col + block_col)) * 8 +: 8] > max_valB) max_valB <= B_mat[((row + block_row) * 7 + (col + block_col)) * 8 +: 8];
    
            // Move to the next column
            k1 <= k1 + 1;
        end
        if(k1 == 9) begin
            k1 <= 0;
            // Store the max value
            A_pool[(row * 5 + col) * 8 +: 8] <= max_valA;
            B_pool[(row * 5 + col) * 8 +: 8] <= max_valB;
            max_valA <= 0;
            max_valB <= 0;
            col <= col + 1;
            if (col == 4) begin
                // Move to the next row
                col <= 0;
                row <= row + 1;
                if (row == 4) begin
                    // Pooling is done
                    pool_done <= 1;
                end
            end
        end
    end
  end
end

// Calculate

reg [7:0] row_index, col_index;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n || P == S_MAIN_WAIT) begin
        C_mat <= 0;
        row2 <= 0;
        col2 <= 0;
        k <= 0;
        calc_done <= 0;
        temp <= 0;
    end else if (P == S_MAIN_CALC) begin
        if (!calc_done) begin
            // Perform the accumulation for C_mat[row][col]
            if (k <= 5) begin
                if (k < 5)row_index <= A_pool[(row2 * 5 + k) * 8 +: 8];
                if (k < 5)col_index <= B_pool[(col2 * 5 + k) * 8 +: 8];
                if(k != 0) temp <= temp + row_index * col_index;
                k <= k + 1;
            end else begin
                k <= 0;
                C_mat[(row2 * 5 + col2) * 19 +: 19] <= temp; 
                temp <= 0;
                if (col2 < 4) begin
                    col2 <= col2 + 1;
                end else begin
                    col2 <= 0;
                    if (row2 < 4) begin
                        row2 <= row2 + 1;
                    end else begin
                        row2 <= 0;
                        calc_done <= 1;
                    end
                end
            end
        end
    end
end

endmodule
