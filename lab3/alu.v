`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/25 13:13:09
// Design Name: 
// Module Name: alu
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


module alu(
  // DO NOT modify the interface!
  // input signal
  input [7:0] accum,
  input [7:0] data,
  input [2:0] opcode,
  input reset,
  
  // result
  output [7:0] alu_out,
  
  // PSW
  output zero,
  output overflow,
  output parity,
  output sign
);

  //Internal Signals
  reg signed [7:0] result;
  reg signed [7:0] accum_m;
  reg signed [7:0] data_m;
  reg signed [3:0] sa, sd;
  reg zero_result;
  reg parity_result;
  reg sign_result;
  reg overflow_result;

  assign alu_out = result;
  assign zero = zero_result;
  assign parity = parity_result;
  assign sign = sign_result;
  assign overflow = overflow_result;

  //Main function
  always @(*) begin
    accum_m = accum;
    data_m = data;
    sa = accum[3:0];
    sd = data[3:0];
    if(reset)begin
      result = 0;
      zero_result = 0;
      parity_result = 0;
      sign_result = 0;
      overflow_result = 0;
    end else begin
        case (opcode)
          3'b000: result = accum_m;
          3'b001: result = (accum_m+data_m);
          3'b010: result = (accum_m-data_m);
          3'b011: result = (accum_m>>>data_m);
          3'b100: result = (accum_m^data_m);
          3'b101: result = (accum_m < 0)? (-accum_m):accum_m;
          3'b110: result = sa*sd;
          3'b111: result = (-accum_m);
          default: result = 0;
        endcase
        if(opcode == 3'b001) overflow_result = ((accum[7] == data[7]) && (result[7] != accum[7]));
        else if(opcode == 3'b010) overflow_result = ((accum[7] != data[7]) && (result[7] != accum[7]));
        if(overflow && accum[7] == 0) result = 127;
        else if(overflow && accum[7] == 1) result = -128;
        zero_result = ~|result;
        parity_result = ^result;
        sign_result = (result < 0)? 1 : 0;
    end
  end
endmodule
