/************************************************************************
Avalon-MM Interface VGA Text mode display

Modified for DE2-115 board

Register Map:
0x000-0x0257 : VRAM, 80x30 (2400 byte, 600 word) raster order (first column then row)
0x258        : control register

VRAM Format:
X->
[ 31  30-24][ 23  22-16][ 15  14-8 ][ 7    6-0 ]
[IV3][CODE3][IV2][CODE2][IV1][CODE1][IV0][CODE0]

IVn = Draw inverse glyph
CODEn = Glyph code from IBM codepage 437

Control Register Format:
[[31-25][24-21][20-17][16-13][ 12-9][ 8-5 ][ 4-1 ][   0    ] 
[[RSVD ][FGD_R][FGD_G][FGD_B][BKG_R][BKG_G][BKG_B][RESERVED]

VSYNC signal = bit which flips on every Vsync (time for new frame), used to synchronize software
BKG_R/G/B = Background color, flipped with foreground when IVn bit is set
FGD_R/G/B = Foreground color, flipped with background when Inv bit is set

************************************************************************/
// `define NUM_REGS 601 //80*30 characters / 4 characters per register
// `define CTRL_REG 600 //index of control register

module vga_text_avl_interface (
	// Avalon Clock Input, note this clock is also used for VGA, so this must be 50Mhz
	// We can put a clock divider here in the future to make this IP more generalizable
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,					// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,			// Avalon-MM Byte Enable
	input  logic [11:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,		// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,		// Avalon-MM Read Data
	
	// Exported Conduit (mapped to VGA port - make sure you export in Platform Designer)
	output logic [3:0]  red, green, blue,	// VGA color channels (mapped to output pins in top-level)
	output logic hs, vs,					// VGA HS/VS
	output logic sync, blank, pixel_clk		// Required by DE2-115 video encoder
);

//logic [31:0] LOCAL_REG       [`NUM_REGS]; // Registers
//put other local variables here

// logic [31:0] ctrl_reg; // 0x258 control register
logic [31:0] palette_reg [8];

// ram lining signals
logic ram_we;
logic [31:0] ram_q_a;

assign ram_we = (AVL_CS && AVL_WRITE && ~AVL_ADDR[11]); // vram can be writen when bit 11 is 0
vram vram_inst (
    .clock     (CLK),
    // Port A: Avalon bus for NIOS
    .address_a (AVL_ADDR[10:0]),
    .data_a    (AVL_WRITEDATA),
    .wren_a    (ram_we),
    .byteena_a (AVL_BYTE_EN),
    .q_a       (ram_q_a),
    
    .address_b (vram_addr_b),
    .q_b       (vram_data_b),
    .data_b    (32'b0),
    .wren_b    (1'b0)
);

always_ff @(posedge CLK) begin
    if (RESET) begin
        for (int i = 0; i < 8; i++) begin
            palette_reg[i] <= 32'b0;
        end
    end else if (AVL_CS && AVL_WRITE && AVL_ADDR[11]) begin
        // when bit 11 is 1, address >= 0x800, write into the pallate
        if (AVL_BYTE_EN[3]) palette_reg[AVL_ADDR[2:0]][31:24] <= AVL_WRITEDATA[31:24];
        if (AVL_BYTE_EN[2]) palette_reg[AVL_ADDR[2:0]][23:16] <= AVL_WRITEDATA[23:16];
        if (AVL_BYTE_EN[1]) palette_reg[AVL_ADDR[2:0]][15:8]  <= AVL_WRITEDATA[15:8];
        if (AVL_BYTE_EN[0]) palette_reg[AVL_ADDR[2:0]][7:0]   <= AVL_WRITEDATA[7:0];
    end
end

logic blank_int;

//Declare submodules..e.g. VGA controller, ROMS, etc

logic [9:0] DrawX, DrawY;
logic [31:0] vram_data_b;
logic [10:0] vram_addr_b;
logic [10:0] font_addr;
logic [7:0] font_data;

// === week 2 pallate
logic [15:0] char_data;
logic [6:0] code;
logic invert;
logic [3:0] fgd_idx;
logic [3:0] bkg_idx;
logic pixel_on;
// final color
logic [3:0] fgd_r, fgd_g, fgd_b;
logic [3:0] bkg_r, bkg_g, bkg_b;
// ===

// assign pixel_clk = CLK;
assign sync = 1'b0;

vga_controller vga_ctrl (
    .Clk(CLK),
    .Reset(RESET),
    .hs(hs),
    .vs(vs),
    .pixel_clk(pixel_clk),
    .blank(blank_int),
    .sync(),
    .DrawX(DrawX),
    .DrawY(DrawY)
);

assign blank = blank_int;
assign vram_addr_b = (DrawY[9:4] * 11'd40) + DrawX[9:4];

// 16 bit data from 32
always_comb begin
    if (DrawX[3] == 1'b0)
        char_data = vram_data_b[15:0];
    else
        char_data = vram_data_b[31:16];
end

assign code    = char_data[14:8];
assign invert  = char_data[15];
assign fgd_idx = char_data[7:4];
assign bkg_idx = char_data[3:0];


// get font and its addr(ROM look up)
// 16 rows per character
assign font_addr = (code << 4) + DrawY[3:0]; 
font_rom font_unit (
    .addr(font_addr),
    .data(font_data)
);
// is pixel lighted up
assign pixel_on = font_data[3'd7 - DrawX[2:0]];

// === output color , for week 2
// get color
always_comb begin
    // fg RGB
    if (fgd_idx[0] == 1'b1) begin
        fgd_r = palette_reg[fgd_idx[3:1]][24:21];
        fgd_g = palette_reg[fgd_idx[3:1]][20:17];
        fgd_b = palette_reg[fgd_idx[3:1]][16:13];
    end else begin
        fgd_r = palette_reg[fgd_idx[3:1]][12:9];
        fgd_g = palette_reg[fgd_idx[3:1]][8:5];
        fgd_b = palette_reg[fgd_idx[3:1]][4:1];
    end

    // bg RGB
    if (bkg_idx[0] == 1'b1) begin
        bkg_r = palette_reg[bkg_idx[3:1]][24:21];
        bkg_g = palette_reg[bkg_idx[3:1]][20:17];
        bkg_b = palette_reg[bkg_idx[3:1]][16:13];
    end else begin
        bkg_r = palette_reg[bkg_idx[3:1]][12:9];
        bkg_g = palette_reg[bkg_idx[3:1]][8:5];
        bkg_b = palette_reg[bkg_idx[3:1]][4:1];
    end
end
// output color
always_ff @(posedge CLK) begin
    if (~blank_int) begin 
        red   <= 4'h0;
        green <= 4'h0;
        blue  <= 4'h0;
    end else begin
        if (pixel_on ^ invert) begin
            red   <= fgd_r;
            green <= fgd_g;
            blue  <= fgd_b;
        end else begin
            red   <= bkg_r;
            green <= bkg_g;
            blue  <= bkg_b;
        end
    end
end
// ===

// Read and write from AVL interface to register block, add choice for week2
logic [11:0] read_addr_delayed; 

always_ff @(posedge CLK) begin
    if (RESET) begin
        read_addr_delayed <= 12'b0;
    end else if (AVL_CS && AVL_READ) begin
        read_addr_delayed <= AVL_ADDR;
    end
end

always_comb begin
    if (read_addr_delayed[11]) begin
        // adress >= 0x800, get palette data
        AVL_READDATA = palette_reg[read_addr_delayed[2:0]];
    end else begin
        // vram data
        AVL_READDATA = ram_q_a;
    end
end

endmodule
