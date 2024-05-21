`timescale 1ns/1ps

`include "TREE.v"

`define CYCLE 0.5 // 2 GHz

module TEST_TREE;

	reg		   CLK;
	reg [52:0] X, Y;
	reg [7:0] counter;
	wire [105:0] Z;
	integer i;

	always #(`CYCLE/2) CLK = ~CLK;

	TREE TREE(.CLK( CLK ), .X( X ), .Y( Y ), .Z( Z ));

	initial begin
	
		$fsdbDumpfile("TREE.fsdb");
		$fsdbDumpvars;

		CLK = 0;
		counter = 0;
		X = {53{1'b1}};
		Y = {53{1'b1}};
		for(i = 0 ;i < 50;i = i + 1)
			#(`CYCLE);
		$finish;
	end
	always @(posedge CLK) counter = counter + 1;
endmodule
