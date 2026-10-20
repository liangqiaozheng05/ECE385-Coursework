// Full adder logic for adder9
module full_adder (
    input        x, y, z,
    output logic s, c
);
    assign s = x ^ y ^ z;
    assign c = (x & y) | (y & z) | (x & z);
endmodule

// 9-bits adder subtractor, the extension logic is included here
module adder9 (
    input[7:0] S,
    input[7:0] A,
    input      fn,  // fn=0 addition, fn=1 subtraction
    output logic[8:0] Sum
);
    logic [8:0] A_ext, S_ext, S_in;
    logic c0, c1, c2, c3, c4, c5, c6, c7, c8;

    // sign extension
    assign A_ext = {A[7], A}; 
    assign S_ext = {S[7], S}; 

    // if addition, let S_in be S_ext
    // if substraction, let S_in be the reverse of S_ext
    assign S_in = fn ? ~S_ext : S_ext;

    // instantiate 9 full adder for computation
    full_adder fa0 (.x(A_ext[0]), .y(S_in[0]), .z(fn), .s(Sum[0]), .c(c0));
    full_adder fa1 (.x(A_ext[1]), .y(S_in[1]), .z(c0), .s(Sum[1]), .c(c1));
    full_adder fa2 (.x(A_ext[2]), .y(S_in[2]), .z(c1), .s(Sum[2]), .c(c2));
    full_adder fa3 (.x(A_ext[3]), .y(S_in[3]), .z(c2), .s(Sum[3]), .c(c3));
    full_adder fa4 (.x(A_ext[4]), .y(S_in[4]), .z(c3), .s(Sum[4]), .c(c4));
    full_adder fa5 (.x(A_ext[5]), .y(S_in[5]), .z(c4), .s(Sum[5]), .c(c5));
    full_adder fa6 (.x(A_ext[6]), .y(S_in[6]), .z(c5), .s(Sum[6]), .c(c6));
    full_adder fa7 (.x(A_ext[7]), .y(S_in[7]), .z(c6), .s(Sum[7]), .c(c7));
    full_adder fa8 (.x(A_ext[8]), .y(S_in[8]), .z(c7), .s(Sum[8]), .c(c8));
endmodule

// HexDriver from lab4
module HexDriver (input  logic[3:0]  In0,
                  output logic [6:0]  Out0);
	
	always_comb
	begin
		unique case (In0)
	 	   4'b0000   : Out0 = 7'b1000000; // '0'
	 	   4'b0001   : Out0 = 7'b1111001; // '1'
		   4'b0010   : Out0 = 7'b0100100; // '2'
	 	   4'b0011   : Out0 = 7'b0110000; // '3'
	 	   4'b0100   : Out0 = 7'b0011001; // '4'
		   4'b0101   : Out0 = 7'b0010010; // '5'
	 	   4'b0110   : Out0 = 7'b0000010; // '6'
	 	   4'b0111   : Out0 = 7'b1111000; // '7'
	 	   4'b1000   : Out0 = 7'b0000000; // '8'
		   4'b1001   : Out0 = 7'b0010000; // '9'
	 	   4'b1010   : Out0 = 7'b0001000; // 'A'
	 	   4'b1011   : Out0 = 7'b0000011; // 'B'
	 	   4'b1100   : Out0 = 7'b1000110; // 'C'
		   4'b1101   : Out0 = 7'b0100001; // 'D'
	 	   4'b1110   : Out0 = 7'b0000110; // 'E'
	 	   4'b1111   : Out0 = 7'b0001110; // 'F'
	 	   default   : Out0 = 7'bXXXXXXX; // undefined output
        endcase
	end

endmodule

