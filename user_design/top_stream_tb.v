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

    // Simple capture using in_display_area directly
    integer pixel_x = 0;
    integer pixel_y = 0;
    integer frame_count = 0;
    reg prev_in_display = 0;
    reg prev_vsync = 1;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Simple pixel capture - capture while in_display_area is high
    always @(posedge clk) begin
        prev_in_display <= in_display_area;
        prev_vsync <= vga_vsync;

        // Detect vsync falling edge (start of new frame)
        if (prev_vsync && !vga_vsync) begin
            frame_count = frame_count + 1;
            pixel_y = 0;
            pixel_x = 0;
            $fwrite(32'h8000_0002, "FRAME %0d\n", frame_count);
            $fflush(32'h8000_0002);
        end

        // Reset pixel_x at start of each line
        if (!prev_in_display && in_display_area) begin
            pixel_x = 0;
        end

        // Capture while in_display_area is high
        if (in_display_area && pixel_x < H_VISIBLE && pixel_y < V_VISIBLE) begin
            $fwrite(32'h8000_0001, "%c%c%c",
                vga_r ? 8'd255 : 8'd0,
                vga_g ? 8'd255 : 8'd0,
                vga_b ? 8'd255 : 8'd0
            );
            pixel_x = pixel_x + 1;

            if (pixel_x >= H_VISIBLE) begin
                $fflush(32'h8000_0001);
            end
        end

        // End of line
        if (prev_in_display && !in_display_area) begin
            if (pixel_y < V_VISIBLE - 1) begin
                pixel_y = pixel_y + 1;
            end
        end
    end

    // Main test sequence
    initial begin
        $fwrite(32'h8000_0002, "=== VGA Streaming Testbench ===\n");
        $fwrite(32'h8000_0002, "Resolution: %0dx%0d\n", H_VISIBLE, V_VISIBLE);
        $fwrite(32'h8000_0002, "Streaming to stdout...\n");
        $fflush(32'h8000_0002);

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
    // Uncomment to auto-stop after 100 frames
    // initial begin
    //     wait(frame_count >= 100);
    //     $finish;
    // end

endmodule
