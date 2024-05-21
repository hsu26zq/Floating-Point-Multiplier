//------------------------------------------------------//
//- Final Project										//
//														//
//- Floating Point Number Multiplier					//
//------------------------------------------------------//

`timescale 1ns/1ps
`include "TREE.v"

module FP_MUL(input		  CLK,
			  input		  RESET,
			  input		  ENABLE,
			  input [7:0] DATA_IN,
	
			  output reg [7:0] DATA_OUT,
			  output reg	   READY);

parameter FETCH = 2'b00,
		  CAL   = 2'b01,
		  OUT   = 2'b11;

reg  [1:0]  current_state, next_state;
reg  [63:0] A, B;
wire [63:0] Z;
reg  [5:0]  counter;

CORE CORE(.CLK( CLK ),
		  .A_SIGN( A[63] ), .A_EXPONENT( A[62:52] ), .A_MANTISSA( A[51:0] ),
		  .B_SIGN( B[63] ), .B_EXPONENT( B[62:52] ), .B_MANTISSA( B[51:0] ),		
		  .Z_SIGN( Z[63] ), .Z_EXPONENT( Z[62:52] ), .Z_MANTISSA( Z[51:0] ));

always @(posedge CLK)
	if(RESET)
		current_state <= FETCH;
	else
		current_state <= next_state;


