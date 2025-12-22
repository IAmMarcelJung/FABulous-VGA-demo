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
    wire [9:0]hcnt, vcnt;
    wire in_display_area;

    localparam H_VIS_START = 64;
    localparam H_VIS_END = 264;
    localparam V_VIS_START = 27;
    localparam V_VIS_END = 627;
    // localparam HVIS = 264;
    // localparam VVIS = 628;

    vga_gen vga_gen_inst(
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .hcnt(hcnt),
        .vcnt(vcnt),
        .in_display_area(in_display_area)
    );

    wire [5:0]video_bar_in, video_bar_out;
    wire visible;
    wire r_out, g_out, b_out, vsync_out, hsync_out;

    reg r, g, b;


    pacman pacman_inst(
        .clk(clk),
        .rst(rst),
        .video_bar_i(video_bar_in),
        .video_bar_o(video_bar_out)
    );
    // assign video_bar_out  = video_bar_in;

    assign video_bar_in = {b, g, r, in_display_area, vsync, hsync};

    assign {b_out, g_out, r_out, visible, vsync_out, hsync_out} = video_bar_out;


    wire [8:0] paddle_position;
    wire left, right;

    wire border = (hcnt <= 10) // left border
               || (hcnt >= 200 - 10) //  right border
               || (vcnt <= 40) // upper border
               || (vcnt >= 600 - 40); // lower border
    always @(posedge clk) begin
        if (in_display_area) begin
            r <= border | hcnt[2] ^ vcnt[4]; //checkboard pattern
            g <= border;
            b <= border;
        end else {r, g, b} <= 3'b000;
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

