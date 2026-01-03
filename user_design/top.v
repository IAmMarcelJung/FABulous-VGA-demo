`include "pacman.v"
`include "vga_gen.v"
module top (
    input wire clk,
// verilator lint_off UNUSEDSIGNAL
    input wire [23:0] io_in,
// verilator lint_on UNUSEDSIGNAL
// verilator lint_off UNDRIVEN
    output wire [23:0] io_out,
// verilator lint_on UNDRIVEN
    io_oeb
);

    localparam COUNTER_WIDTH = 24;

    // WARNING: Don't change these values for MPW5!
    localparam OUTPUT_ENABLE = 1'b1;
    localparam OUTPUT_DISABLE = 1'b0;

    localparam RESET_PIN = 23;
    localparam RESET_OUT_PIN = 21;
    localparam PADDLE_LEFT_INPUT_PIN = 19;
    localparam PADDLE_RIGHT_INPUT_PIN = 17;


    // VGA pins
    localparam VGA_VYSNC_PIN = 22;
    localparam VGA_HYSNC_PIN = 20;
    localparam VGA_BLUE_PIN = 18;
    localparam VGA_GREEN_PIN = 16;
    localparam VGA_RED_PIN = 14;

    wire rst;
    wire hsync, vsync;
    wire [11:0]hcnt, vcnt;
    wire [11:0]x, y;
    wire in_display_area;

    // VGA timing parameters (640x480 @ 60Hz)
    localparam H_VISIBLE = 640;
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC = 96;
    localparam H_BACK_PORCH = 48;

    localparam V_VISIBLE = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC = 2;
    localparam V_BACK_PORCH = 33;

    // Display offset parameters (adjust if image is shifted)
    // localparam H_OFFSET = 15;
    localparam H_OFFSET = 0;
    localparam V_OFFSET = 0;

    vga_gen #(
        .H_VISIBLE(H_VISIBLE),
        .H_FRONT_PORCH(H_FRONT_PORCH),
        .H_SYNC(H_SYNC),
        .H_BACK_PORCH(H_BACK_PORCH),
        .V_VISIBLE(V_VISIBLE),
        .V_FRONT_PORCH(V_FRONT_PORCH),
        .V_SYNC(V_SYNC),
        .V_BACK_PORCH(V_BACK_PORCH),
        .H_OFFSET(H_OFFSET),
        .V_OFFSET(V_OFFSET)
    ) vga_gen_inst(
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .hcnt(hcnt),
        .vcnt(vcnt),
        .in_display_area(in_display_area),
        .x(x),
        .y(y)
    );

    wire [5:0]video_bar_in, video_bar_out;
    wire visible;
    wire r_out, g_out, b_out, vsync_out, hsync_out;

    reg r, g, b;


    // pacman pacman_inst(
    //     .clk(clk),
    //     .rst(rst),
    //     .video_bar_i(video_bar_in),
    //     .video_bar_o(video_bar_out)
    // );
    assign video_bar_in = {b, g, r, in_display_area, vsync, hsync};
    assign {b_out, g_out, r_out, visible, vsync_out, hsync_out} = video_bar_out;
    assign video_bar_out =  video_bar_in;

    wire [8:0] paddle_position;
    wire left, right;

    wire border = (x <= 10) // left border
               || (x >= 640 - 10) //  right border
               || (y <= 10) // upper border
               || (y >= 480 - 10); // lower border

    // Make RGB registered to match registered sync signals
    always @(posedge clk) begin
        if (in_display_area) begin
            r <= border | x[4] ^ y[4]; //checkboard pattern
            g <= border;
            b <= border;
        end else begin
            r <= 1'b0;
            g <= 1'b0;
            b <= 1'b0;
        end
    end

    // Inputs
    assign rst = io_in[RESET_PIN];
    assign io_oeb[RESET_PIN] = OUTPUT_DISABLE;
    assign left = io_in[PADDLE_LEFT_INPUT_PIN];
    assign io_oeb[PADDLE_LEFT_INPUT_PIN] = OUTPUT_DISABLE;
    assign right = io_in[PADDLE_RIGHT_INPUT_PIN];
    assign io_oeb[PADDLE_RIGHT_INPUT_PIN] = OUTPUT_DISABLE;

    // Outputs

    // Route the reset through for debugging
    assign io_out[RESET_OUT_PIN] = rst;
    assign io_oeb[RESET_OUT_PIN] = OUTPUT_ENABLE;

    // VGA connections
    assign io_out[VGA_RED_PIN] = r_out;
    assign io_out[VGA_GREEN_PIN] = g_out;
    assign io_out[VGA_BLUE_PIN] = b_out;
    assign io_out[VGA_HYSNC_PIN] =  hsync_out;
    assign io_out[VGA_VYSNC_PIN] =  vsync_out;

    assign io_oeb[VGA_RED_PIN] = OUTPUT_ENABLE;
    assign io_oeb[VGA_GREEN_PIN] = OUTPUT_ENABLE;
    assign io_oeb[VGA_BLUE_PIN] = OUTPUT_ENABLE;
    assign io_oeb[VGA_HYSNC_PIN] = OUTPUT_ENABLE;
    assign io_oeb[VGA_VYSNC_PIN] = OUTPUT_ENABLE;
endmodule

