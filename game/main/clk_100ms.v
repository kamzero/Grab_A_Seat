`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:13:43 11/27/2019 
// Design Name: 
// Module Name:    clk_100ms 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clk_100ms(
		input wire clk,
		output reg clk_100ms
	);
	reg [31: 0] cnt;
	initial cnt <= 32'b0;
	always @(posedge clk) begin
		cnt = cnt + 1;
		if (cnt == 32'b 1000000_0000_0000_0000000) begin
			clk_100ms = 1;
			cnt = 0;
		end
		else clk_100ms = 0;
	end
endmodule

