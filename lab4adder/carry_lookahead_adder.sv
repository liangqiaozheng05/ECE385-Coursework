module carry_lookahead_adder
(
    input   logic[15:0]     A,
    input   logic[15:0]     B,
    output  logic[15:0]     Sum,
    output  logic           CO
);

    /* TODO
     *
     * Insert code here to implement a CLA adder.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */

    logic PG0, PG1, PG2, PG3;
    logic GG0, GG1, GG2, GG3;
    logic C4, C8, C12;

    four_bit_CLA CLA0 (
        .A   (A[3:0]),
        .B   (B[3:0]),
        .Cin (0),
        .Sum (Sum[3:0]),
        .PG  (PG0),
        .GG  (GG0)
    );

    four_bit_CLA CLA1 (
        .A   (A[7:4]),
        .B   (B[7:4]),
        .Cin (C4),
        .Sum (Sum[7:4]),
        .PG  (PG1),
        .GG  (GG1)
    );

    four_bit_CLA CLA2 (
        .A   (A[11:8]),
        .B   (B[11:8]),
        .Cin (C8),
        .Sum (Sum[11:8]),
        .PG  (PG2),
        .GG  (GG2)
    );

    four_bit_CLA CLA3 (
        .A   (A[15:12]),
        .B   (B[15:12]),
        .Cin (C12),
        .Sum (Sum[15:12]),
        .PG  (PG3),
        .GG  (GG3)
    );

	 // same as below
	 assign C4  = GG0 | (PG0 & 0);
    assign C8  = GG1 | (PG1 & GG0) | (PG1 & PG0 & 0);
    assign C12 = GG2 | (PG2 & GG1) | (PG2 & PG1 & GG0) | (PG2 & PG1 & PG0 & 0);
    assign CO  = GG3 | (PG3 & GG2) | (PG3 & PG2 & GG1) | (PG3 & PG2 & PG1 & GG0)
                     | (PG3 & PG2 & PG1 & PG0 & 0);

endmodule


// need 4 cla to get their own group P and G
module four_bit_CLA
(
    input   logic[3:0] A,
    input   logic[3:0] B,
    input   logic      Cin,
    output  logic[3:0] Sum,
    output  logic      PG,
    output  logic      GG
);

    logic[3:0] P, G;
    logic C1, C2, C3;//, C4;

    assign P = A ^ B;
    assign G = A & B;

    // C1 = Cin * P0 + G0
	 // G[0] | (P[0] & Cin)
	 // C2 = C1 * P1 + G1
	 //    = Cin * P0 * P1 + G0 * P1 + G1
	 // G[1] | (P[1] & G[0]) | (P[1] & P[0] & Cin)
	 // G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & Cin)
	 // G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & Cin)
    assign C1 = G[0] | (P[0] & Cin);
    assign C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & Cin);
    assign C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & Cin);
    //assign C4 = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0])
    //                  | (P[3] & P[2] & P[1] & P[0] & Cin);

    assign Sum[0] = P[0] ^ Cin;
    assign Sum[1] = P[1] ^ C1;
    assign Sum[2] = P[2] ^ C2;
    assign Sum[3] = P[3] ^ C3;

    // PG and GG
    assign PG = P[0] & P[1] & P[2] & P[3];
    assign GG = G[3]
              | (P[3] & G[2])
              | (P[3] & P[2] & G[1])
              | (P[3] & P[2] & P[1] & G[0]);

endmodule

