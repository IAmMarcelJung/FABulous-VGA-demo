module vga_gen  (
    input clk,
    input rst,
    output reg hsync,
    output reg vsync,
    output reg [9:0] hcnt,
    output reg [9:0]vcnt,
    output reg in_display_area
);

    // running at 10MHz, targeting a pixel clock of 40MHz: divide horizontal timings by 4
    // localparam H_FRONT_PORCH = 10 -1;
    // localparam H_VISIBLE = H_FRONT_PORCH + 200;
    // localparam H_BACK_PORCH = H_VISIBLE + 22;
    // localparam H_SYNC = H_BACK_PORCH + 32;
    // localparam H_TOTAL = H_SYNC;
    //
    // localparam V_FRONT_PORCH = 1 -1;
    // localparam V_VISIBLE = V_FRONT_PORCH + 600;
    // localparam V_BACK_PORCH = V_VISIBLE + 23;
    // localparam V_SYNC = V_FRONT_PORCH + 4;
    // localparam V_TOTAL = V_SYNC;
    //
    localparam H_FRONT_PORCH = 10;
    localparam H_SYNC = 22;
    localparam H_BACK_PORCH = 32;
    localparam H_VISIBLE = 200;
    localparam H_TOTAL = H_FRONT_PORCH + H_SYNC + H_BACK_PORCH + H_VISIBLE;

    localparam V_FRONT_PORCH = 1;
    localparam V_SYNC = 4;
    localparam V_BACK_PORCH = 23;
    localparam V_VISIBLE = 600;
    localparam V_TOTAL = V_FRONT_PORCH + V_SYNC + V_BACK_PORCH + V_VISIBLE;



  //   always @(posedge clk) begin
  //     if (rst) begin
  //         hcnt <= 0;
  //         vcnt <= 0;
  //         hsync <= 1;
  //         vsync <= 1;
  //         in_display_area <= 0;
  //     end else begin
  //       if (hcnt == (H_TOTAL)) begin
  //           if (vcnt == (V_TOTAL)) begin
  //               vcnt <= 0;
  //           end else begin
  //               vcnt <= vcnt + 1'b1;
  //           end
  //           hcnt <= 0;
  //       end else begin
  //           hcnt <= hcnt + 1'b1;
  //       end
  //       // hsync   <= ~((hcnt >= H_FRONT_PORCH) && (hcnt < H_FRONT_PORCH + H_SYNC));
  //       // vsync   <= ~((vcnt >= V_FRONT_PORCH) && (vcnt < V_FRONT_PORCH + V_SYNC));
  //       // in_display_area <= (((hcnt >= H_FRONT_PORCH + H_SYNC + H_BACK_PORCH) && hcnt < H_TOTAL) &&
  //       //     ((vcnt >= V_FRONT_PORCH + V_SYNC + V_BACK_PORCH) && vcnt < V_TOTAL));
  //       //
  //       hsync   <= ~(hcnt < H_SYNC);
  //       vsync   <= ~(vcnt < V_SYNC);
  //       in_display_area <= (((hcnt >= H_SYNC + H_BACK_PORCH) && hcnt < H_TOTAL - H_FRONT_PORCH) &&
  //           ((vcnt >= V_SYNC + H_BACK_PORCH) && vcnt < V_TOTAL - V_FRONT_PORCH));
  //   end
  // end

    always @(posedge clk) begin
        in_display_area <= (hcnt<H_VISIBLE) && (vcnt<V_VISIBLE);
        hcnt <= (hcnt==H_VISIBLE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH-1) ? 0 : hcnt+1;
        if(hcnt==H_VISIBLE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH-1) vcnt <= (vcnt==V_VISIBLE+V_FRONT_PORCH+V_SYNC+V_BACK_PORCH-1) ? 0 : vcnt+1;
        hsync <= (hcnt>=H_VISIBLE+H_FRONT_PORCH) && (hcnt<H_VISIBLE+H_FRONT_PORCH+H_SYNC);
        vsync <= (vcnt>=V_VISIBLE+V_FRONT_PORCH) && (vcnt<V_VISIBLE+V_FRONT_PORCH+V_SYNC);
  end

endmodule
