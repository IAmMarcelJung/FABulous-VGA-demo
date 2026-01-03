module vga_gen #(
    // VGA timing parameters (default: 640x480 @ 60Hz)
    parameter H_VISIBLE = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC = 96,
    parameter H_BACK_PORCH = 48,

    parameter V_VISIBLE = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC = 2,
    parameter V_BACK_PORCH = 33,

    // Display offset parameters
    parameter H_OFFSET = 40,  // Horizontal offset to compensate for display shift
    parameter V_OFFSET = 0    // Vertical offset to compensate for display shift
)(
    input clk,
    input rst,
    output reg hsync,
    output reg vsync,
    output reg [11:0] hcnt,
    output reg [11:0] vcnt,
    output reg in_display_area,
    output reg [11:0] x,      // Display position X (adjusted for offset) - now registered
    output reg [11:0] y       // Display position Y (adjusted for offset) - now registered
);

    // Calculate total line/frame counts from parameters
    localparam H_TOTAL = H_VISIBLE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;
    localparam V_TOTAL = V_VISIBLE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;



    always @(posedge clk) begin
        if (rst) begin
            hcnt <= 0;
            vcnt <= 0;
            hsync <= 1;
            vsync <= 1;
            in_display_area <= 0;
            x <= 0;
            y <= 0;
        end else begin
            hcnt <= (hcnt == H_TOTAL - 1) ? 0 : hcnt + 1;
            if (hcnt == H_TOTAL - 1) vcnt <= (vcnt == V_TOTAL - 1) ? 0 : vcnt + 1;

            // All outputs registered for consistent timing
            // Register x and y to match in_display_area pipeline timing
            x <= hcnt - H_OFFSET;
            y <= vcnt - V_OFFSET;

            // Add offsets to shift visible area (compensate for display shift)
            in_display_area <= (hcnt >= H_OFFSET) && (hcnt < H_VISIBLE + H_OFFSET) &&
                              (vcnt >= V_OFFSET) && (vcnt < V_VISIBLE + V_OFFSET);
            hsync <= ~((hcnt >= H_VISIBLE + H_FRONT_PORCH) && (hcnt < H_VISIBLE + H_FRONT_PORCH + H_SYNC));
            vsync <= ~((vcnt >= V_VISIBLE + V_FRONT_PORCH) && (vcnt < V_VISIBLE + V_FRONT_PORCH + V_SYNC));
        end
  end
  //
endmodule
