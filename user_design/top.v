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
    output wire [23:0] io_oeb
);

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
    localparam VGA_BLUE_PIN  = 18;
    localparam VGA_GREEN_PIN = 16;
    localparam VGA_RED_PIN   = 14;

    wire rst;
    wire hsync, vsync;
    wire [11:0] hcnt, vcnt;
    wire in_display_area;

    // VGA timing parameters (640x480 @ 60Hz)
    // Adjusted to center image: H_FRONT 16->4, H_BACK 48->60, V_FRONT 10->6, V_BACK 33->37
    // This moves the image ~12 pixels right and 4 lines down.
    localparam H_VISIBLE     = 640;
    localparam H_FRONT_PORCH = 4;   // Minimum safe front porch
    localparam H_SYNC        = 96;
    localparam H_BACK_PORCH  = 60;

    localparam V_VISIBLE     = 480;
    localparam V_FRONT_PORCH = 6;
    localparam V_SYNC        = 2;
    localparam V_BACK_PORCH  = 37;

    vga_gen #(
        .H_VISIBLE(H_VISIBLE),
        .H_FRONT_PORCH(H_FRONT_PORCH),
        .H_SYNC(H_SYNC),
        .H_BACK_PORCH(H_BACK_PORCH),
        .V_VISIBLE(V_VISIBLE),
        .V_FRONT_PORCH(V_FRONT_PORCH),
        .V_SYNC(V_SYNC),
        .V_BACK_PORCH(V_BACK_PORCH)
    ) vga_gen_inst(
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .hcnt(hcnt),
        .vcnt(vcnt),
        .in_display_area(in_display_area)
    );

    wire [29:0] video_bar_in;
    wire [29:0] video_bar_out;
    wire [11:0] hcnt_out, vcnt_out;
    wire r_out, g_out, b_out, vsync_out, hsync_out, visible_out;

    // --- Background Generation ---
    wire r_bg, g_bg, b_bg;
    wire border = (hcnt <= 10) || (hcnt >= 640 - 10) || (vcnt <= 10) || (vcnt >= 480 - 10);

    assign r_bg = in_display_area ? (border | hcnt[4] ^ vcnt[4]) : 1'b0;
    assign g_bg = in_display_area ? border : 1'b0;
    assign b_bg = in_display_area ? border : 1'b0;

    // Pipeline Stage 1: Register Background (1 cycle)
    reg [29:0] video_bar_reg;
    always @(posedge clk) begin
        if (rst) begin
            video_bar_reg <= 30'd0;
        end else begin
            video_bar_reg <= {vcnt, hcnt, b_bg, g_bg, r_bg, in_display_area, vsync, hsync};
        end
    end

    // Final Output Decoding (Directly from registered background)
    assign {vcnt_out, hcnt_out, b_out, g_out, r_out, visible_out, vsync_out, hsync_out} = video_bar_reg;

    // --- IO Assignments ---
    assign rst = io_in[RESET_PIN];
    assign io_oeb[RESET_PIN] = OUTPUT_DISABLE;

    // Unused paddle pins
    assign io_oeb[PADDLE_LEFT_INPUT_PIN] = OUTPUT_DISABLE;
    assign io_oeb[PADDLE_RIGHT_INPUT_PIN] = OUTPUT_DISABLE;

    // Route the reset through for debugging
    assign io_out[RESET_OUT_PIN] = rst;
    assign io_oeb[RESET_OUT_PIN] = OUTPUT_ENABLE;

    // VGA Output Connections
    assign io_out[VGA_RED_PIN]   = r_out;
    assign io_out[VGA_GREEN_PIN] = g_out;
    assign io_out[VGA_BLUE_PIN]  = b_out;
    assign io_out[VGA_HYSNC_PIN] = hsync_out;
    assign io_out[VGA_VYSNC_PIN] = vsync_out;

    assign io_oeb[VGA_RED_PIN]   = OUTPUT_ENABLE;
    assign io_oeb[VGA_GREEN_PIN] = OUTPUT_ENABLE;
    assign io_oeb[VGA_BLUE_PIN]  = OUTPUT_ENABLE;
    assign io_oeb[VGA_HYSNC_PIN] = OUTPUT_ENABLE;
    assign io_oeb[VGA_VYSNC_PIN] = OUTPUT_ENABLE;

endmodule
