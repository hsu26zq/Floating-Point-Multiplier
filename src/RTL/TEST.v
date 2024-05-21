//------------------------------------------------------//
//- Final Project										//
//														//
//- Floating Point Number Multiplier TestBench			//
//------------------------------------------------------//

`timescale 1ns/1ps

`include "FP_MUL.v"

`define COUNT 1000
`define CYCLE 0.5 // 2 GHz

module TEST;

	integer FILE;
	integer CNT;
	integer i, j;

	reg		   CLK;
	reg		   RESET;
	reg		   ENABLE;
	reg [7:0]  DATA_IN;
	reg [63:0] A;
	reg [63:0] B;
	reg [63:0] Z;
	reg [63:0] C;
	
	wire [7:0]  DATA_OUT;
	wire		   READY;

	always #(`CYCLE/2) CLK = ~CLK;

	FP_MUL FP_MUL(.CLK(CLK), .RESET(RESET), .ENABLE(ENABLE), .DATA_IN(DATA_IN), .DATA_OUT(DATA_OUT), .READY(READY));

	initial begin
	
		$fsdbDumpfile("FP_MUL.fsdb");
		$fsdbDumpvars;

        $toggle_count("TEST.FP_MUL");

		FILE = $fopen("pattern.dat", "r");
		if(!FILE) begin
			$display("Unable to Open File.");
			$finish;
		end

		CLK = 0;
		RESET = 1;
		ENABLE = 0;
		A = 0;
		B = 0;
		C = 0;
		Z = 0;
		DATA_IN = 0;

		@(negedge CLK) RESET = 1'b1;
		@(negedge CLK) RESET = 1'b0;

		for(j = 0; j < `COUNT; j = j + 1) begin
			FEED_PATTERN;
			CHECK_PATTERN;

			repeat(2) @(negedge CLK);
		end

		$display("Pass !\n");
		$toggle_count_report_flat("FP_MUL.tcf", "TEST.FP_MUL");
		$finish;
	end

	task FEED_PATTERN;
	integer i;
	begin
		CNT = $fscanf(FILE, "%x", A);
		CNT = $fscanf(FILE, "%x", B);

		for(i = 0; i < 8; i = i + 1)
			@(negedge CLK) begin
				ENABLE = 1'b1;
				DATA_IN = A[8*i +: 8];
			end
		for(i = 0; i < 8; i = i + 1)
			@(negedge CLK) begin
				ENABLE = 1'b1;
				DATA_IN = B[8*i +: 8];
			end
		@(negedge CLK) ENABLE = 1'b0;
	end
	endtask

	task CHECK_PATTERN;
	integer i;
	begin
		CNT = $fscanf(FILE, "%x", C);

		@(posedge READY)
			for(i = 0; i < 8; i = i + 1)
				@(negedge CLK) Z[8*i +: 8] = DATA_OUT;
		
		SHOW_PATTERN;

		if(Z != C &&
		  !(Z[62:52] == 11'd2047 && Z[51:0] != 0 && // NaN
			C[62:52] == 11'd2047 && C[51:0] != 0)) begin
			$display("Wrong !\n");
			#(`CYCLE * 2);
			$finish;
		end
	end
	endtask

	task SHOW_PATTERN;
	begin
		$display("\n");
		$display("%0d.", j+1);
		$display("**********************************************************************");
		$display("A = %x_%x_%x", A[63], A[62:52], A[51:0]);
		$display("B = %x_%x_%x", B[63], B[62:52], B[51:0]);
		$display("------------------- Your Result --------------------------------------");
		$display("Z = %x_%x_%x", Z[63], Z[62:52], Z[51:0]);
		$display("------------------- Correct Result -----------------------------------");
		$display("C = %x_%x_%x", C[63], C[62:52], C[51:0]);
		$display("**********************************************************************");
	end
	endtask

endmodule
