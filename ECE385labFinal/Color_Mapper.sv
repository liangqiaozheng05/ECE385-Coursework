// render
module  color_mapper ( 
    input  logic        Clk,            
    input  logic        is_note,        
    input  logic [1:0]  note_track_idx, 
    input  logic [9:0]  DrawX, DrawY,
    input  logic [31:0] Score_PIO,
    output logic [7:0]  VGA_R, VGA_G, VGA_B
);
    
    // updated way to use data
    logic [3:0] feedback_type; 
    logic [3:0] score_100, score_10, score_1;
    logic [3:0] combo_10, combo_1;
    logic       score_anim_100, score_anim_10, score_anim_1;

    logic       is_game_over;
    assign is_game_over       = Score_PIO[31];
    
    assign feedback_type      = Score_PIO[27:24]; // 1:A, 2:B, 3:X, 0:Nothing
    assign score_100          = Score_PIO[23:20];
    assign score_10           = Score_PIO[19:16];
    assign score_1            = Score_PIO[15:12];
    assign combo_10           = Score_PIO[11:8];
    assign combo_1            = Score_PIO[7:4];

    assign score_anim_100 = Score_PIO[2]; 
    assign score_anim_10  = Score_PIO[1];
    assign score_anim_1   = Score_PIO[0];

    // ========== vignette ===========
    logic [9:0] dist_x, dist_y, edge_dist;
    
    assign dist_x = (DrawX < 10'd320) ? DrawX : (10'd639 - DrawX);
    assign dist_y = (DrawY < 10'd240) ? DrawY : (10'd479 - DrawY);
    
    assign edge_dist = (dist_x < dist_y) ? dist_x : dist_y;

    logic       is_vignette;
    logic [7:0] vig_R, vig_G, vig_B;

    always_comb begin
        is_vignette = 1'b0;
        vig_R = 8'h00; vig_G = 8'h00; vig_B = 8'h00;

        if (!is_game_over && (feedback_type == 4'd1 || feedback_type == 4'd2)) begin
            if (edge_dist < 10'd24) begin
                is_vignette = 1'b1;
                
                if (feedback_type == 4'd1) begin 
                    vig_R = 8'h00; vig_B = 8'h00;
                    if      (edge_dist < 10'd8)  vig_G = 8'hCC;
                    else if (edge_dist < 10'd16) vig_G = 8'h88;
                    else                         vig_G = 8'h44;
                end
                else begin 
                    vig_B = 8'h00;
                    if      (edge_dist < 10'd8)  begin vig_R = 8'hFF; vig_G = 8'h88; end
                    else if (edge_dist < 10'd16) begin vig_R = 8'hCC; vig_G = 8'h66; end
                    else                         begin vig_R = 8'h88; vig_G = 8'h44; end
                end
            end
        end
    end
    // ===================================

    // instantiate sprite ram
    logic [14:0] rom_addr;
    logic [7:0]  rom_data;
    
    sprite_ram ui_sprite_rom (
        .Clk(Clk),
        .read_address(rom_addr),
        .data_Out(rom_data)
    );

    // ui area division
    // bottom_left
    logic is_ui_feedback, is_ui_combo_10, is_ui_combo_1;
    assign is_ui_feedback = (DrawX >= 20 && DrawX < 52 && DrawY >= 400 && DrawY < 432);
    assign is_ui_combo_10 = (DrawX >= 60 && DrawX < 92 && DrawY >= 400 && DrawY < 432);
    assign is_ui_combo_1  = (DrawX >= 92 && DrawX < 124 && DrawY >= 400 && DrawY < 432);

    // top_right for score
    logic [9:0] s100_x, s100_y, s10_x, s10_y, s1_x, s1_y;
    assign s100_x = is_game_over ? 10'd272 : 10'd500;
    assign s100_y = is_game_over ? 10'd200 : 10'd40;
    assign s10_x  = is_game_over ? 10'd304 : 10'd532;
    assign s10_y  = is_game_over ? 10'd200 : 10'd40;
    assign s1_x   = is_game_over ? 10'd336 : 10'd564;
    assign s1_y   = is_game_over ? 10'd200 : 10'd40;

    logic is_ui_score_100, is_ui_score_10, is_ui_score_1;
    assign is_ui_score_100 = (DrawX >= s100_x && DrawX < s100_x + 32 && DrawY >= s100_y && DrawY < s100_y + 32);
    assign is_ui_score_10  = (DrawX >= s10_x  && DrawX < s10_x  + 32 && DrawY >= s10_y  && DrawY < s10_y  + 32);
    assign is_ui_score_1   = (DrawX >= s1_x   && DrawX < s1_x   + 32 && DrawY >= s1_y   && DrawY < s1_y   + 32);

    logic [5:0] x_off_100, x_off_10, x_off_1;
    assign x_off_100 = score_anim_100 ? 6'd32 : 6'd0;
    assign x_off_10  = score_anim_10  ? 6'd32 : 6'd0;
    assign x_off_1   = score_anim_1   ? 6'd32 : 6'd0;

    always_comb begin
        rom_addr = 15'd0;
        
        // ------ bottom left -------
        if (is_ui_feedback && feedback_type != 4'd0) begin
            logic [8:0] base_y;
            if      (feedback_type == 4'd1) base_y = 9'd320; 
            else if (feedback_type == 4'd2) base_y = 9'd352; 
            else                            base_y = 9'd384; 
            rom_addr = ((DrawY - 10'd400) + base_y) * 7'd64 + (DrawX - 10'd20);
        end
        else if (is_ui_combo_10) begin
            rom_addr = ((DrawY - 10'd400) + combo_10 * 9'd32) * 7'd64 + (DrawX - 10'd60);
        end
        else if (is_ui_combo_1) begin
            rom_addr = ((DrawY - 10'd400) + combo_1 * 9'd32) * 7'd64 + (DrawX - 10'd92);
        end
        

        else if (is_ui_score_100) begin
            rom_addr = ((DrawY - s100_y) + score_100 * 9'd32) * 7'd64 + ((DrawX - s100_x) + x_off_100);
        end
        else if (is_ui_score_10) begin
            rom_addr = ((DrawY - s10_y) + score_10 * 9'd32) * 7'd64 + ((DrawX - s10_x) + x_off_10);
        end
        else if (is_ui_score_1) begin
            rom_addr = ((DrawY - s1_y) + score_1 * 9'd32) * 7'd64 + ((DrawX - s1_x) + x_off_1);
        end
    end

    // pallate
    logic [7:0] pal_R, pal_G, pal_B;
    always_comb begin
        case(rom_data)
            8'h00: begin pal_R = 8'hFF; pal_G = 8'h00; pal_B = 8'hFF; end // -> 0xFF00FF 透明
            8'h01: begin pal_R = 8'hFF; pal_G = 8'hE7; pal_B = 8'h77; end
            8'h02: begin pal_R = 8'hF5; pal_G = 8'hFF; pal_B = 8'hA3; end
            8'h03: begin pal_R = 8'hE4; pal_G = 8'h3B; pal_B = 8'h00; end
            8'h04: begin pal_R = 8'hFF; pal_G = 8'h9E; pal_B = 8'h47; end
            8'h05: begin pal_R = 8'hBF; pal_G = 8'h19; pal_B = 8'h29; end
            8'h06: begin pal_R = 8'hA1; pal_G = 8'hB3; pal_B = 8'hC6; end
            8'h07: begin pal_R = 8'h99; pal_G = 8'h5C; pal_B = 8'hFF; end 
            8'h08: begin pal_R = 8'h85; pal_G = 8'h1B; pal_B = 8'h13; end
            8'h09: begin pal_R = 8'h6E; pal_G = 8'h79; pal_B = 8'hA6; end
            8'h0A: begin pal_R = 8'h65; pal_G = 8'hA5; pal_B = 8'h20; end
            8'h0B: begin pal_R = 8'h5A; pal_G = 8'h23; pal_B = 8'h14; end
            8'h0C: begin pal_R = 8'h3F; pal_G = 8'h3B; pal_B = 8'h93; end
            8'h0D: begin pal_R = 8'h13; pal_G = 8'h85; pal_B = 8'h49; end
            8'h0E: begin pal_R = 8'hFC; pal_G = 8'hC4; pal_B = 8'h58; end
            8'h0F: begin pal_R = 8'hF5; pal_G = 8'h7A; pal_B = 8'h37; end
            8'h10: begin pal_R = 8'hDD; pal_G = 8'hF6; pal_B = 8'hF7; end
            8'h11: begin pal_R = 8'hD7; pal_G = 8'h6E; pal_B = 8'h35; end
            8'h12: begin pal_R = 8'hC2; pal_G = 8'hD2; pal_B = 8'hD9; end
            8'h13: begin pal_R = 8'hFF; pal_G = 8'hA5; pal_B = 8'h5C; end
            8'h14: begin pal_R = 8'hAB; pal_G = 8'h34; pal_B = 8'h20; end
            8'h15: begin pal_R = 8'h89; pal_G = 8'hC8; pal_B = 8'h26; end
            8'h16: begin pal_R = 8'h57; pal_G = 8'h06; pal_B = 8'h16; end
            8'h17: begin pal_R = 8'h19; pal_G = 8'h06; pal_B = 8'h57; end
            8'h18: begin pal_R = 8'h0C; pal_G = 8'h54; pal_B = 8'h42; end
            default: begin pal_R = 8'h00; pal_G = 8'h00; pal_B = 8'h00; end
        endcase
    end

    // pixel output dicision
    logic is_any_ui;
    assign is_any_ui = is_ui_feedback || is_ui_combo_10 || is_ui_combo_1 || 
                       is_ui_score_100 || is_ui_score_10 || is_ui_score_1;

    always_comb begin
        // UI 1st
        if (is_any_ui && !(pal_R == 8'hFF && pal_G == 8'h00 && pal_B == 8'hFF)) begin
            VGA_R = pal_R;
            VGA_G = pal_G;
            VGA_B = pal_B;
        end
        // Note 2nd
        else if (is_note == 1'b1) begin
            case (note_track_idx)
                2'd0: begin VGA_R = 8'hFF; VGA_G = 8'h00; VGA_B = 8'h00; end // r
                2'd1: begin VGA_R = 8'h00; VGA_G = 8'hFF; VGA_B = 8'h00; end // g
                2'd2: begin VGA_R = 8'h00; VGA_G = 8'h80; VGA_B = 8'hFF; end // b
                2'd3: begin VGA_R = 8'hFF; VGA_G = 8'hFF; VGA_B = 8'h00; end // y
            endcase
        end
        // vignette
        else if (is_vignette) begin
            VGA_R = vig_R;
            VGA_G = vig_G;
            VGA_B = vig_B;
        end
        // Track and BG 3rd
        else begin
            if (DrawX >= 160 && DrawX < 480) begin
                VGA_R = 8'h33; VGA_G = 8'h33; VGA_B = 8'h33;
                if (DrawY >= 400 && DrawY <= 404) begin
                    VGA_R = 8'hFF; VGA_G = 8'hFF; VGA_B = 8'hFF;
                end
                if (DrawX == 240 || DrawX == 320 || DrawX == 400) begin
                    VGA_R = 8'h55; VGA_G = 8'h55; VGA_B = 8'h55; 
                end
            end else begin
                VGA_R = 8'h11; VGA_G = 8'h11; VGA_B = 8'h22; 
            end
        end
    end 
endmodule