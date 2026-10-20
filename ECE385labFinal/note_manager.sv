// original ball.sv
module note_manager ( 
    input  logic        Clk,            // 50 MHz clock
    input  logic        Reset,          // Active-high reset signal
    input  logic        frame_clk,      // The clock indicating a new frame (~60Hz)
    
    // IO to contact with Qsys
    input  logic [7:0]  Spawn_PIO,      // [3:0] control the generation of notes
    input  logic [7:0]  Hit_PIO,        // [3:0] control the destroy of notes

    input  logic [9:0]  DrawX, DrawY,   // Current pixel coordinates
    output logic        is_note,        // is this pixel belongs to a note (like is_ball)
    output logic [1:0]  note_track_idx  // if belongs to a note, which track it belongs to
);
    
    parameter [9:0] FALL_SPEED = 10'd5;
    parameter [9:0] NOTE_HEIGHT = 10'd20;
    
    // 4轨道X边界, 屏幕宽640，中间320像素给4条轨道
    parameter [9:0] TRK0_L = 10'd160, TRK0_R = 10'd240;
    parameter [9:0] TRK1_L = 10'd240, TRK1_R = 10'd320;
    parameter [9:0] TRK2_L = 10'd320, TRK2_R = 10'd400;
    parameter [9:0] TRK3_L = 10'd400, TRK3_R = 10'd480;

    // 状态寄存器2d数组 [轨道][音符槽位]， 不过目前只打算让它能够容纳四个音符， 不要选用太快的曲子！
    //                 0 - 3   0 - 3
    logic       valid [4][4]; 
    logic [9:0] y_pos [4][4];



    // Edge Detection 防止多销毁音符，或是不销毁
    logic frame_clk_delayed, frame_clk_rising_edge;
    logic [3:0] spawn_delayed, spawn_edge;
    logic [3:0] hit_delayed, hit_edge;

    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
        
        spawn_delayed <= Spawn_PIO[3:0];
        spawn_edge    <= Spawn_PIO[3:0] & ~spawn_delayed;
        
        hit_delayed   <= Hit_PIO[3:0];
        hit_edge      <= Hit_PIO[3:0] & ~hit_delayed;
    end



    // 控制音符的销毁、生成、下落
    always_ff @ (posedge Clk) begin
        if (Reset) begin
            for (int t = 0; t < 4; t++)
                for (int n = 0; n < 4; n++) begin
                    valid[t][n] <= 1'b0;
                    y_pos[t][n] <= 10'd0;
                end
        end else begin
            // 遍历 4 条轨道
            for (int t = 0; t < 4; t++) begin
                
                // 收到engine发来的打中信号，销毁
                if (hit_edge[t]) begin
                    // 销毁该轨道最下面的有效音符
                    logic [2:0] max_n; 
                    logic [9:0] max_y;
                    
                    max_n = 3'd7;
                    max_y = 10'd0;
                    
                    for (int n = 0; n < 4; n++) begin
                        if (valid[t][n] && y_pos[t][n] >= max_y) begin
                            max_y = y_pos[t][n];
                            max_n = n[2:0];
                        end
                    end
                    if (max_n != 3'd7) valid[t][max_n] <= 1'b0; 
                end

                // 收到生成指令
                if (spawn_edge[t]) begin
                    // 找到第一个空位放入
                    for (int n = 0; n < 4; n++) begin
                        if (!valid[t][n]) begin
                            valid[t][n] <= 1'b1;
                            y_pos[t][n] <= 10'd0; // 从顶部生成
                            break; // 结束
                        end
                    end
                end

                // 根据VGA，下落
                if (frame_clk_rising_edge) begin
                    for (int n = 0; n < 4; n++) begin
                        if (valid[t][n]) begin
                            if (y_pos[t][n] + FALL_SPEED >= 10'd480) 
                                valid[t][n] <= 1'b0; // 漏掉的自动销毁
                            else 
                                y_pos[t][n] <= y_pos[t][n] + FALL_SPEED;
                        end
                    end
                end

            end // end for the tracks interation
        end
    end

    // 根据is_ball写的渲染判断逻辑
    always_comb begin
        is_note = 1'b0;
        note_track_idx = 2'b00;
        
        // 检查当前扫描像素(DrawX, DrawY)是否在任何活着的音符色块内
        for (int t = 0; t < 4; t++) begin
            for (int n = 0; n < 4; n++) begin
                if (valid[t][n] && DrawY >= y_pos[t][n] && DrawY < y_pos[t][n] + NOTE_HEIGHT) begin
                    // 属于哪个轨道
                    if ( (t == 0 && DrawX >= TRK0_L && DrawX < TRK0_R) ||
                         (t == 1 && DrawX >= TRK1_L && DrawX < TRK1_R) ||
                         (t == 2 && DrawX >= TRK2_L && DrawX < TRK2_R) ||
                         (t == 3 && DrawX >= TRK3_L && DrawX < TRK3_R) ) 
                    begin
                        is_note = 1'b1;
                        note_track_idx = t[1:0];
                    end
                end
            end
        end
    end
endmodule