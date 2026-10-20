// 16 bit register for PC, MAR, MDR, IR
// with load enable

module reg_16(
    input logic Clk, Reset, Load,
    input logic [15:0] D,
    output logic [15:0] Q
);

always_ff @(posedge Clk)
begin
    if (Reset) 
        Q <= 16'h0000;
    else if (Load)
        Q <= D;
end
endmodule