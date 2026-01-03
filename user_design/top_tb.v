`timescale 1ns/1ps

module top_tb;

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

    // Pin definitions (from top.v)
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

    // Frame buffer for capturing image
    reg [2:0] framebuffer [0:V_VISIBLE-1][0:H_VISIBLE-1]; // {R,G,B} per pixel

    integer frame_count = 0;
    integer h_counter = 0;  // Horizontal pixel counter
    integer v_counter = 0;  // Vertical line counter
    integer pixel_x = 0;
    integer pixel_y = 0;
    reg prev_hsync = 1;
    reg prev_vsync = 1;

    // VGA counter organization: Visible -> Front Porch -> Sync -> Back Porch
    localparam H_OFFSET = 15;  // From top.v
    localparam V_OFFSET = 0;   // From top.v

    // Pipeline delay: in_display_area (1) + RGB (1) + pacman (1) = 3 clocks
    localparam PIPELINE_DELAY = 3;

    // Capture window accounting for offset and pipeline delay
    localparam H_CAPTURE_START = H_OFFSET + PIPELINE_DELAY;
    localparam H_CAPTURE_END = H_CAPTURE_START + H_VISIBLE;
    localparam V_CAPTURE_START = V_OFFSET + PIPELINE_DELAY;
    localparam V_CAPTURE_END = V_CAPTURE_START + V_VISIBLE;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Track position - synchronized with VGA sync signals
    always @(posedge clk) begin
        prev_hsync <= vga_hsync;
        prev_vsync <= vga_vsync;

        // Synchronize h_counter on hsync rising edge
        // hsync rises at hcnt = H_VISIBLE + H_FRONT_PORCH + H_SYNC = 752
        if (!prev_hsync && vga_hsync) begin
            h_counter = 752;  // Sync point
        end else begin
            h_counter = (h_counter == H_TOTAL - 1) ? 0 : h_counter + 1;
        end

        // Synchronize v_counter on vsync rising edge
        // vsync rises at vcnt = V_VISIBLE + V_FRONT_PORCH + V_SYNC = 492
        if (!prev_vsync && vga_vsync) begin
            v_counter = 492;  // Sync point

            // Save previous frame
            if (frame_count > 0) begin
                // Rotate through 3 frame files for live viewing
                if (frame_count % 3 == 1) begin
                    save_frame_to_ppm("frame_0.ppm");
                end else if (frame_count % 3 == 2) begin
                    save_frame_to_ppm("frame_1.ppm");
                end else begin
                    save_frame_to_ppm("frame_2.ppm");
                end
            end

            frame_count = frame_count + 1;
        end else if (!prev_hsync && vga_hsync) begin
            // New line
            v_counter = (v_counter == V_TOTAL - 1) ? 0 : v_counter + 1;
        end

        // Capture pixels accounting for offset and pipeline delay
        if (h_counter >= H_CAPTURE_START && h_counter < H_CAPTURE_END &&
            v_counter >= V_CAPTURE_START && v_counter < V_CAPTURE_END) begin

            // Calculate position in visible area
            pixel_x = h_counter - H_CAPTURE_START;
            pixel_y = v_counter - V_CAPTURE_START;

            if (pixel_x < H_VISIBLE && pixel_y < V_VISIBLE) begin
                framebuffer[pixel_y][pixel_x] = {vga_r, vga_g, vga_b};
            end
        end
    end

    // Task to save framebuffer to PPM file
    task save_frame_to_ppm;
        input [256*8-1:0] filename;
        integer file;
        integer x, y;
        integer r, g, b;
        begin
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("ERROR: Could not open file %s", filename);
            end else begin
                // PPM header (P3 = ASCII format)
                $fwrite(file, "P3\n");
                $fwrite(file, "%0d %0d\n", H_VISIBLE, V_VISIBLE);
                $fwrite(file, "255\n");

                // Write pixel data
                for (y = 0; y < V_VISIBLE; y = y + 1) begin
                    for (x = 0; x < H_VISIBLE; x = x + 1) begin
                        // Convert 1-bit RGB to 8-bit RGB (0 or 255)
                        r = framebuffer[y][x][2] ? 255 : 0;
                        g = framebuffer[y][x][1] ? 255 : 0;
                        b = framebuffer[y][x][0] ? 255 : 0;
                        $fwrite(file, "%0d %0d %0d ", r, g, b);
                    end
                    $fwrite(file, "\n");
                end

                $fclose(file);
                $display("Saved frame to %s", filename);
            end
        end
    endtask

    // Live mode control
    integer live_mode = 0;
    integer max_frames = 3;

    // Main test sequence
    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        $display("=== VGA Top Module Visual Testbench ===");
        $display("Resolution: %0dx%0d", H_VISIBLE, V_VISIBLE);

        // Check for live mode environment variable
        if ($value$plusargs("live=%d", live_mode)) begin
            $display("LIVE MODE: Running continuous simulation");
            max_frames = 999999;  // Run indefinitely
        end else begin
            $display("Capturing %0d frames to PPM files...", max_frames);
        end

        // Initialize inputs
        io_in = 24'h0;

        // Apply reset
        io_in[RESET_PIN] = 1;
        #(CLK_PERIOD * 10);
        io_in[RESET_PIN] = 0;
        #(CLK_PERIOD * 10);

        $display("Reset released, running simulation...");

        // Run for specified number of frames
        #(CLK_PERIOD * H_TOTAL * V_TOTAL * (max_frames + 1));

        if (!live_mode) begin
            $display("\n=== Simulation Complete ===");
            $display("Generated files:");
            $display("  - top_tb.vcd (waveform for GTKWave)");
            $display("  - frame_0.ppm (first frame)");
            $display("  - frame_1.ppm (second frame)");
            $display("  - frame_2.ppm (third frame)");
            $display("\nView with: python vga_viewer.py --file frame_0.ppm");
            $display("Or view all: feh frame_*.ppm");
        end

        $finish;
    end

    // Timeout watchdog (30 seconds of simulation time)
    initial begin
        #30_000_000_000;
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

    // Progress indicator
    always @(posedge clk) begin
        if (frame_count > 0 && pixel_y == 0 && pixel_x == 0) begin
            $display("  Frame %0d captured", frame_count - 1);
        end
    end

endmodule