always @(*)
	case (current_state)
		FETCH: // Fetch Two Inputs
			if(counter == 6'd15) 
				next_state = CAL;
			else 
				next_state = FETCH;
		CAL: // Calculate
			if(counter == 6'd50) // 50 cycles
				next_state = OUT;
			else 
				next_state = CAL;
		OUT: // Output the Result
			if(counter == 6'd8) 
				next_state = FETCH;
			else 
				next_state = OUT;
		default:
			next_state = FETCH;
	endcase

always @(posedge CLK)
	if(RESET) begin
		counter <= 6'b0;
		READY <= 1'b0;
		DATA_OUT <= 8'b0;
	end
	else
		case (current_state)
			FETCH: begin
				if(ENABLE) begin
					if(counter < 6'd8)
						A[counter*8+:8] <= DATA_IN;
					else
						B[(counter-8)*8+:8] <= DATA_IN;
					if(counter == 6'd15) begin
						counter <= 6'b0;
					end
					else
						counter <= counter + 1;
				end
			end
			CAL: begin
				if(counter == 6'd50) // 50 cycles
					counter <= 6'b0;
				else
					counter <= counter + 1;
			end
			OUT: begin
				if(counter == 5'd8) begin
					READY <= 1'b0;
					counter <= 5'b0;
				end
				else begin
					READY <= 1'b1;
					DATA_OUT <= Z[counter*8+:8];
					counter <= counter + 1;
				end
			end
		endcase	
endmodule


module CORE(input CLK,
			input A_SIGN,
			input B_SIGN,
			input [10:0] A_EXPONENT,
			input [10:0] B_EXPONENT,
			input [51:0] A_MANTISSA,
			input [51:0] B_MANTISSA,

			output reg		  Z_SIGN,
			output reg [10:0] Z_EXPONENT,
			output reg [51:0] Z_MANTISSA);

reg [10:0] TEMP_EXPONENT;
reg [51:0] TEMP_MANTISSA;
//-------------------------Special Cases-------------------------//
always @(posedge CLK)
	if(A_EXPONENT == 11'd2047 && A_MANTISSA != 52'b0 || B_EXPONENT == 11'd2047 && B_MANTISSA != 52'b0) begin // IF A or B NaN THEN Z NaN
		Z_SIGN <= 1'b1;
		Z_EXPONENT <= 11'd2047;
		Z_MANTISSA <= 1'b1;
	end

	else if(A_EXPONENT == 11'd2047 && A_MANTISSA == 52'b0 ) // IF A Infinity
		if(B_EXPONENT == 11'b0 && B_MANTISSA == 52'b0) begin // IF B Zero THEN Z NaN, ELSE Z Infinity
			Z_SIGN <= 1'b1;
			Z_EXPONENT <= 11'd2047;
			Z_MANTISSA <= 1'b1;
		end
		else begin
			Z_SIGN <= A_SIGN;
			Z_EXPONENT <= A_EXPONENT;
			Z_MANTISSA <= A_MANTISSA;
		end

	else if(B_EXPONENT == 11'd2047 && B_MANTISSA == 52'b0 ) // IF B Infinity
		if(A_EXPONENT == 11'b0 && A_MANTISSA == 52'b0) begin // IF A Zero THEN Z NaN, ELSE Z Infinity
			Z_SIGN <= 1'b1;
			Z_EXPONENT <= 11'd2047;
			Z_MANTISSA <= 1'b1;
		end
		else begin
			Z_SIGN <= B_SIGN;
			Z_EXPONENT <= B_EXPONENT;
			Z_MANTISSA <= B_MANTISSA;
		end

	else if(A_EXPONENT == 11'b0 && A_MANTISSA == 52'b0) begin // IF A Zero THEN Z Zero
		Z_SIGN <=  A_SIGN;
		Z_EXPONENT <= A_EXPONENT;
		Z_MANTISSA <= A_MANTISSA;
	end

	else if(B_EXPONENT == 11'b0 && B_MANTISSA == 52'b0) begin // IF B Zero THEN Z Zero
		Z_SIGN <=  B_SIGN;
		Z_EXPONENT <= B_EXPONENT;
		Z_MANTISSA <= B_MANTISSA;
	end

	else begin // Non-Speical Cases 
		Z_SIGN <= ( ((A_SIGN && ~B_SIGN) || (~A_SIGN && B_SIGN)) ? 1'b1 : 1'b0 );
		Z_EXPONENT <= TEMP_EXPONENT;
		Z_MANTISSA <= TEMP_MANTISSA;
	end
//---------------------------------------------------------------//

//--------------------Mantissas Multiplicaion--------------------//
reg [52:0] OP1, OP2;
wire [105:0] PRODUCT;

TREE TREE(.CLK( CLK ), .X( OP1 ), .Y( OP2 ), .Z( PRODUCT ));

always @(*) begin
	if(A_EXPONENT == 11'b0 && A_MANTISSA != 52'b0) // A Denorm THEN Implicit Zero, ELSE One
		OP1 = {1'b0, A_MANTISSA};
	else
		OP1 = {1'b1, A_MANTISSA};

	if(B_EXPONENT == 11'b0 && B_MANTISSA != 52'b0) // B Denorm THEN Implicit Zero, ELSE One
		OP2 = {1'b0, B_MANTISSA};
	else
		OP2 = {1'b1, B_MANTISSA};
end
//---------------------------------------------------------------//

//----------------------Exponents Addition-----------------------//
wire signed [12:0] SUM;
wire Cout;

RCA_11x3 U1(.CLK( CLK ), .A( A_EXPONENT ), .B( B_EXPONENT ), .C( -11'd1023 ), .Cin( 1'b0 ), .S( SUM ), .Cout( Cout ));
//---------------------------------------------------------------//

reg triggerA, triggerB;
always @(*) begin // IF X Deform THEN set triggerX
	triggerA = !A_EXPONENT;
	triggerB = !B_EXPONENT;
end

//---------------------Find LeftMost Set Bit---------------------//
reg [105:0] REV, MSB, HOT;
reg [7:0] LOC;
reg signed [8:0] SHIFT;
integer i, j;

always @(posedge CLK) begin // Find Leftmost Set Bit of "PRODUCT"
	for(i = 0; i < 106; i = i + 1) // Reverse
		REV[i] <= PRODUCT[105 - i];
	MSB <= REV & (~REV + 1); // RightMost Set Bit
	for(i = 0; i < 106; i = i + 1) // Reverse again, LeftMost Set Bit
		HOT[i] <= MSB[105 - i];

	for(i = 0; i < 106; i = i + 1) // One-Hot to Binary
		if(HOT[i])
			LOC <= i; // Length from PRODUCT[0] to PRODUCT[i]

	SHIFT <= (LOC - 104); // Difference Between LeftMost Set Bit and Decimal Point	
end

//---------------------------------------------------------------//

reg signed [12:0] NORMALIZED_EXPONENT;
always @(posedge CLK)
	NORMALIZED_EXPONENT <= SUM + SHIFT;

//-------------Check if Exponent Overflow or Underflow-----------//

reg OVERFLOW, UNDERFLOW;
always @(posedge CLK) begin
	OVERFLOW <= (NORMALIZED_EXPONENT > 2046); // Overflow if SUM plus SHIFT greater than 111_1111_1110
	UNDERFLOW <= (NORMALIZED_EXPONENT < 1); // Underflow if SUM plus SHIFT less than 000_0000_0001
end
//---------------------------------------------------------------//

//--------------if Exponent Underflow, i.e., Z Denorm------------//

reg [10:0] BIAS;
always @(posedge CLK)
	BIAS <= -SUM - 1 - triggerA - triggerB;

reg [51:0] DENORM_MANTISSA_1, DENORM_MANTISSA_0, NORMALIZED_MANTISSA;
wire [51:0] NORMALIZED_MANTISSA_1;
RCA_52x1 RCA_52x1_0(.CLK( CLK ), .A( NORMALIZED_MANTISSA ), .Cin( 1'b1 ), .S( NORMALIZED_MANTISSA_1 ), .Cout());
always @(posedge CLK) begin // output
	NORMALIZED_MANTISSA  <= PRODUCT[105:54] >> BIAS;
	DENORM_MANTISSA_1 <= NORMALIZED_MANTISSA_1; // rounding 
	DENORM_MANTISSA_0 <= NORMALIZED_MANTISSA;
end

reg CHECK;
always @(posedge CLK)
	CHECK <= (-SUM > 0);
//---------------------------------------------------------------//

//----------------------Pipelined Addition----------------------//
reg [51:0] NORM_OP1;
wire [51:0] DENORM_OP1;
reg NORM_OP2;
wire DENORM_OP2;
wire [51:0] NORMAL_MANTISSA, DENORM_MANTISSA;

wire [8:0] INDEX1, INDEX2;
RCA_9x2 RCA_9x2_1(.CLK( CLK ), .A( SHIFT ), .B( 9'd52 ), .Cin( 1'b0 ), .S( INDEX1 ), .Cout());
RCA_9x2 RCA_9x2_2(.CLK( CLK ), .A( SHIFT ), .B( 9'd51 ), .Cin( 1'b0 ), .S( INDEX2 ), .Cout());

reg [51:0] NORM_SHIFT_1;
always @(posedge CLK) begin
	NORM_SHIFT_1 <= PRODUCT >> INDEX1;
	NORM_OP1 <= NORM_SHIFT_1[51:0];
	NORM_OP2 <= PRODUCT[INDEX2];
end

assign DENORM_OP1 = PRODUCT[104:53];
assign DENORM_OP2 = PRODUCT[52];

RCA_52x1 RCA_52x1_1(.CLK( CLK ), .A( NORM_OP1 ), .Cin( NORM_OP2 ), .S( NORMAL_MANTISSA ), .Cout());
RCA_52x1 RCA_52x1_2(.CLK( CLK ), .A( DENORM_OP1 ), .Cin( DENORM_OP2 ), .S( DENORM_MANTISSA ), .Cout());

wire [12:0] RENORMALIZED_EXPONENT;

RCA_13x2 RCA_13x2(.CLK( CLK ), .A( NORMALIZED_EXPONENT ), .B( triggerA ),.Cin( triggerB ), .S( RENORMALIZED_EXPONENT ), .Cout());

wire [10:0] INDEX3;

RCA_11x2 RCA_11x2(.CLK( CLK ), .A( BIAS ), .B( 11'd53 ), .Cin( 1'b0 ), .S( INDEX3 ), .Cout());

//-----------------------------Output----------------------------//
always @(posedge CLK) begin
	if(OVERFLOW) begin // Overflow (Infinity)
		TEMP_EXPONENT <= 11'd2047;
		TEMP_MANTISSA <= 52'b0;
	end

	else if(UNDERFLOW) begin // Underflow (Denorm)
		TEMP_EXPONENT <= 11'b0;                                                   
		if(CHECK) begin
			if((INDEX3 >= 0) &&
			   (INDEX3 <= 105) && // avoid PRODUCT[-1] etc.
				PRODUCT[INDEX3])
				TEMP_MANTISSA <= DENORM_MANTISSA_1;
			else
				TEMP_MANTISSA <= DENORM_MANTISSA_0;
		end
		else
			TEMP_MANTISSA <= DENORM_MANTISSA;
	end
	
	else begin // Normal
		TEMP_EXPONENT <= RENORMALIZED_EXPONENT;
		TEMP_MANTISSA <= NORMAL_MANTISSA;
	end		
end
//---------------------------------------------------------------//
endmodule

// 3 x 3-bit Ripple-Carry Adder
module FFA(CLK, A, B, C, Cin, S, Cout);

	input CLK;
	input [2:0] A, B, C;
	input [1:0] Cin;
	output reg [2:0] S;
	output reg [1:0] Cout;

	always @(posedge CLK) begin
		{Cout, S} <= A + B + C + Cin;
	end
endmodule

// 3 x 11-bit Ripple-Carry Adder
module RCA_11x3(CLK, A, B, C, Cin, S, Cout);

	input CLK;
	input [10:0] A, B, C;
	input Cin;
	output [12:0] S;
	output Cout;

	wire [10:0] TEMP_C;
	genvar i;

	generate
	FFA U1(.CLK( CLK ), .A( A[2:0] ), .B( B[2:0] ),  .C( C[2:0] ), .Cin( {1'b0, Cin} ), .S( S[2:0] ), .Cout( TEMP_C[1:0] ));
	for(i = 1; i < 3; i = i + 1)
		FFA U2(.CLK( CLK ), .A( A[(i*3)+2:i*3] ), .B( B[(i*3)+2:i*3] ), .C( C[(i*3)+2:i*3] ), .Cin( TEMP_C[((i-1)*2)+1:(i-1)*2] ),
							.S( S[(i*3)+2:i*3] ), .Cout( TEMP_C[(i*2)+1:i*2] ));
	FFA U3(.CLK( CLK ), .A( {1'b0, A[10:9]} ), .B( {1'b0, B[10:9]} ), .C( {1'b1, C[10:9]} ), .Cin( TEMP_C[5:4] ), // Sign Extension (-1023)
						.S( S[11:9] ), .Cout(TEMP_C[7:6] ));
	FFA U4(.CLK( CLK ), .A( 3'b000 ), .B( 3'b000 ), .C( 3'b111 ), .Cin( TEMP_C[7:6] ), // Sign Extension (-1023)
						.S( {TEMP_C[10], Cout, S[12]} ), .Cout( TEMP_C[9:8] ));
	endgenerate
endmodule

// 2 x 11-bit Ripple-Carry Adder
module RCA_11x2(CLK, A, B, Cin, S, Cout);

	input CLK;
	input [10:0] A, B;
	input Cin;
	output [10:0] S;
	output Cout;

	wire [2:0] TEMP_C;
	genvar i;

	generate
	FA U1(.CLK( CLK ), .A( A[2:0] ), .B( B[2:0] ), .Cin( Cin ), .S( S[2:0] ), .Cout( TEMP_C[0] ));
	for(i = 1; i < 3; i = i + 1)
		FA U2(.CLK( CLK ), .A( A[(i*3)+2:i*3] ), .B( B[(i*3)+2:i*3] ), .Cin( TEMP_C[i-1] ),
							.S( S[(i*3)+2:i*3] ), .Cout( TEMP_C[i] ));
	FA U3(.CLK( CLK ), .A( {2'b0, A[10:9]} ), .B( {2'b0, B[10:9]} ), .Cin( TEMP_C[2] ),
						.S( {S[10:9]} ), .Cout( Cout ));
	endgenerate
endmodule

// 2 x 13-bit Ripple-Carry Adder
module RCA_13x2(CLK, A, B, Cin, S, Cout);

	input CLK;
	input [12:0] A, B;
	input Cin;
	output [12:0] S;
	output Cout;

	wire [10:0] TEMP_C;
	genvar i;

	generate
	FA U1(.CLK( CLK ), .A( A[2:0] ), .B( B[2:0] ), .Cin( Cin ), .S( S[2:0] ), .Cout( TEMP_C[0] ));
	for(i = 1; i < 4; i = i + 1)
		FA U2(.CLK( CLK ), .A( A[(i*3)+2:i*3] ), .B( B[(i*3)+2:i*3] ), .Cin( TEMP_C[i-1] ),
							.S( S[(i*3)+2:i*3] ), .Cout( TEMP_C[i] ));
	FA U3(.CLK( CLK ), .A( {2'b0, A[12]} ), .B( {2'b0, B[12]} ), .Cin( TEMP_C[3] ), // Sign Extension (-1023)
						.S( {S[12]} ), .Cout( Cout ));
	endgenerate
endmodule

// 2 x 9-bit Ripple-Carry Adder
module RCA_9x2(CLK, A, B, Cin, S, Cout);

	input CLK;
	input [8:0] A, B;
	input Cin;
	output [8:0] S;
	output Cout;

	wire [2:0] TEMP_C;
	genvar i;

	generate
	FA U1(.CLK( CLK ), .A( A[2:0] ), .B( B[2:0] ), .Cin( Cin ), .S( S[2:0] ), .Cout( TEMP_C[0] ));
	for(i = 1; i < 3; i = i + 1)
		FA U2(.CLK( CLK ), .A( A[(i*3)+2:i*3] ), .B( B[(i*3)+2:i*3] ), .Cin( TEMP_C[i-1] ),
							.S( S[(i*3)+2:i*3] ), .Cout( TEMP_C[i] ));
	endgenerate
endmodule

// 1 x 3-bit Ripple-Carry Adder
module HA(CLK, A, Cin, S, Cout);

	input CLK;
	input [2:0] A;
	input Cin;
	output reg [2:0] S;
	output reg Cout;

	always @(posedge CLK) begin
		{Cout, S} <= A + Cin;
	end
endmodule

// 1 x 52-bit Ripple-Carry Adder
module RCA_52x1(CLK, A, Cin, S, Cout);

	input CLK;
	input [51:0] A;
	input Cin;
	output [51:0] S;
	output Cout;

	wire [17:0] TEMP_C;
	genvar i;

	generate
	HA U1(.CLK( CLK ), .A( A[2:0] ), .Cin( Cin ), .S( S[2:0] ), .Cout( TEMP_C[0] ));
	for(i = 1; i < 17; i = i + 1)
		HA U2(.CLK( CLK ), .A( A[(i*3)+2:i*3] ), .Cin( TEMP_C[i-1] ), .S( S[(i*3)+2:i*3] ), .Cout( TEMP_C[i] ));
	HA U3(.CLK( CLK ), .A( {2'b0, A[51]} ), .Cin( TEMP_C[16] ), .S( {S[51]} ), .Cout( TEMP_C[17] ));
	endgenerate
endmodule
