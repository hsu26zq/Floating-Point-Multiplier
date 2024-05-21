//------------------------------------------------------//
//- Final Project					//
//							//
//- Floating Point Number Multiplier			//
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
		  .RESET(RESET),
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
		FETCH:
			if(counter == 6'd15) 
				next_state = CAL;
			else 
				next_state = FETCH;
		CAL: 
			if(counter == 6'd50) 
				next_state = OUT;
			else 
				next_state = CAL;
		OUT:
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
				if(counter == 6'd50)
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
			input RESET,
			input A_SIGN,
			input B_SIGN,
			input signed [10:0] A_EXPONENT,
			input signed [10:0] B_EXPONENT,
			input [51:0] A_MANTISSA,
			input [51:0] B_MANTISSA,

			output reg		  Z_SIGN,
			output reg signed [10:0] Z_EXPONENT,
			output reg [51:0] Z_MANTISSA);

reg [10:0] TEMP_EXPONENT;
reg [51:0] TEMP_MANTISSA;

always @(posedge CLK)
	if(A_EXPONENT == 11'd2047 && A_MANTISSA != 52'b0 || B_EXPONENT == 11'd2047 && B_MANTISSA != 52'b0) begin // A or B NaN THEN Z NaN
		Z_SIGN <= 1'b1;
		Z_EXPONENT <= 11'd2047;
		Z_MANTISSA <= 1'b1;
	end

	else if(A_EXPONENT == 11'd2047 && A_MANTISSA == 52'b0 ) // A Infinity
		if(B_EXPONENT == 11'b0 && B_MANTISSA == 52'b0) begin // B Zero THEN Z NaN, ELSE Z Infinity
			Z_SIGN <= 1'b1;
			Z_EXPONENT <= 11'd2047;
			Z_MANTISSA <= 1'b1;
		end
		else begin
			Z_SIGN <= A_SIGN;
			Z_EXPONENT <= A_EXPONENT;
			Z_MANTISSA <= A_MANTISSA;
		end

	else if(B_EXPONENT == 11'd2047 && B_MANTISSA == 52'b0 ) // B Infinity
		if(A_EXPONENT == 11'b0 && A_MANTISSA == 52'b0) begin // A Zero THEN Z NaN, ELSE Z Infinity
			Z_SIGN <= 1'b1;
			Z_EXPONENT <= 11'd2047;
			Z_MANTISSA <= 1'b1;
		end
		else begin
			Z_SIGN <= B_SIGN;
			Z_EXPONENT <= B_EXPONENT;
			Z_MANTISSA <= B_MANTISSA;
		end

	else if(A_EXPONENT == 11'b0 && A_MANTISSA == 52'b0) begin // A Zero THEN Z Zero
		Z_SIGN <=  A_SIGN;
		Z_EXPONENT <= A_EXPONENT;
		Z_MANTISSA <= A_MANTISSA;
	end

	else if(B_EXPONENT == 11'b0 && B_MANTISSA == 52'b0) begin // B Zero THEN Z Zero
		Z_SIGN <=  B_SIGN;
		Z_EXPONENT <= B_EXPONENT;
		Z_MANTISSA <= B_MANTISSA;
	end

	else begin // Non-Speical Cases 
		Z_SIGN <= ( ((A_SIGN && ~B_SIGN) || (~A_SIGN && B_SIGN)) ? 1'b1 : 1'b0 );
		Z_EXPONENT <= TEMP_EXPONENT;
		Z_MANTISSA <= TEMP_MANTISSA;
	end

//--------------------Mantissas Multiplicaion--------------------//
reg [52:0] OP1, OP2;
wire [105:0] PRODUCT;
TREE TREE(.CLK( CLK ), .X( OP1 ), .Y( OP2 ), .Z( PRODUCT ));

always @(posedge CLK) begin
	if(A_EXPONENT == 11'b0 && A_MANTISSA != 52'b0) // A Denorm THEN Implicit Zero, ELSE One
		OP1 <= {1'b0, A_MANTISSA};
	else
		OP1 <= {1'b1, A_MANTISSA};

	if(B_EXPONENT == 11'b0 && B_MANTISSA != 52'b0) // B Denorm THEN Implicit Zero, ELSE One
		OP2 <= {1'b0, B_MANTISSA};
	else
		OP2 <= {1'b1, B_MANTISSA};
end
//---------------------------------------------------------------//

//---------------------Find LeftMost Set Bit---------------------//
reg [105:0] REV, MSB, HOT;
reg [7:0] LOC;
reg signed [8:0] SHIFT;
integer i, j;

always @(posedge CLK) begin // Find Leftmost Set Bit of "PRODUCT"
	for(i = 0; i < 106; i = i + 1)
		REV[i] <= PRODUCT[105 - i];
	MSB <= REV & (~REV + 1);
	for(i = 0; i < 106; i = i + 1)
		HOT[i] <= MSB[105 - i];
	for(i = 0; i < 106; i = i + 1)
		if(HOT[i])
			LOC <= i;
	SHIFT <= LOC - 104; // Difference Between First Set Bit and Decimal Point	
end
//---------------------------------------------------------------//

reg [10:0] SHIFTER;
reg [10:0] SHIFTING;
always @(posedge CLK) begin
	SHIFTER <= ~(A_EXPONENT + B_EXPONENT - 1023 + LOC - 104) + 1;
	SHIFTING <= (SHIFTER -1 + LOC -104);
end

reg triggerA, triggerB;
always @(*) begin
	triggerA = !A_EXPONENT;	
	triggerB = !B_EXPONENT;
end


reg [51:0] DENORM_MANTISSA_1, DENORM_MANTISSA_0, SHIFTED;
always @(posedge CLK) begin
	SHIFTED  <= (PRODUCT[105:54] >> (SHIFTING - triggerA - triggerB));
	DENORM_MANTISSA_1 <= SHIFTED + 1;
	DENORM_MANTISSA_0 <= SHIFTED;
end

reg OVERFLOW, UNDERFLOW, CHECK;
always @(posedge CLK) begin
	OVERFLOW <= ($signed(A_EXPONENT + B_EXPONENT - 1023 + LOC - 104) > 2046);
	UNDERFLOW <= ($signed(A_EXPONENT + B_EXPONENT - 1023 + LOC - 104) < 1);
	CHECK <= ($signed(SHIFTER - 1 + LOC -104) >= 0);
end

//-------------------------Normalization-------------------------//
always @(posedge CLK) begin
	if(OVERFLOW) begin // Overflow (Infinity)
		TEMP_EXPONENT <= 11'd2047;
		TEMP_MANTISSA <= 52'b0;
	end

	else if(UNDERFLOW) begin // Underflow (Denorm)
		TEMP_EXPONENT <= 11'b0;                                                   
		if(CHECK) begin
			if((54 + SHIFTING - triggerA - triggerB - 1 >= 0) &&
			   (54 + SHIFTING - triggerA - triggerB - 1 <= 105) && 
				PRODUCT[54 + SHIFTING - triggerA - triggerB - 1])
				TEMP_MANTISSA <= DENORM_MANTISSA_1;
			else
				TEMP_MANTISSA <= DENORM_MANTISSA_0;
		end
		else
			TEMP_MANTISSA <= PRODUCT[104:53] + PRODUCT[52];
	end
	
	else begin // Normal
		TEMP_EXPONENT <= A_EXPONENT + B_EXPONENT - 1023 + LOC - 104 + triggerA + triggerB;
		TEMP_MANTISSA <= PRODUCT[52 + (LOC - 104) +: 52] + PRODUCT[52 + (LOC - 104) - 1];
	end		
end
//---------------------------------------------------------------//
endmodule

// Pipelined 4-bit Ripple Adder
module HA_4(CLK, A, Cin, S, Cout);

	input CLK;
	input [3:0] A;
	input Cin;
	output reg [3:0] S;
	output reg Cout;

	always @(posedge CLK) begin
		{Cout, S} <= A + Cin;
	end
endmodule

module CPA_52(CLK, A, Cin, S, Cout);
	
	input CLK;
	input [51:0] A;
	input Cin;
	output reg [51:0] S;
	output reg Cout;

	wire [51:0] S_WIRE;
	wire [52:0] C_WIRE;

	genvar i;	
	generate
	for(i = 0; i < 13; i = i + 1)
		HA_4 U1(.CLK( CLK ), .A( A[i*4+:4] ), .Cin( C_WIRE[i] ), .S( S_WIRE[i*4+:4] ), .Cout( C_WIRE[i+1] ));
	endgenerate

	always @(posedge CLK) begin
		S <= S_WIRE;
		Cout <= C_WIRE[52];
	end
endmodule
