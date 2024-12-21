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

    localparam [1:0] S_MAIN_INIT = 2'b00, S_MAIN_CALC = 3'b01,
                 S_MAIN_SHOW = 2'b10;
    
    //reg [255:0] passwd_hash = 256'hf120bb5698d520c5691b6d603a00bfd662d13bf177a04571f9d10c0745dfa2a5;
    reg [255:0] passwd_hash = 256'hbb421fa35db885ce507b0ef5c3f23cb09c62eb378fae3641c165bdf4c0272949;
    reg [55:0] timer;
    reg [8*9-1:0] txt [0:4];
    wire [8*9-1:0] ans [0:4];
    wire [255:0] hash [0:4];
    wire done [0:4];
    reg calc_done;
    reg [8*9-1:0] ans_reg;
    reg [127:0] row_A;    
    reg [127:0] row_B;
    reg  [1:0] P, P_next;
    wire btn_level, btn_pressed;
    reg  prev_btn_level;
    reg pre_done [0:4];

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

    sha256 s0(
        .clk(clk),
        .reset(~reset_n),
        .input_number(txt[0]),
        .hash(hash[0]),
        .done(done[0]),
        .answer_number(ans[0])
    );
    
    sha256 s1(
        .clk(clk),
        .reset(~reset_n),
        .input_number(txt[1]),
        .hash(hash[1]),
        .done(done[1]),
        .answer_number(ans[1])
    );
    
    sha256 s2(
        .clk(clk),
        .reset(~reset_n),
        .input_number(txt[2]),
        .hash(hash[2]),
        .done(done[2]),
        .answer_number(ans[2])
    );
    
    sha256 s3(
        .clk(clk),
        .reset(~reset_n),
        .input_number(txt[3]),
        .hash(hash[3]),
        .done(done[3]),
        .answer_number(ans[3])
    );
    
    sha256 s4(
        .clk(clk),
        .reset(~reset_n),
        .input_number(txt[4]),
        .hash(hash[4]),
        .done(done[4]),
        .answer_number(ans[4])
    );
    
    

    debounce btn_db0(
        .clk(clk),
        .btn_input(usr_btn[3]),
        .btn_output(btn_level)
    );

    //
    // Enable one cycle of btn_pressed per each button hit
    //
    integer i;
    always @(posedge clk, negedge reset_n) begin
        if (~reset_n) begin
            prev_btn_level <= 0;
            for(i = 0; i<5; i=i+1) pre_done[i] <= 0;
        end else begin
            prev_btn_level <= btn_level;
            if(P == S_MAIN_INIT) for(i = 0; i<5; i=i+1) pre_done[i] <= 0;
            else for(i = 0; i<5; i=i+1) pre_done[i] <= done[i];
        end
    end

    assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

    function [7:0] num_to_ascii;
        input [3:0] num;
        begin
            if (num < 10)
                num_to_ascii = "0" + num;
            else
                num_to_ascii = "7" + num;
        end
    endfunction

    // FSM of the main controller
    always @(posedge clk) begin
        if (~reset_n) begin
            P <= S_MAIN_INIT;
        end
        else begin
            P <= P_next;
        end
    end

    always @(*) begin // FSM next-state logic
        case (P)
            S_MAIN_INIT:
                if(btn_pressed == 1)P_next <= S_MAIN_CALC;
                else P_next <= S_MAIN_INIT;
            S_MAIN_CALC:
                if (calc_done) P_next <= S_MAIN_SHOW;
                else P_next <= S_MAIN_CALC;
            S_MAIN_SHOW:
                P_next <= S_MAIN_SHOW;
        endcase
    end

    // Timer
    always @(posedge clk, negedge reset_n) begin
        if (!reset_n || P == S_MAIN_INIT) begin
            timer <= 0;
        end else if (P == S_MAIN_CALC) begin
            timer <= (timer != 56'hFFFFFFFFFFFFFF) ? (timer + 1) : timer;
        end
    end
    integer j;
    always @(posedge clk, negedge reset_n) begin
        if (!reset_n || P == S_MAIN_INIT) begin
            calc_done <= 0;
        end else begin
            for(j = 0; j<5; j=j+1) begin
                if (hash[j] == passwd_hash) begin
                    calc_done <= 1; 
                    ans_reg <= ans[j];
                end
           end
        end
    end
    integer k;
    always @(posedge clk) begin
        if (!reset_n || P == S_MAIN_INIT) begin
            txt[0] <= "000000000";
            txt[1] <= "200000000";
            txt[2] <= "400000000";
            txt[3] <= "600000000";
            txt[4] <= "800000000";
        end else if (P == S_MAIN_CALC) begin
            for(k = 0; k<5; k=k+1)begin
               if(pre_done[k] == 0 && done[k] == 1) begin
                if (txt[k][7:0] == "9") begin  // ASCII '9'
                    txt[k][7:0] <= "0";        // ASCII '0'
                    if (txt[k][15:8] == "9") begin
                        txt[k][15:8] <= "0";
                        if (txt[k][23:16] == "9") begin
                            txt[k][23:16] <= "0";
                            if (txt[k][31:24] == "9") begin
                                txt[k][31:24] <= "0";
                                if (txt[k][39:32] == "9") begin
                                    txt[k][39:32] <= "0";
                                    if (txt[k][47:40] == "9") begin
                                        txt[k][47:40] <= "0";
                                        if (txt[k][55:48] == "9") begin
                                            txt[k][55:48] <= "0";
                                            if (txt[k][63:56] == "9") begin
                                                txt[k][63:56] <= "0";
                                                if (txt[k][71:64] != "9") begin
                                                    txt[k][71:64] <= txt[k][71:64] + 1; // Increment the most significant digit 
                                                end
                                            end else begin
                                                txt[k][63:56] <= txt[k][63:56] + 1; // Increment the next digit
                                            end
                                        end else begin
                                            txt[k][55:48] <= txt[k][55:48] + 1;
                                        end
                                    end else begin
                                        txt[k][47:40] <= txt[k][47:40] + 1;
                                    end
                                end else begin
                                    txt[k][39:32] <= txt[k][39:32] + 1;
                                end
                            end else begin
                                txt[k][31:24] <= txt[k][31:24] + 1;
                            end
                        end else begin
                            txt[k][23:16] <= txt[k][23:16] + 1;
                        end
                    end else begin
                        txt[k][15:8] <= txt[k][15:8] + 1;
                    end
                end else begin
                    txt[k][7:0] <= txt[k][7:0] + 1; // Increment the least significant digit
                end
            end 
            end
        end
    end

    // LCD Display
    always @(posedge clk, negedge reset_n) begin
        if (!reset_n || P == S_MAIN_INIT) begin
            row_A <= "Press  BTN3  to ";
            row_B <= "start calcualte ";
        end else if (P == S_MAIN_CALC) begin
            row_A <= "Calculating.....";
            row_B <= {txt[4], "       "};
        end else if (P == S_MAIN_SHOW) begin
            row_A <= {"Pwd:", ans_reg, "   "};
            row_B <= {"T:", num_to_ascii(timer[55:52]), num_to_ascii(timer[51:48]), num_to_ascii(timer[47:44]), num_to_ascii(timer[43:40]),
                            num_to_ascii(timer[39:36]), num_to_ascii(timer[35:32]), num_to_ascii(timer[31:28]), num_to_ascii(timer[27:24]),
                            num_to_ascii(timer[23:20]), num_to_ascii(timer[19:16]), num_to_ascii(timer[15:12]), num_to_ascii(timer[11:8]),
                            num_to_ascii(timer[7:4]), num_to_ascii(timer[3:0])};
        end
    end
    

endmodule
