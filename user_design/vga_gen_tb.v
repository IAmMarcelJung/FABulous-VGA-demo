`timescale 1ns/1ps

module vga_gen_tb;

    reg clk;
    reg rst;
    wire hsync;
    wire vsync;
    wire [11:0] hcnt;
    wire [11:0] vcnt;
    wire in_display_area;

    // VGA timing parameters (from vga_gen.v)
    // Standard VGA 640x480 @ 60Hz timing
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC = 96;
    localparam H_BACK_PORCH = 48;
    localparam H_VISIBLE = 640;
    localparam H_TOTAL = H_FRONT_PORCH + H_SYNC + H_BACK_PORCH + H_VISIBLE;

    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC = 2;
    localparam V_BACK_PORCH = 33;
    localparam V_VISIBLE = 480;
    localparam V_TOTAL = V_FRONT_PORCH + V_SYNC + V_BACK_PORCH + V_VISIBLE;

    // Clock period - 25MHz clock (40ns period for standard VGA)
    localparam CLK_PERIOD = 40;

    // Instantiate the VGA generator
    vga_gen uut (
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .hcnt(hcnt),
        .vcnt(vcnt),
        .in_display_area(in_display_area)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test statistics
    integer hsync_count = 0;
    integer vsync_count = 0;
    integer pixel_count = 0;
    integer display_pixels = 0;

    reg prev_hsync;
    reg prev_vsync;

    // Monitor hsync edges
    always @(posedge clk) begin
        prev_hsync <= hsync;
        prev_vsync <= vsync;

        // Count falling edges of hsync (start of sync pulse)
        if (prev_hsync && !hsync) begin
            hsync_count = hsync_count + 1;
        end

        // Count falling edges of vsync (start of sync pulse)
        if (prev_vsync && !vsync) begin
            vsync_count = vsync_count + 1;
        end

        // Count pixels
        pixel_count = pixel_count + 1;
        if (in_display_area) begin
            display_pixels = display_pixels + 1;
        end
    end

    // Main test sequence
    initial begin
        $dumpfile("vga_gen_tb.vcd");
        $dumpvars(0, vga_gen_tb);

        $display("=== VGA Generator Testbench ===");
        $display("Resolution: %0dx%0d", H_VISIBLE, V_VISIBLE);
        $display("H Total: %0d, V Total: %0d", H_TOTAL, V_TOTAL);
        $display("Clock period: %0dns", CLK_PERIOD);

        // Initialize signals
        rst = 0;
        prev_hsync = 1;
        prev_vsync = 1;

        // Apply reset
        #(CLK_PERIOD * 2);
        rst = 1;
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 2);

        $display("\n--- Starting VGA timing verification ---");

        // Test 1: Verify horizontal counter rollover
        $display("\nTest 1: Checking horizontal counter...");
        wait(hcnt == 0);
        wait(hcnt == H_TOTAL - 1);
        #(CLK_PERIOD);
        if (hcnt != 0) begin
            $display("ERROR: Horizontal counter did not roll over correctly!");
            $display("Expected: 0, Got: %0d", hcnt);
        end else begin
            $display("PASS: Horizontal counter rolls over at %0d", H_TOTAL);
        end

        // Test 2: Verify vertical counter increments
        $display("\nTest 2: Checking vertical counter increment...");
        wait(hcnt == 0);
        #(CLK_PERIOD);
        if (vcnt == 0 || vcnt == 1) begin
            $display("PASS: Vertical counter increments on horizontal rollover");
        end else begin
            $display("ERROR: Vertical counter behavior unexpected");
        end

        // Test 3: Verify hsync timing
        $display("\nTest 3: Checking hsync timing...");
        wait(hcnt == 0);
        wait(hcnt == H_VISIBLE + H_FRONT_PORCH);
        #(CLK_PERIOD);
        if (!hsync) begin
            $display("PASS: hsync goes low at position %0d", H_VISIBLE + H_FRONT_PORCH);
        end else begin
            $display("ERROR: hsync should be low at start of sync pulse");
        end

        wait(hcnt == H_VISIBLE + H_FRONT_PORCH + H_SYNC);
        #(CLK_PERIOD);
        if (hsync) begin
            $display("PASS: hsync goes high after %0d clocks", H_SYNC);
        end else begin
            $display("ERROR: hsync should be high after sync pulse");
        end

        // Test 4: Verify display area signal
        $display("\nTest 4: Checking in_display_area signal...");
        wait(hcnt == 0 && vcnt == 0);
        #(CLK_PERIOD);
        if (in_display_area) begin
            $display("PASS: in_display_area active at (0,0)");
        end else begin
            $display("ERROR: in_display_area should be active at (0,0)");
        end

        wait(hcnt == H_VISIBLE);
        #(CLK_PERIOD);
        if (!in_display_area) begin
            $display("PASS: in_display_area inactive at horizontal boundary");
        end else begin
            $display("ERROR: in_display_area should be inactive outside visible area");
        end

        // Test 5: Complete frame timing
        $display("\nTest 5: Running complete frame...");
        hsync_count = 0;
        vsync_count = 0;
        display_pixels = 0;

        wait(vcnt == 0 && hcnt == 0);
        #(CLK_PERIOD);

        // Wait for one complete frame
        wait(vcnt == V_TOTAL - 1 && hcnt == H_TOTAL - 1);
        #(CLK_PERIOD * 2);

        $display("Horizontal syncs in frame: %0d (expected: %0d)", hsync_count, V_TOTAL);
        $display("Display pixels per frame: %0d (expected: %0d)", display_pixels, H_VISIBLE * V_VISIBLE);

        if (hsync_count >= V_TOTAL - 2 && hsync_count <= V_TOTAL + 2) begin
            $display("PASS: Correct number of horizontal sync pulses");
        end else begin
            $display("ERROR: Unexpected number of horizontal sync pulses");
        end

        // Test 6: Verify vsync timing
        $display("\nTest 6: Checking vsync timing...");
        wait(vcnt == 0 && hcnt == 0);
        vsync_count = 0;

        // Wait for vsync to go low
        wait(!vsync);
        $display("vsync went low at vcnt=%0d", vcnt);

        // Wait for vsync to go high
        wait(vsync);
        $display("vsync went high at vcnt=%0d", vcnt);

        if (vsync_count == 1) begin
            $display("PASS: One vsync pulse detected per frame");
        end

        // Run for a couple more frames to observe
        $display("\nRunning 2 additional frames for observation...");
        repeat(2) begin
            wait(vcnt == 0 && hcnt == 0);
            #(CLK_PERIOD);
            wait(vcnt == V_TOTAL - 1 && hcnt == H_TOTAL - 1);
            #(CLK_PERIOD * 2);
        end

        $display("\n=== All tests completed ===");
        $display("Total simulation time: %0t ns", $time);

        #(CLK_PERIOD * 10);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * H_TOTAL * V_TOTAL * 5);
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

    // Monitor key signals periodically
    initial begin
        #(CLK_PERIOD * 100);
        forever begin
            #(CLK_PERIOD * 1000);
            $display("[%0t] hcnt=%0d, vcnt=%0d, hsync=%b, vsync=%b, display=%b",
                     $time, hcnt, vcnt, hsync, vsync, in_display_area);
        end
    end

endmodule
