`timescale 1ns / 1ps
module lab4(
    input clk,
    input reset_n,
    input [3:0] usr_btn,
    output [3:0] usr_led
);
    wire [3:0] btn_real;
    debounce btn0(
        .clk(clk), 
        .reset_n(reset_n),
        .btn_in(usr_btn[0]),
        .btn_out(btn_real[0])
    );
    debounce btn1(
        .clk(clk), 
        .reset_n(reset_n),
        .btn_in(usr_btn[1]),
        .btn_out(btn_real[1])
    );
    debounce btn2(
        .clk(clk), 
        .reset_n(reset_n),
        .btn_in(usr_btn[2]),
        .btn_out(btn_real[2])
    );
    debounce btn3(
        .clk(clk), 
        .reset_n(reset_n),
        .btn_in(usr_btn[3]),
        .btn_out(btn_real[3])
    );
    reg [3:0] counter;
    wire [3:0] gray_out;
    reg [3:0] brightness;
    reg [19:0] pwm;
    reg [3:0] led_out;
    assign usr_led = led_out;
    assign gray_out[3] = counter[3];
    assign gray_out[2] = counter[3] ^ counter[2];
    assign gray_out[1] = counter[2] ^ counter[1];
    assign gray_out[0] = counter[1] ^ counter[0]; 
    always @(posedge clk, negedge reset_n) begin
        if(reset_n == 0) begin
            counter <= 0;
            pwm <= 0;
            brightness <= 0;
        end else begin
            if (btn_real[0] && counter != 0) counter <= counter - 1;
            else if (btn_real[1] && counter != 15) counter <= counter + 1;
            if (btn_real[3] && brightness != 0) brightness <= brightness - 1;
            else if (btn_real[2] && brightness != 4) brightness <= brightness + 1;
            
            if (brightness == 0 && pwm <= 50000) led_out <= gray_out;
            else if (pwm <= brightness * 250000) led_out <= gray_out;
            else led_out <= 0;
            if(pwm != 1000000) pwm <= pwm+1;
            else pwm <= 0;
        end
    end
endmodule


module debounce(
    input wire clk,
    input wire reset_n,
    input wire btn_in,
    output wire btn_out
);

    reg [19:0] counter = 0;
    reg stable, last, result;
    assign btn_out = result;

    always @(posedge clk, negedge reset_n) begin
        if (reset_n == 0) begin
            counter <= 0;
            last <= 0;
            stable <= 0;
            result <= 0;
        end else begin
            if(btn_in != stable)begin
                counter <= counter+1;
                if(counter >= 1000000)begin
                    stable <= btn_in;
                    counter <= 0;
                end
            end else begin
                counter <= 0;
            end
            if(stable && !last) result <= 1;
            else result <= 0;
            last <= stable;
        end
        
    end

endmodule

