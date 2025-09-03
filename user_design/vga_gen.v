module vga_gen  (
    input clk,
    input rst,
    output reg hsync = 0,
    output reg vsync = 0,
    output reg [9:0] hcnt = 0,
    output reg [9:0]vcnt = 0,
    output reg in_display_area = 0
);

    // running at 10MHz, targeting a pixel clock of 40MHz: divide horizontal timings by 4
    localparam H_VISIBLE = 200;
    localparam H_FRONT_PORCH = H_VISIBLE + 5;
    localparam H_SYNC = H_FRONT_PORCH + 32;
    localparam H_TOTAL = 264;

    localparam V_VISIBLE_AREA = 600;
    localparam V_FRONT_PORCH = V_VISIBLE_AREA + 10;
    localparam V_SYNC = V_FRONT_PORCH + 2;
    localparam V_TOTAL = 628;


    always @(posedge clk) begin
        if (hcnt == (H_TOTAL - 1)) begin
            if (vcnt == (V_TOTAL - 1)) begin
                vcnt <= 0;
            end else begin
                vcnt <= vcnt + 1'b1;
            end
            hcnt <= 0;
        end else begin
            hcnt <= hcnt + 1'b1;
        end
        hsync   <= ~((hcnt >= H_FRONT_PORCH) && (hcnt < H_SYNC));
        vsync   <= ~((vcnt >= V_FRONT_PORCH) && (vcnt < V_SYNC));
        in_display_area <= (hcnt < H_VISIBLE) && (vcnt < V_VISIBLE_AREA);
    end

endmodule
