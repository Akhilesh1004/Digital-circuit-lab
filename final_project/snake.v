`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/11/27 15:05:37
// Design Name:
// Module Name: snake
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module snake
#(
parameter x_width = 20,
parameter y_length = 14
)
(
input clk,
input start,
input [3:0] usr_btn,
input rst,
input [1:0] diff,

output reg [3 * x_width * y_length - 1:0] stage_out,
output reg [1:0] scorechange,
output reg over
);

reg bump = 1;
reg [7:0] score = 0;
reg [31:0] counter = 0;
reg [$clog2(x_width):0] head_cord [1:0];
reg [1:0] btn_input = 0;
reg [7:0] age [x_width - 1:0][y_length - 1:0];
reg [3:0] stage [x_width - 1:0][y_length - 1:0];
reg [$clog2(x_width):0] next [1:0];
reg ate;
reg [1:0] direction;
reg [3:0] x_seed = 0, y_seed = 0;

reg [$clog2(x_width) : 0] ii; 
reg [$clog2(y_length) : 0] jj;

reg [3:0] x_rand [0:19];
reg [3:0] y_rand [0:13];

localparam up = 0, right = 1, down = 2, left = 3,
           turnleft = 2, turnright = 1,
           head = 1, body = 2, wall = 3, apple = 4;
wire btn3, btn0;
debounce db3 (.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn3));
debounce db0 (.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn0));

reg [0:19] walls[2:0][0:13]; // walls[diff][row][column]


initial begin
    // Wall pattern for walls[0]
    walls[0][0]  = 20'b00000000000000000000;
    walls[0][1]  = 20'b00000000000000000000;
    walls[0][2]  = 20'b00000000000000000000;
    walls[0][3]  = 20'b00000000000000000000;
    walls[0][4]  = 20'b00000000000000000000;
    walls[0][5]  = 20'b00000000000000000000;
    walls[0][6]  = 20'b00000000000000000000;
    walls[0][7]  = 20'b00000000000000000000;
    walls[0][8]  = 20'b00000000000000000000;
    walls[0][9]  = 20'b00000000000000000000;
    walls[0][10] = 20'b00000000000000000000;
    walls[0][11] = 20'b00000000000000000000;
    walls[0][12] = 20'b00000000000000000000;
    walls[0][13] = 20'b00000000000000000000;

    // Wall pattern for walls[1]
    walls[1][0]  = 20'b00000000000000000000;
    walls[1][1]  = 20'b00000000000000000000;
    walls[1][2]  = 20'b00011000000011111000;
    walls[1][3]  = 20'b00011000000011111000;
    walls[1][4]  = 20'b00011000000000000000;
    walls[1][5]  = 20'b00011000000000000000;
    walls[1][6]  = 20'b00000000000000000000;
    walls[1][7]  = 20'b00000000000000000000;
    walls[1][8]  = 20'b00000000000000011000;
    walls[1][9]  = 20'b00000000000000011000;
    walls[1][10] = 20'b00011111000000011000;
    walls[1][11] = 20'b00011111000000011000;
    walls[1][12] = 20'b00000000000000000000;
    walls[1][13] = 20'b00000000000000000000;

    // Wall pattern for walls[2]
    walls[2][0]  = 20'b00000000000000000000;
    walls[2][1]  = 20'b00000000000000000000;
    walls[2][2]  = 20'b00110000011000001100;
    walls[2][3]  = 20'b00110000011000001100;
    walls[2][4]  = 20'b00000000011000000000;
    walls[2][5]  = 20'b00000000011000000000;
    walls[2][6]  = 20'b00111111111111111100;
    walls[2][7]  = 20'b00111111111111111100;
    walls[2][8]  = 20'b00000000011000000000;
    walls[2][9]  = 20'b00000000011000000000;
    walls[2][10] = 20'b00110000011000001100;
    walls[2][11] = 20'b00110000011000001100;
    walls[2][12] = 20'b00000000000000000000;
    walls[2][13] = 20'b00000000000000000000;
    head_cord[0] <= 12;
    head_cord[1] <= 11;
    over <= 0;
    ate <= 1;
    x_rand[0] <= 4'd11;
    x_rand[1] <= 4'd14;
    x_rand[2] <= 4'd3;
    x_rand[3] <= 4'd9;
    x_rand[4] <= 4'd18;
    x_rand[5] <= 4'd17;
    x_rand[6] <= 4'd6;
    x_rand[7] <= 4'd1;
    x_rand[8] <= 4'd0;
    x_rand[9] <= 4'd2;
    x_rand[10] <= 4'd12;
    x_rand[11] <= 4'd13;
    x_rand[12] <= 4'd16;
    x_rand[13] <= 4'd10;
    x_rand[14] <= 4'd19;
    x_rand[15] <= 4'd4;
    x_rand[16] <= 4'd5;
    x_rand[17] <= 4'd7;
    x_rand[18] <= 4'd8;
    x_rand[19] <= 4'd15;
    y_rand[0] <= 4'd4;
    y_rand[1] <= 4'd9;
    y_rand[2] <= 4'd13;
    y_rand[3] <= 4'd7;
    y_rand[4] <= 4'd1;
    y_rand[5] <= 4'd6;
    y_rand[6] <= 4'd0;
    y_rand[7] <= 4'd12;
    y_rand[8] <= 4'd2;
    y_rand[9] <= 4'd10;
    y_rand[10] <= 4'd3;
    y_rand[11] <= 4'd8;
    y_rand[12] <= 4'd11;
    y_rand[13] <= 4'd5;
end
//counter + button logic
always @ (posedge clk) begin
    if (!rst) begin
        counter <= 0;
    end
    else if (counter < 40000007) begin
        counter <= counter + start;
    end
    else if (~over) begin counter <= 0; end
end

always @ (posedge clk) begin
    if (x_seed == 19) x_seed = 0;
    else x_seed = x_seed + 1;
    if (y_seed == 13) y_seed = 0;
    else y_seed = y_seed + 1;
end
wire [8:0] lengh = score + 5;

always @ (posedge clk) begin
if (!rst) begin
    head_cord[0] <= 12;
    head_cord[1] <= 11;
    over <= 0;
    ate <= 1;
    score <= 0;
    for(ii = 0; ii < x_width; ii = ii + 1) begin
        for(jj = 0; jj < y_length; jj = jj + 1) begin
            stage[ii][jj] <= 0;
            age[ii][ii] <= 0;
        end
    end
    btn_input <= 0;
    direction <= 0;
end

else begin
case(counter)
    0: begin
        for(ii = 0; ii < x_width; ii = ii + 1) begin
            for(jj = 0; jj < y_length; jj = jj + 1) begin
                if (walls[diff][jj][ii] == 1) begin
                    stage[ii][jj] <= wall;
                    
                end
            end
        end
    end
    39999999: begin 
        direction = direction + (btn_input == turnleft ? -1 : btn_input);
        btn_input <= 0;
    end
    40000000: begin //movement
        case(direction) //calculate next move
        up: begin
            next[0] <= head_cord[0];
            next[1] <= head_cord[1] - 1;
        end
        down: begin
            next[0] <= head_cord[0];
            next[1] <= head_cord[1] + 1;
        end
        left: begin
            next[0] <= head_cord[0] - 1;
            next[1] <= head_cord[1];
        end
        right: begin
            next[0] <= head_cord[0] + 1;
            next[1] <= head_cord[1];
        end
        endcase
    end
    40000001: begin
        if (next[0] >= x_width || next[1] >= y_length ||
             stage[next[0]][next[1]] == wall || stage[next[0]][next[1]] == body) begin
            if(score == 0) over <= 1;
            else begin 
                score <= score - 1;
                scorechange <= 2; 
                bump = 0;
            end
        end
        else begin
            if (stage[next[0]][next[1]] == apple) begin 
                ate <= 1;
                score <= score + 1; 
                scorechange <= 1;
            end
            head_cord[0] <= next[0];
            head_cord[1] <= next[1];
            stage[next[0]][next[1]] <= head;
            stage[head_cord[0]][head_cord[1]] <= body;
            bump <= 1;
        end
    end
    40000002: begin //tail dissapear
        for(ii = 0; ii < x_width; ii = ii + 1) begin
            for(jj = 0; jj < y_length; jj = jj + 1) begin
                if (stage[ii][jj] == body)  begin
                    if (age[ii][jj] >= lengh) begin 
                        stage[ii][jj] <= 0; 
                        age[ii][jj] <= 0; 
                    end
                    else if (bump) begin 
                        age[ii][jj] <= age[ii][jj] + 1; 
                    end
                end
            end
        end
        scorechange <= 0;
    end
    default: begin
        if (btn0 == 1 && btn_input == 0) btn_input <= turnright;
        else if (btn3 == 1 && btn_input == 0) btn_input <= turnleft;
        if (ate) begin
            if(stage[x_rand[x_seed]][y_rand[y_seed]] == 0) begin
                stage[x_rand[x_seed]][y_rand[y_seed]] <= apple;
                ate <= 0;
            end
        end
    end
endcase
end
end
reg [$clog2(x_width) : 0] i;
reg [$clog2(y_length) : 0] j;

always @ (posedge clk) begin
for(i = 0; i < x_width; i = i + 1) begin
    for(j = 0; j < y_length; j = j + 1) begin
        stage_out[((j*x_width + i)*3)+:3] <= stage[i][j];
    end
end
end

endmodule

module debounce(input clk, input btn_input, output btn_output);

parameter DEBOUNCE_PERIOD = 2_000_000; /* 20 msec = (100,000,000*0.2) ticks @100MHz */

reg [$clog2(DEBOUNCE_PERIOD):0] counter;

assign btn_output = (counter == DEBOUNCE_PERIOD);

always@(posedge clk) begin
  if (btn_input == 0)
    counter <= 0;
  else
    counter <= counter + (counter != DEBOUNCE_PERIOD + 1);
end

endmodule
