module audio_driver (
    input  logic        Clk,
    input  logic        Reset,
    input  logic        data_over,
    input  logic        start,

    output logic [15:0] LDATA,
    output logic [15:0] RDATA
);

    // ROM has 65536 words, so address is 16 bits
    logic [15:0] rom_addr;
    logic [7:0]  rom_q;

    // Detect start rising edge
    logic start_prev;
    logic start_edge;

    // Detect data_over rising edge
    logic data_over_prev;
    logic data_tick;

    logic playing;
    logic waiting_to_play;

    // music.mif was generated at 5000 Hz
    logic [31:0] rate_accum;

    // 1 second delay after Enter
    // CLOCK_50 = 50 MHz, so 50,000,000 cycles = 1 second
    logic [31:0] delay_counter;
    localparam logic [31:0] AUDIO_START_DELAY_CYCLES = 32'd50_000_000;

    // Calibrated based on your measured playback time:
    // 48000 made total time about 19.83s.
    // 31500 should make Enter-to-stop time close to 13s.
    localparam logic [31:0] AUDIO_RATE_DENOM = 32'd31_500;

    logic signed [15:0] audio_sample;

    assign start_edge = start & ~start_prev;
    assign data_tick  = data_over & ~data_over_prev;

    music_rom music_rom0 (
        .address(rom_addr),
        .clock(Clk),
        .q(rom_q)
    );

    always_comb begin
        // rom_q = 8'h80 means silence/midpoint.
        // Convert unsigned 8-bit [0, 255] to signed 16-bit audio.
        audio_sample = $signed({1'b0, rom_q}) - 16'sd128;
        audio_sample = audio_sample <<< 8;
    end

    always_ff @(posedge Clk) begin
        if (Reset) begin
            rom_addr        <= 16'd0;
            rate_accum      <= 32'd0;
            LDATA           <= 16'd0;
            RDATA           <= 16'd0;
            playing         <= 1'b0;
            waiting_to_play <= 1'b0;
            delay_counter   <= 32'd0;
            start_prev      <= 1'b0;
            data_over_prev  <= 1'b0;
        end else begin
            start_prev     <= start;
            data_over_prev <= data_over;

            // Press Enter: reset audio position and start 1 second delay
            if (start_edge) begin
                rom_addr        <= 16'd0;
                rate_accum      <= 32'd0;
                playing         <= 1'b0;
                waiting_to_play <= 1'b1;
                delay_counter   <= 32'd0;
                LDATA           <= 16'd0;
                RDATA           <= 16'd0;
            end

            // Wait 1 second before audio starts
            if (waiting_to_play) begin
                if (delay_counter >= AUDIO_START_DELAY_CYCLES) begin
                    waiting_to_play <= 1'b0;
                    playing         <= 1'b1;
                    delay_counter   <= 32'd0;
                end else begin
                    delay_counter <= delay_counter + 32'd1;
                end
            end

            // Only update audio once per data_over rising edge
            if (data_tick) begin
                if (playing) begin
                    LDATA <= audio_sample;
                    RDATA <= audio_sample;

                    // music.mif was generated at 5000 samples/sec.
                    rate_accum <= rate_accum + 32'd5000;

                    if (rate_accum >= AUDIO_RATE_DENOM) begin
                        rate_accum <= rate_accum - AUDIO_RATE_DENOM;
                        rom_addr   <= rom_addr + 16'd1;
                    end

                    // Stop after about 12 seconds of stored audio.
                    // 12 sec * 5000 samples/sec = 60000 samples.
                    if (rom_addr >= 16'd60000) begin
                        rom_addr <= 16'd0;
                        playing  <= 1'b0;
                    end
                end else begin
                    LDATA <= 16'd0;
                    RDATA <= 16'd0;
                end
            end
        end
    end

endmodule