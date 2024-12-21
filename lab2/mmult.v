`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/18 13:54:22
// Design Name: 
// Module Name: mmult
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


module mmult(
    input wire clk,
    input wire reset_n, 
    input wire enable, 
    input wire [0:9*8-1] A_mat,
    input wire [0:9*8-1] B_mat,
    output wire valid,
    output reg [0:9*18-1] C_mat 
);
    reg [1:0] check;

    assign valid = &check;

    integer j, k;

    always @(posedge clk)begin
        if((!enable) || (!reset_n)) begin
            C_mat <= 0;
            check <= 0;
        end else if(enable && (~&check)) begin
            for(j = 0; j<3; j=j+1)begin
                for(k = 0; k<3; k=k+1)begin
                    C_mat[(check*3+j)*18 +: 18] = (C_mat[(check*3+j)*18 +: 18] 
                                                        + A_mat[(check*3+k)*8 +: 8]*B_mat[(k*3+j)*8 +: 8]);
                end
            end
            check <= check+1;
        end
    end

endmodule
