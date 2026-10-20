module sprite_ram (
    input  logic        Clk,
    input  logic [14:0] read_address, // 2^15 > 64x416=26624
    output logic [7:0]  data_Out      // color idx output
);

    logic [7:0] mem [0:26623]; 
    
    initial begin
        $readmemh("sprite.txt", mem);
    end
    
    always_ff @ (posedge Clk) begin
        data_Out <= mem[read_address];
    end
    
endmodule