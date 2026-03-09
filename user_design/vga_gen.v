//----------------------------------------------------------------------------------------------------------
// VGA Timing Generator - Clean Implementation
// Generates standard VGA 640x480 @ 60Hz timing signals
//
// All outputs are perfectly synchronized - counters and signals update together
// No confusing offsets - just clean, simple VGA timing
//----------------------------------------------------------------------------------------------------------

module vga_gen #(
    // VGA 640x480 @ 60Hz timing parameters (25 MHz pixel clock)
    parameter H_VISIBLE     = 640,  // Horizontal visible area
    parameter H_FRONT_PORCH = 16,   // Horizontal front porch
    parameter H_SYNC        = 96,   // Horizontal sync pulse width
    parameter H_BACK_PORCH  = 48,   // Horizontal back porch

    parameter V_VISIBLE     = 480,  // Vertical visible area
    parameter V_FRONT_PORCH = 10,   // Vertical front porch
    parameter V_SYNC        = 2,    // Vertical sync pulse width
    parameter V_BACK_PORCH  = 33   // Vertical back porch

)(
    input  wire clk,
    input  wire rst,

    output reg hsync,               // Horizontal sync (active low)
    output reg vsync,               // Vertical sync (active low)
    output reg [11:0] hcnt,         // Horizontal counter (0 to H_TOTAL-1)
    output reg [11:0] vcnt,         // Vertical counter (0 to V_TOTAL-1)
    output reg in_display_area      // High when in visible display area
);

    // Calculate total counts
    localparam H_TOTAL = H_VISIBLE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;  // 800
    localparam V_TOTAL = V_VISIBLE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;  // 525

    // Sync pulse start positions
    localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;  // 656
    localparam H_SYNC_END   = H_SYNC_START + H_SYNC;      // 752
    localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;  // 490
    localparam V_SYNC_END   = V_SYNC_START + V_SYNC;      // 492

    // Calculate next counter values (combinatorial)
    wire [11:0] hcnt_next;
    wire [11:0] vcnt_next;

    assign hcnt_next = (hcnt == H_TOTAL - 1) ? 12'd0 : hcnt + 12'd1;
    assign vcnt_next = (hcnt == H_TOTAL - 1) ?
                       ((vcnt == V_TOTAL - 1) ? 12'd0 : vcnt + 12'd1) :
                       vcnt;

    always @(posedge clk) begin
        if (rst) begin
            hcnt <= 0;
            vcnt <= 0;
            hsync <= 1;
            vsync <= 1;
            in_display_area <= 0;
        end else begin
            // Update counters
            hcnt <= hcnt_next;
            vcnt <= vcnt_next;

            // Generate all outputs using NEXT counter values
            // This ensures they are aligned with the hcnt/vcnt that will be on the wire
            hsync <= ~((hcnt_next >= H_SYNC_START) && (hcnt_next < H_SYNC_END));
            vsync <= ~((vcnt_next >= V_SYNC_START) && (vcnt_next < V_SYNC_END));
            in_display_area <= (hcnt_next < H_VISIBLE) && (vcnt_next < V_VISIBLE);
        end
    end

endmodule
