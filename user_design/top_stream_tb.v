`timescale 1ns/1ps

module top_stream_tb;

    reg clk;
    reg [23:0] io_in;
    wire [23:0] io_out;
    wire [23:0] io_oeb;

    // VGA timing parameters
    localparam H_VISIBLE = 640;
    localparam V_VISIBLE = 480;
    localparam H_TOTAL = 800;
    localparam V_TOTAL = 525;

    // Clock period - 25MHz (40ns period for VGA pixel clock)
    localparam CLK_PERIOD = 40;

    // Pipeline delay: vga_gen (1) + top.v RGB (1) + pacman (1) = 2 total cycles
    // (vga_gen and top.v/pacman overlap in the same cycle)
    localparam PIPELINE_DELAY = 2;

    // Pin definitions
    localparam RESET_PIN = 23;
    localparam VGA_VYSNC_PIN = 22;
    localparam VGA_HYSNC_PIN = 20;
    localparam VGA_BLUE_PIN = 18;
    localparam VGA_GREEN_PIN = 16;
    localparam VGA_RED_PIN = 14;

    // Instantiate top module
    top uut (
        .clk(clk),
        .io_in(io_in),
        .io_out(io_out),
        .io_oeb(io_oeb)
    );

    // Extract VGA signals
    wire vga_r = io_out[VGA_RED_PIN];
    wire vga_g = io_out[VGA_GREEN_PIN];
    wire vga_b = io_out[VGA_BLUE_PIN];
    wire vga_hsync = io_out[VGA_HYSNC_PIN];
    wire vga_vsync = io_out[VGA_VYSNC_PIN];

    // Access internal signals via hierarchical path
    wire in_display_area = uut.in_display_area;
    wire [11:0] hcnt = uut.hcnt;
    wire [11:0] vcnt = uut.vcnt;

    // Pipeline delay shift registers to synchronize capture with RGB output
    reg [PIPELINE_DELAY-1:0] in_display_delay;
    reg [PIPELINE_DELAY-1:0] vsync_delay;

    wire in_display_delayed = in_display_delay[PIPELINE_DELAY-1];
    wire vsync_delayed = vsync_delay[PIPELINE_DELAY-1];

    // Frame tracking
    integer pixel_x = 0;
    integer pixel_y = 0;
    integer frame_count = 0;
    reg prev_in_display_delayed = 0;
    reg prev_vsync_delayed = 1;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Pipeline delay and pixel capture with proper synchronization
    always @(posedge clk) begin
        // Shift in_display_area and vsync through delay pipeline
        in_display_delay <= {in_display_delay[PIPELINE_DELAY-2:0], in_display_area};
        vsync_delay <= {vsync_delay[PIPELINE_DELAY-2:0], vga_vsync};

        prev_in_display_delayed <= in_display_delayed;
        prev_vsync_delayed <= vsync_delayed;

        // Detect vsync falling edge (start of new frame) - using delayed signal
        if (prev_vsync_delayed && !vsync_delayed) begin
            frame_count = frame_count + 1;
            pixel_y = 0;
            pixel_x = 0;
            $fwrite(32'h8000_0002, "FRAME %0d\n", frame_count);
            $fflush(32'h8000_0002);
        end

        // Reset pixel_x at start of each line - using delayed signal
        if (!prev_in_display_delayed && in_display_delayed) begin
            pixel_x = 0;
        end

        // Capture RGB using delayed in_display_area signal
        // This ensures RGB data is synchronized with the correct pixel position
        if (in_display_delayed && pixel_x < H_VISIBLE && pixel_y < V_VISIBLE) begin
            // Write RGB bytes in order: R, G, B
            $fwrite(32'h8000_0001, "%c%c%c",
                vga_r ? 8'd255 : 8'd0,
                vga_g ? 8'd255 : 8'd0,
                vga_b ? 8'd255 : 8'd0
            );
            pixel_x = pixel_x + 1;

            // Flush after each line for better streaming performance
            if (pixel_x >= H_VISIBLE) begin
                $fflush(32'h8000_0001);
            end
        end

        // End of line detection - using delayed signal
        if (prev_in_display_delayed && !in_display_delayed) begin
            if (pixel_y < V_VISIBLE - 1) begin
                pixel_y = pixel_y + 1;
            end
        end
    end

    // Main test sequence
    initial begin
        $fwrite(32'h8000_0002, "=== VGA Streaming Testbench (Pipeline Corrected) ===\n");
        $fwrite(32'h8000_0002, "Resolution: %0dx%0d\n", H_VISIBLE, V_VISIBLE);
        $fwrite(32'h8000_0002, "Pipeline delay: %0d cycles\n", PIPELINE_DELAY);
        $fwrite(32'h8000_0002, "Streaming to stdout...\n");
        $fflush(32'h8000_0002);

        // Initialize delay shift registers
        in_display_delay = 0;
        vsync_delay = {PIPELINE_DELAY{1'b1}};  // Initialize to high (inactive)

        // Initialize inputs
        io_in = 24'h0;

        // Apply reset
        io_in[RESET_PIN] = 1;
        #(CLK_PERIOD * 10);
        io_in[RESET_PIN] = 0;
        #(CLK_PERIOD * 10);

        // Run indefinitely (stop with Ctrl+C)
        // Note: This will run forever, user must interrupt
    end

    // Optional: Stop after N frames for testing
    // Uncomment to auto-stop after 10 frames
    // initial begin
    //     wait(frame_count >= 10);
    //     #(CLK_PERIOD * H_TOTAL * V_TOTAL);
    //     $fwrite(32'h8000_0002, "\nAuto-stopped after %0d frames\n", frame_count);
    //     $finish;
    // end

endmodule
