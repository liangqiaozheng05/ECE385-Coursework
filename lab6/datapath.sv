// datapath.sv
// use MUX to select the input
// instantiate the register
// drive BUS

module datapath(
    input logic Clk, Reset,
    input logic LD_MAR, LD_MDR, LD_IR, LD_PC, // Load signals from ISDU
    input logic GatePC, GateMDR, GateALU, GateMARMUX, // Gate signals from ISDU
    // MUX select signals
    input logic[1:0] PCMUX,
    input logic MIO_EN,
    // in and out
    input logic[15:0] MDR_In, // which is the Data_to_CPU from the detailed diagram
    output logic[15:0] MAR, MDR, IR, PC // for other modules to use
);

logic[15:0] BUS; // internal bus


// PC+1
logic[15:0] PC_plus_1;
assign PC_plus_1 = PC + 16'h0001;

// data from bus to PC and MDR, note that they will pass some MUX
logic[15:0] PC_data_In;
logic[15:0] MDR_data_In;

always_comb begin : choose_MDR
    if (MIO_EN) 
        MDR_data_In = MDR_In; // read from SRAM to MDR
    else 
        MDR_data_In = BUS; // from BUS to MDR
end
always_comb begin : choose_PC
    unique case (PCMUX)
        2'b00: PC_data_In = PC_plus_1; // PC + 1
        2'b01: PC_data_In = BUS; // from BUS
        2'b10: PC_data_In = 16'h0000; // TODO week2
        default: PC_data_In = 16'h0000; 
    endcase
end

// Instatiate registers
reg_16 PC_reg(
    .Clk(Clk), .Reset(Reset), .Load(LD_PC), 
    .D(PC_data_In), .Q(PC)
);
reg_16 MAR_reg(
    .Clk(Clk), .Reset(Reset), .Load(LD_MAR), 
    .D(BUS), .Q(MAR)
);
reg_16 MDR_reg(
    .Clk(Clk), .Reset(Reset), .Load(LD_MDR), 
    .D(MDR_data_In), .Q(MDR)
);
reg_16 IR_reg(
    .Clk(Clk), .Reset(Reset), .Load(LD_IR), 
    .D(BUS), .Q(IR)
);


// 4-to-1 MUX for the bus
// BUS can be PC, MDR, ALU val, MARMUX output.
always_comb begin : Gate_MUX
    if(GatePC) 
        BUS = PC;
    else if (GateMDR) 
        BUS = MDR;
    else if (GateALU) 
        BUS = 16'h0000; // TODO week2 ALU
    else if (GateMARMUX) 
        BUS = 16'h0000; // TODO week2 MARMUX output
    else 
        BUS = 16'h0000; // idle
end

endmodule