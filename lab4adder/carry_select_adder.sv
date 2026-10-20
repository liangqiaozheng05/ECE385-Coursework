module carry_select_adder
(
    input   logic[15:0]     A,
    input   logic[15:0]     B,
    output  logic[15:0]     Sum,
    output  logic           CO
);

    /* TODO
     *
     * Insert code here to implement a carry select.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */
	  
	 // decide which output to choose
    logic c4, c8, c12;
	 

    // one ra for group 1
    four_bit_ripple_adder CSA0(
        .x   (A[3:0]),
        .y   (B[3:0]),
        .cin (0),
        .s   (Sum[3:0]),
        .cout(c4)
    );

    // group2
    logic[3:0] sum4_0, sum4_1;
    logic      c8_0, c8_1;

    four_bit_ripple_adder CSA1_0(
        .x   (A[7:4]),
        .y   (B[7:4]),
        .cin (0),
        .s   (sum4_0),
        .cout(c8_0)
    );

    four_bit_ripple_adder CSA1_1(
        .x   (A[7:4]),
        .y   (B[7:4]),
        .cin (1),
        .s   (sum4_1),
        .cout(c8_1)
    );
    // choose output
    assign Sum[7:4] = (c4 == 0) ? sum4_0 : sum4_1;
    assign c8       = (c4 == 0) ? c8_0   : c8_1;

    // group3
    logic[3:0] sum8_0, sum8_1;
    logic      c12_0, c12_1;

    four_bit_ripple_adder CSA2_0(
        .x   (A[11:8]),
        .y   (B[11:8]),
        .cin (0),
        .s   (sum8_0),
        .cout(c12_0)
    );

    four_bit_ripple_adder CSA2_1(
        .x   (A[11:8]),
        .y   (B[11:8]),
        .cin (1),
        .s   (sum8_1),
        .cout(c12_1)
    );

	 // choose output
    assign Sum[11:8] = (c8 == 0) ? sum8_0 : sum8_1;
    assign c12       = (c8 == 0) ? c12_0  : c12_1;

    // group4
    logic[3:0] sum12_0, sum12_1;
    logic      c16_0, c16_1;

    four_bit_ripple_adder CSA3_0(
        .x   (A[15:12]),
        .y   (B[15:12]),
        .cin (0),
        .s   (sum12_0),
        .cout(c16_0)
    );

    four_bit_ripple_adder CSA3_1(
        .x   (A[15:12]),
        .y   (B[15:12]),
        .cin (1),
        .s   (sum12_1),
        .cout(c16_1)
    );

	 // choose output
    assign Sum[15:12] = (c12 == 0) ? sum12_0 : sum12_1;
    assign CO         = (c12 == 0) ? c16_0   : c16_1;

endmodule
