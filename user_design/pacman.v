//----------------------------------------------------------------------------------------------------------
// build a 64x64 pixel Packman sliding over the screen from left to right
//----------------------------------------------------------------------------------------------------------
// no timescale needed

module pacman(
    input wire clk,
    input wire rst,
    input wire [29:0]video_bar_i,
    output wire [29:0]video_bar_o
);

reg [9:0] v_pacman_pos;
reg [9:0] h_pacman_pos;

parameter PACMAN_HEIGHT = 64;
parameter PACMAN_WIDTH = 64;
parameter LOWER_BORDER = 480-10;  // Updated for 640x480 resolution
parameter RIGHT_BORDER = 640-10;  // Updated for 640x480 resolution


reg [10:0] pacman_counter;
reg pac_flag; // Tells which pacman sprite to use

wire [63:0] pacman_open [0:63];
wire [63:0] pacman_closed [0:63];

`include "pacman_closed_bitmap.vh"
`include "pacman_open_bitmap.vh"


wire r_in; wire g_in; wire b_in;
wire visible_in;
wire H_in; wire V_in;
wire [11:0] hcnt_in;
wire [11:0] vcnt_in;

reg r_out; reg g_out; reg b_out;
reg visible_out;
reg H_out; reg V_out;
reg [11:0] hcnt_out;
reg [11:0] vcnt_out;

wire at_start_of_frame;

wire [5:0] pacman_x;
wire [5:0] pacman_y;

// Calculate sprite pixel offset using hcnt_in and vcnt_in from VGA generator
assign pacman_x = hcnt_in - h_pacman_pos;
assign pacman_y = vcnt_in - v_pacman_pos;


//MAP BAR signals to readable internal signals
// video_bar format: {vcnt[11:0], hcnt[11:0], b, g, r, in_display_area, vsync, hsync}
assign video_bar_o[0] = H_out;
assign video_bar_o[1] = V_out;
assign video_bar_o[2] = visible_out;
assign video_bar_o[3] = r_out;
assign video_bar_o[4] = g_out;
assign video_bar_o[5] = b_out;
assign video_bar_o[17:6] = hcnt_out;
assign video_bar_o[29:18] = vcnt_out;

assign H_in       = video_bar_i[0];
assign V_in       = video_bar_i[1];
assign visible_in = video_bar_i[2];
assign r_in       = video_bar_i[3];
assign g_in       = video_bar_i[4];
assign b_in       = video_bar_i[5];
assign hcnt_in    = video_bar_i[17:6];
assign vcnt_in    = video_bar_i[29:18];

always @(posedge clk) begin : p_sync
    if (rst) begin
        H_out <= 1'b1;
        V_out <= 1'b1;
        visible_out <= 1'b0;
        hcnt_out <= 'b0;
        vcnt_out <= 'b0;
    end else begin
        // Register sync, visible, and position signals to match RGB pipeline delay
        H_out <= H_in;
        V_out <= V_in;
        visible_out <= visible_in;
        hcnt_out <= hcnt_in;
        vcnt_out <= vcnt_in;
    end
end

// Detect start of frame using hcnt and vcnt inputs
assign at_start_of_frame = (hcnt_in == 0 && vcnt_in == 0 && visible_in);

always @(posedge clk) begin : p_pacman_counter
    if (rst) begin
        pacman_counter <= 'b0;
        pac_flag <= 1'b0;
    end else begin
        if(at_start_of_frame) begin
            if(pacman_counter == 'd31) begin
                pacman_counter <= 0;
                pac_flag <=  ~pac_flag;
            end else begin
                pacman_counter <= pacman_counter + 1;
            end
        end
    end
end

always @(posedge clk) begin : p_position_counter
    if (rst) begin
        h_pacman_pos <= 'd0;
        v_pacman_pos <= 'd0;
    end else begin
        if(at_start_of_frame) begin
            if (h_pacman_pos >= RIGHT_BORDER) begin
                h_pacman_pos <= 'b0;
                if(v_pacman_pos >= LOWER_BORDER)  begin
                    // Reached the bottom
                    v_pacman_pos <= 'b0;
                end else begin
                    v_pacman_pos <= v_pacman_pos + 1;
                end
            end else begin
                h_pacman_pos <= h_pacman_pos + 1;
            end
        end
    end
end


always @(posedge clk) begin : p_display
    if (rst) begin
        r_out <= 'b0;
        g_out <= 'b0;
        b_out <= 'b0;
    end else begin
        // Pass the background through by default
        r_out <= r_in;
        g_out <= g_in;
        b_out <= b_in;

        // Check if current pixel is within pacman sprite bounds using hcnt_in and vcnt_in
        if ((hcnt_in >= h_pacman_pos && hcnt_in < (h_pacman_pos + PACMAN_WIDTH))
        && (vcnt_in >= v_pacman_pos && vcnt_in < (v_pacman_pos + PACMAN_HEIGHT)))
        begin
            if(pac_flag == 1'b1) begin
                if (!pacman_open[pacman_y][pacman_x]) begin
                    r_out <= 1'b1; //pac_red;
                    g_out <= 1'b1; // pac_green;
                    b_out <= 1'b0; // pac_blue;
                end
            end else begin
                if (!pacman_closed[pacman_y][pacman_x]) begin
                    r_out <= 1'b1; //pac_red;
                    g_out <= 1'b1; // pac_green;
                    b_out <= 1'b0; //   // pac_blue;
                end
            end
        end
    end
end


endmodule
