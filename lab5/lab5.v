`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
    input clk,
    input reset_n,
    input [3:0] usr_btn,      // button 
    input [3:0] usr_sw,       // switches
    output [3:0] usr_led,     // led
    output LCD_RS,
    output LCD_RW,
    output LCD_E,
    output [3:0] LCD_D
);

    assign usr_led = 4'b0000; // turn off led
    
    reg [31:0] period, count;
    reg [7:0] display_A [0:2];
    reg [7:0] display_B [0:2];
    reg [127:0] row_A = "    |2|8|2|     ";    
    reg [127:0] row_B = "    |1|9|1|     ";
    reg [1:0] game_state;
    reg [3:0] usr_sw_prev;

    parameter GAME_INIT = 2'b00;
    parameter GAME_RUNNING = 2'b01;
    parameter GAME_ERROR = 2'b10;
    parameter GAME_STOPPED = 2'b11;

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

    function [7:0] num_to_ascii;
        input [7:0] num;
        begin
            if (num < 10)
                num_to_ascii = "0" + num;
            else
                num_to_ascii = "0";
        end
    endfunction

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            period <= 0;
            count <= 0;
            display_A[0] = 8'd2;
            display_A[1] = 8'd8;
            display_A[2] = 8'd2;
            display_B[0] = 8'd1;
            display_B[1] = 8'd9;
            display_B[2] = 8'd1;
            row_A <= "    |2|8|2|     ";    
            row_B <= "    |1|9|1|     ";
            game_state <= GAME_INIT;
            usr_sw_prev <= 4'b1111;
        end else begin
            if(period%1_000_000 == 0) usr_sw_prev <= usr_sw; 
            case (game_state)
                GAME_INIT: begin
                    if (!usr_sw[0]) begin
                        game_state <= GAME_RUNNING;
                    end else if (!usr_sw[3] || !usr_sw[2] || !usr_sw[1]) begin
                        game_state <= GAME_ERROR;
                    end
                end
                GAME_RUNNING: begin
                    if (((usr_sw_prev[3] == 0) && (usr_sw[3] == 1)) ||
                        ((usr_sw_prev[2] == 0) && (usr_sw[2] == 1)) ||
                        ((usr_sw_prev[1] == 0) && (usr_sw[1] == 1)) ||
                        ((usr_sw_prev[0] == 0) && (usr_sw[0] == 1))) begin
                        game_state <= GAME_ERROR;
                    end else begin
                        if(period != 100_000_000) period <= period+1;
                        else begin
                            period <= 0;
                            if(count != 1) count <= count+1;
                            else begin
                                count <= 0;
                                if (usr_sw[2]) begin
                                    display_A[1] = ((display_A[1]-1 == 0)? 9 : display_A[1]-1);
                                    display_B[1] = ((display_B[1]-1 == 0)? 9 : display_B[1]-1);
                                end
                            end
                            if (usr_sw[3]) begin
                                display_A[0] = ((display_A[0]+1 == 10)? 1 : display_A[0]+1);
                                display_B[0] = ((display_B[0]+1 == 10)? 1 : display_B[0]+1);
                            end
                            if (usr_sw[1]) begin
                                display_A[2] = ((display_A[2]+1 == 10)? 1 : display_A[2]+1);
                                display_B[2] = ((display_B[2]+1 == 10)? 1 : display_B[2]+1);
                            end
                            if(!usr_sw[2] && !usr_sw[1] && !usr_sw[3])begin
                                if(display_B[0] == display_B[1] && display_B[0] == display_B[2]) begin
                                    row_A <= "   Jackpots!    ";
                                    row_B <= "   Game over    ";
                                end else if(display_B[0] == display_B[1] || display_B[0] == display_B[2] || display_B[1] == display_B[2]) begin
                                    row_A <= "   Free Game!   ";
                                    row_B <= "   Game over    ";
                                end else begin
                                    row_A <= "   Loser!       ";
                                    row_B <= "   Game over    ";
                                end
                                game_state <= GAME_STOPPED;
                            end else begin
                                row_A <= { "    |", num_to_ascii(display_A[0]), "|", num_to_ascii(display_A[1]), "|", num_to_ascii(display_A[2]), "|     " };
                                row_B <= { "    |", num_to_ascii(display_B[0]), "|", num_to_ascii(display_B[1]), "|", num_to_ascii(display_B[2]), "|     " };
                            end
                        end
                    end
                end
                GAME_ERROR: begin
                    if(period != 100_000_000) period <= period+1;
                    else begin
                        period <= 0;
                        row_A <= "     ERROR      ";
                        row_B <= "  game stopped  ";
                    end
                end
                GAME_STOPPED: begin
                    
                end
                default: begin
                    game_state <= GAME_INIT;
                end
            endcase
        end
    end

endmodule