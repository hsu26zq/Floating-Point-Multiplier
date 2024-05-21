//------------------------------------------------------//
//- Final Project										//
//														//
//- Pipelined Wallace Tree (TREE, CELL, FA modules)		//
//------------------------------------------------------//

`timescale 1ns/1ps

module TREE(CLK, X, Y, Z); // 46 cycles

	input CLK;
	input [52:0] X; //MULTIPLICAND
	input [52:0] Y; //MULTIPLIER
	output reg [105:0] Z;

	genvar i;
	integer k;

//-------- Partial Products Generator --------//

	reg [105:0] PP [52:0];

	always @(posedge CLK)
		for(k = 0; k < 53; k = k + 1)
			if(Y[k] == 1'b1)
				PP[k] <= X << k;
			else
				PP[k] <= 106'b0;
//--------------------------------------------//

//---------------- Stage One -----------------// PP[51], PP[52] left

	wire [105:0] S1_S [16:0];
	wire [105:0] S1_Cout [16:0];

	generate
	for(i = 0; i < 17; i = i + 1)
		CELL U1_1(.CLK( CLK ), .A( PP[i*3] ), .B( PP[(i*3)+1] ), .Cin( PP[(i*3)+2] ), .S( S1_S[i] ), .Cout( S1_Cout[i] ));
	endgenerate
//--------------------------------------------//

//---------------- Stage Two -----------------//

	wire [105:0] S2_S [11:0];
	wire [105:0] S2_Cout [11:0];

	generate
	for(i = 0; i < 6; i = i + 1)
		CELL U2_1(.CLK( CLK ), .A( S1_S[i*3] ), .B( S1_Cout[(i*3)] ), .Cin( S1_S[(i*3)+1] ), .S( S2_S[i*2] ), .Cout( S2_Cout[i*2] ));
	for(i = 0; i < 5; i = i + 1)
		CELL U2_2(.CLK( CLK ), .A( S1_Cout[(i*3)+1] ), .B( S1_S[(i*3)+2] ), .Cin( S1_Cout[(i*3)+2] ), .S( S2_S[(i*2)+1] ), .Cout( S2_Cout[(i*2)+1] ));
	CELL U2_3(.CLK( CLK ), .A( S1_Cout[16] ), .B( PP[51] ), .Cin( PP[52] ), .S( S2_S[11] ), .Cout( S2_Cout[11] ));
	endgenerate
//--------------------------------------------//

//---------------- Stage Three ---------------//

	wire [105:0] S3_S [7:0];
	wire [105:0] S3_Cout [7:0];

	generate
	for(i = 0; i < 4; i = i + 1)
		CELL U3_1(.CLK( CLK ), .A( S2_S[i*3] ), .B( S2_Cout[(i*3)] ), .Cin( S2_S[(i*3)+1] ), .S( S3_S[i*2] ), .Cout( S3_Cout[i*2] ));
	for(i = 0; i < 4 ; i = i + 1)
		CELL U3_2(.CLK( CLK ), .A( S2_Cout[(i*3)+1] ), .B( S2_S[(i*3)+2] ), .Cin( S2_Cout[(i*3)+2] ), .S( S3_S[(i*2)+1] ), .Cout( S3_Cout[(i*2)+1] ));
	endgenerate
//--------------------------------------------//

//---------------- Stage Four ----------------// S3_Cout[7] left

	wire [105:0] S4_S [4:0];
	wire [105:0] S4_Cout [4:0];	

	generate
	for(i = 0; i < 3; i = i + 1)
		CELL U4_1(.CLK( CLK ), .A( S3_S[i*3] ), .B( S3_Cout[(i*3)] ), .Cin( S3_S[(i*3)+1] ), .S( S4_S[i*2] ), .Cout( S4_Cout[i*2] ));
	for(i = 0; i < 2 ; i = i + 1)
		CELL U4_2(.CLK( CLK ), .A( S3_Cout[(i*3)+1] ), .B( S3_S[(i*3)+2] ), .Cin( S3_Cout[(i*3)+2] ), .S( S4_S[(i*2)+1] ), .Cout( S4_Cout[(i*2)+1] ));
	endgenerate
//--------------------------------------------//

//---------------- Stage Five ----------------// S3_Cout[7], S4_Cout[4] left

	wire [105:0] S5_S [2:0];
	wire [105:0] S5_Cout [2:0];

	generate
	for(i = 0; i < 2; i = i + 1)
		CELL U5_1(.CLK( CLK ), .A( S4_S[i*3] ), .B( S4_Cout[(i*3)] ), .Cin( S4_S[(i*3)+1] ), .S( S5_S[i*2] ), .Cout( S5_Cout[i*2] ));
	for(i = 0; i < 1; i = i + 1)
		CELL U5_2(.CLK( CLK ), .A( S4_Cout[(i*3)+1] ), .B( S4_S[(i*3)+2] ), .Cin( S4_Cout[(i*3)+2] ), .S( S5_S[(i*2)+1] ), .Cout( S5_Cout[(i*2)+1] ));
	endgenerate
//--------------------------------------------//

//---------------- Stage Six -----------------// S3_Cout[7], S4_Cout[4] left

	wire [105:0] S6_S [1:0];
	wire [105:0] S6_Cout [1:0];

	generate
	for(i = 0; i < 1; i = i + 1)
		CELL U6_1(.CLK( CLK ), .A( S5_S[i*3] ), .B( S5_Cout[(i*3)] ), .Cin( S5_S[(i*3)+1] ), .S( S6_S[i*2] ), .Cout( S6_Cout[i*2] ));
	for(i = 0; i < 1; i = i + 1)
		CELL U6_2(.CLK( CLK ), .A( S5_Cout[(i*3)+1] ), .B( S5_S[(i*3)+2] ), .Cin( S5_Cout[(i*3)+2] ), .S( S6_S[(i*2)+1] ), .Cout( S6_Cout[(i*2)+1] ));
	endgenerate
//--------------------------------------------//

//---------------- Stage Seven ---------------//

	wire [105:0] S7_S [1:0];
	wire [105:0] S7_Cout [1:0];

	CELL U7_1(.CLK( CLK ), .A( S6_S[0] ), .B( S6_Cout[0] ), .Cin( S6_S[1] ), .S( S7_S[0] ), .Cout( S7_Cout[0] ));
	CELL U7_2(.CLK( CLK ), .A( S6_Cout[1] ), .B( S3_Cout[7] ), .Cin( S4_Cout[4] ), .S( S7_S[1] ), .Cout( S7_Cout[1] ));
//--------------------------------------------//

//---------------- Stage Eight ---------------// S7_Cout[1] left

	wire [105:0] S8_S;
	wire [105:0] S8_Cout;

	CELL U8_1(.CLK( CLK ), .A( S7_S[0] ), .B( S7_Cout[0] ), .Cin( S7_S[1] ), .S( S8_S ), .Cout( S8_Cout ));
//--------------------------------------------//

//---------------- Stage Nine ----------------//

	wire [105:0] S9_S;
	wire [105:0] S9_Cout;

	CELL U9_1(.CLK( CLK ), .A( S8_S ), .B( S8_Cout ), .Cin( S7_Cout[1] ), .S( S9_S ), .Cout( S9_Cout ));
//--------------------------------------------//

//---------------- Stage Ten -----------------// 36 cycles
	
	wire [105:0] S10_S;
	wire S10_Cout;

	RCA_106x2 U10_1(.CLK( CLK ), .A( S9_S ), .B( S9_Cout ), .Cin( 1'b0 ), .S( S10_S ), .Cout( S10_Cout ));
	
	always @(posedge CLK)
		Z <= S10_S;
//--------------------------------------------//
endmodule

// Pipelined 106-bit Carry-Save Adder
module CELL(CLK, A, B, Cin, S, Cout);
	
	input CLK;
	input [105:0] A, B, Cin;
	output reg [105:0] S, Cout;

	always @(posedge CLK) begin
		S <= A ^ B ^ Cin;
		Cout[0] <= 1'b0;
		Cout[105:1] <= ((A & B) | (B & Cin) | (Cin & A));
	end
endmodule

// 2 x 3-bit Ripple-Carry Adder
module FA(CLK, A, B, Cin, S, Cout);

	input CLK;
	input [2:0] A, B;
	input Cin;
	output reg [2:0] S;
	output reg Cout;

	always @(posedge CLK) begin
		{Cout, S} <= A + B + Cin;
	end
endmodule

// Pipelined 2 x 106-bit Ripple-Carry Adder
module RCA_106x2(CLK, A, B, Cin, S, Cout);

	input CLK;
	input [105:0] A, B;
	input Cin;
	output [105:0] S;
	output Cout;

	wire [34:0] TEMP_C;
	genvar i;

	generate
	FA U1(.CLK( CLK ), .A( A[2:0] ), .B( B[2:0] ), .Cin( Cin ), .S( S[2:0] ), .Cout( TEMP_C[0] ));
	for(i = 1; i < 35; i = i + 1)
		FA U2(.CLK( CLK ), .A( A[(i*3)+2:i*3] ), .B( B[(i*3)+2:i*3] ), .Cin( TEMP_C[i-1] ), .S( S[(i*3)+2:i*3] ), .Cout( TEMP_C[i] ));
	FA U3(.CLK( CLK ), .A( {1'b0, 1'b0, A[105]} ), .B( {1'b0, 1'b0, B[105]} ), .Cin( TEMP_C[34] ), .S( {S[105]} ), .Cout( Cout ));
	endgenerate
endmodule
