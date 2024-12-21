module SeqMultiplier(
    input wire clk,
    input wire enable,
    input wire [7:0] A,
    input wire [7:0] B,
    input wire [15:0] C
);

    //Internal Signles
    wire shift, clk, enable;
    reg [3:0] counter;
    reg [7:0] mult;
    reg [15:0] prod;

    assign shift = |(counter^7);
    assign C = prod;

    always @(posedge clk) begin
        if(!enable) begin
            mult <= B;
            prod <= 0;
            counter <= 0;
        end else begin
            prod <= (prod + (A & {8{mult[7]}})) << shift;
            mult <= mult << 1;
            counter <= counter+shift;
        end
    end
endmodule

