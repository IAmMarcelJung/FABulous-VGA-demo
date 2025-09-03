`timescale 1ps/1ps

module pacman_tb;

    reg clk = 1'b0;
    reg rst = 1'b0;

    wire hsync;
    wire vsync;
    wire [9:0] hcnt;
    wire [9:0] vcnt;
    wire in_display_area;

    // -------------------------------------------------------------------------
    // Clock generation: 10 MHz (period = 100 ns = 100_000 ps)
    // -------------------------------------------------------------------------
    always #50000 clk = ~clk; // half period = 50,000 ps

    // -------------------------------------------------------------------------
    // VGA sync generator
    // -------------------------------------------------------------------------
    vga_gen vga_gen_i (
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .hcnt(hcnt),
        .vcnt(vcnt),
        .in_display_area(in_display_area)
    );

    // -------------------------------------------------------------------------
    // Video bus between VGA generator and Pac-Man module
    // video_bar_i = {b_in,g_in,r_in,visible,vsync,hsync}
    // -------------------------------------------------------------------------
    wire [5:0] video_bar_i;
    wire [5:0] video_bar_o;

    // simple test background: red in top half, green in bottom half
    wire r_bg = in_display_area && (vcnt < 300);
    wire g_bg = in_display_area && (vcnt >= 300);
    wire b_bg = 1'b0;

    assign video_bar_i[0] = hsync;
    assign video_bar_i[1] = vsync;
    assign video_bar_i[2] = in_display_area;
    assign video_bar_i[3] = r_bg;
    assign video_bar_i[4] = g_bg;
    assign video_bar_i[5] = b_bg;

    // -------------------------------------------------------------------------
    // Pac-Man overlay
    // -------------------------------------------------------------------------
    pacman pacman_i (
        .clk(clk),
        .rst(rst),
        .video_bar_i(video_bar_i),
        .video_bar_o(video_bar_o)
    );

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    reg [2047:0] output_waveform_arg; // 256 bytes for characters
    initial begin
        if ($value$plusargs("output_waveform=%s", output_waveform_arg)) begin
            $dumpfile(output_waveform_arg);
            $dumpvars(0, pacman_vga_tb);
            $display("Output waveform set to %s", output_waveform_arg);
        end
        // simulate ~1/30 second worth of frames
        repeat (10_000_000 / 30) @(posedge clk);
        $finish;
    end

endmodule
