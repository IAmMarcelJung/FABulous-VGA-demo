//----------------------------------------------------------------------------------------------------------
// build a 64x64 pixel Packman sliding over the screen from left to right
//----------------------------------------------------------------------------------------------------------
// no timescale needed

module pacman(
    input wire clk,
    input wire rst,
    input wire [5:0]video_bar_i,
    output wire [5:0]video_bar_o
);

reg [9:0] v_pixel_pos;
reg [9:0] h_pixel_pos;

reg [9:0] v_pacman_pos;
reg [9:0] h_pacman_pos;
reg old_visible_in;

parameter PACMAN_HEIGHT = 64;
parameter PACMAN_WIDTH = 64;
parameter LOWER_BORDER = 600-40;
parameter RIGHT_BORDER = 200-10;


reg [10:0] pacman_counter;
reg pac_flag; // Tells which pacman sprite to use

wire [63:0] pacman_open [0:63];
wire [63:0] pacman_closed [0:63];

`include "pacman_closed_bitmap.vh"
`include "pacman_open_bitmap.vh"


wire r_in; wire g_in; wire b_in;
wire visible_in;
wire H_in; wire V_in;

reg r_out; reg g_out; reg b_out;
wire visible_out;
reg H_out; reg V_out;

wire at_start_of_frame;

wire [5:0] pacman_x;
wire [5:0] pacman_y;

assign pacman_x = h_pixel_pos - h_pacman_pos;
assign pacman_y = v_pixel_pos - v_pacman_pos;


//MAP BAR signals to readable internal signals
assign video_bar_o[0] = H_out;
assign video_bar_o[1] = V_out;
assign video_bar_o[2] = visible_out;
assign video_bar_o[3] = r_out;
assign video_bar_o[4] = g_out;
assign video_bar_o[5] = b_out;

assign H_in       = video_bar_i[0];
assign V_in       = video_bar_i[1];
assign visible_in = video_bar_i[2];
assign r_in       = video_bar_i[3];
assign g_in       = video_bar_i[4];
assign b_in       = video_bar_i[5];

wire in_line = old_visible_in == 1'b1;
wire at_end_of_visible_line = visible_in == 1'b0 && old_visible_in == 1'b1;

always @(posedge clk) begin : p_sync
    if (rst) begin
        old_visible_in <= 1'b0;
        H_out <= 1'b0;
        V_out <= 1'b0;
        h_pixel_pos <= 'b0;
        v_pixel_pos <= 'b0;
    end else begin
        old_visible_in <= visible_in;
        H_out <= H_in;
        V_out <= V_in;

        // if(old_visible_in == 1'b1) begin
        if(in_line) begin
          // in line
            h_pixel_pos <= h_pixel_pos + 1; // Traverse through the line
        end else begin
            h_pixel_pos <= 0;
            // if(V_in == 1'b1)
            //     v_pixel_pos <= v_pixel_pos + 1; // Go to the next line
        end

        if(V_in == 1'b1) begin
            v_pixel_pos <= 0;
        // end else if(visible_in == 1'b0 && old_visible_in == 1'b1) begin
        end else if(at_end_of_visible_line) begin
            v_pixel_pos <= v_pixel_pos + 1; // Go to the next line
        end
    end
end

assign visible_out = old_visible_in;

assign at_start_of_frame = (h_pixel_pos == 0 && v_pixel_pos == 0);

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

        //TODO fix the condition! this is not working properly, could als be
        //that it never evaluets to true.
        if ((h_pixel_pos >= h_pacman_pos && h_pixel_pos < (h_pacman_pos + PACMAN_WIDTH))
        && (v_pixel_pos >= v_pacman_pos && v_pixel_pos < (v_pacman_pos + PACMAN_HEIGHT)))
        begin
            if(pac_flag == 1'b1) begin
                if (!pacman_open[pacman_y][pacman_x]) begin
                    r_out <= 1'b1; //pac_red;
                    g_out <= 1'b1; // pac_green;
                    b_out <= 1'b1; // pac_blue;
                end
            end else begin
                if (!pacman_closed[pacman_y][pacman_x]) begin
                    r_out <= 1'b1; //pac_red;
                    g_out <= 1'b1; // pac_green;
                    b_out <= 1'b1; //   // pac_blue;
                end
            end
        end
    end
end


endmodule