// toplevel control logic, including state machine and connection to the testbench
module lab5_toplevel (
    input  logic      Clk,
    input  logic      Reset,
    input  logic      Run,
    input  logic      ClearA_LoadB,
    input  logic[7:0] S,
    
    output logic[7:0] Aval,
    output logic[7:0] Bval,
    output logic      X,
    output logic[6:0] AhexL,
    output logic[6:0] AhexU,
    output logic[6:0] BhexL,
    output logic[6:0] BhexU
);

    logic [7:0] A;
    logic [7:0] B;
    
    // signals to control
    logic Clr_XA, Add, Sub, Shift;
    logic [8:0] Sum9;
    logic M;
    
    assign M = B[0]; // M is the LSB of B

    // instantiate adder9
    adder9 add_sub_unit (
        .A(A),
        .S(S),
        .fn(Sub), // Sub signal will control which operation to execute
        .Sum(Sum9)
    );

    // Register logic
    always_ff @(posedge Clk) begin
        if (~Reset) 
        begin // reset
            A <= 8'b0;
            B <= 8'b0;
            X <= 1'b0;
        end 
        else if (~ClearA_LoadB) // S->B, reset A and X
        begin
            A <= 8'b0;
            X <= 1'b0;
            B <= S;
        end 
        else if (Clr_XA) // Clr_XA signal will reset A X for the consecutive function
        begin
            A <= 8'b0;
            X <= 1'b0;
        end 
        else if (Add || Sub) // put the result into {X,A}
        begin
            {X, A} <= Sum9;
        end 
        else if (Shift) // arthmetically right shift
        begin
            X <= X;
            A <= {X, A[7:1]};
            B <= {A[0], B[7:1]};
        end
    end

    // Since there are 8 loop, must use FSM
    // state defination
    // Reset -> HALT
    // Run -> S_CLR_XA -> send Clr_XA signal to reset X and A
    // A1 -- A7 add states
    // S1 -- S7 shift states
    typedef enum logic[4:0] {
        HALT, S_CLR_XA,
        A1, S1, A2, S2, A3, S3, A4, S4,
        A5, S5, A6, S6, A7, S7, A8, S8,
        DONE
    } state_t;
    
    state_t state, next_state;

    // Reset will take the state into HALT forcibly
    always_ff @(posedge Clk) begin
        if (~Reset)
            state <= HALT;
        else
            state <= next_state;
    end

    // to dicide state shift
    always_comb begin
        next_state = state; // keep
        unique case (state)
            HALT:     if (~Run) next_state = S_CLR_XA;
            S_CLR_XA: next_state = A1;
            A1:       next_state = S1;
            S1:       next_state = A2;
            A2:       next_state = S2;
            S2:       next_state = A3;
            A3:       next_state = S3;
            S3:       next_state = A4;
            A4:       next_state = S4;
            S4:       next_state = A5;
            A5:       next_state = S5;
            S5:       next_state = A6;
            A6:       next_state = S6;
            S6:       next_state = A7;
            A7:       next_state = S7;
            S7:       next_state = A8;
            A8:       next_state = S8;
            S8:       next_state = DONE;
            DONE:     if (Run)  next_state = HALT;
        endcase
    end

    // to control the signals based on states
    always_comb begin
        Clr_XA = (state == S_CLR_XA);
        Add    = (state == A1 || state == A2 || state == A3 || state == A4 || 
                  state == A5 || state == A6 || state == A7) && M; // to add if M = 1
        Sub    = (state == A8) && M; // to sub if M = 1
        Shift  = (state == S1 || state == S2 || state == S3 || state == S4 || 
                  state == S5 || state == S6 || state == S7 || state == S8);
    end

    // assign output
    assign Aval = A;
    assign Bval = B;

    HexDriver A_HexL_Inst (.In0(A[3:0]), .Out0(AhexL));
    HexDriver A_HexU_Inst (.In0(A[7:4]), .Out0(AhexU));
    HexDriver B_HexL_Inst (.In0(B[3:0]), .Out0(BhexL));
    HexDriver B_HexU_Inst (.In0(B[7:4]), .Out0(BhexU));

endmodule