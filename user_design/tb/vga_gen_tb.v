`timescale 1ps/1ps

module vga_gen_tb;

reg clk = 1'b0;
reg rst = 1'b0;

wire hsync;
wire vsync;
wire [9:0]hcnt;
wire [9:0]vcnt;
wire in_display_area;

localparam CLK_FREQUENCY = 10_000_000;
localparam CLK_CYLCES_PER_SECOND = CLK_FREQUENCY;


vga_gen vga_gen_i(
    .clk(clk),
    .hsync(hsync),
    .vsync(vsync),
    .hcnt(hcnt),
    .vcnt(vcnt),
    .in_display_area(in_display_area)
);

always #50000 clk = (clk === 1'b0);


reg [2047:0] bitstream_hex_arg; // 256 bytes for characters
reg [2047:0] output_waveform_arg; // 256 bytes for characters
initial begin
    if ($value$plusargs("output_waveform=%s", output_waveform_arg)) begin
        $dumpfile(output_waveform_arg);
        $dumpvars(0, vga_gen_tb);
        $display("Output waveform set to %s", output_waveform_arg);
    end
    repeat (CLK_CYLCES_PER_SECOND / 30) @(posedge clk);
    $finish;
end


endmodule
