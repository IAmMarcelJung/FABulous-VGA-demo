# Makefile for VGA Testbenches

# Verilog compiler
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files
VGA_GEN_DUT = vga_gen.v
VGA_GEN_TB = vga_gen_tb.v

TOP_DUT = top.v
TOP_TB = top_tb.v
TOP_STREAM_TB = top_stream_tb.v

# Output files
VGA_GEN_VVP = vga_gen_tb.vvp
VGA_GEN_VCD = vga_gen_tb.vcd

TOP_VVP = top_tb.vvp
TOP_VCD = top_tb.vcd

TOP_STREAM_VVP = top_stream_tb.vvp

# Compiler flags
IVERILOG_FLAGS = -g2012 -Wall

.PHONY: all compile sim view clean help visual

all: sim

# Compile the VGA generator testbench
compile: $(VGA_GEN_VVP)

$(VGA_GEN_VVP): $(VGA_GEN_DUT) $(VGA_GEN_TB)
	@echo "Compiling VGA generator testbench..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(VGA_GEN_VVP) $(VGA_GEN_DUT) $(VGA_GEN_TB)
	@echo "Compilation successful!"

# Compile the visual testbench (top module)
compile-visual: $(TOP_VVP)

$(TOP_VVP): $(TOP_DUT) $(TOP_TB)
	@echo "Compiling visual testbench..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(TOP_VVP) $(TOP_DUT) $(TOP_TB)
	@echo "Compilation successful!"

# Compile the streaming testbench
compile-stream: $(TOP_STREAM_VVP)

$(TOP_STREAM_VVP): $(TOP_DUT) $(TOP_STREAM_TB)
	@echo "Compiling streaming testbench..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(TOP_STREAM_VVP) $(TOP_DUT) $(TOP_STREAM_TB)
	@echo "Compilation successful!"

# Run VGA generator simulation
sim: $(VGA_GEN_VVP)
	@echo "Running VGA generator simulation..."
	$(VVP) $(VGA_GEN_VVP)
	@echo "Simulation complete!"

# Run visual testbench (generates PPM images)
visual: $(TOP_VVP)
	@echo "Running visual testbench..."
	$(VVP) $(TOP_VVP)
	@echo "Visual testbench complete!"
	@echo "Generated PPM image files - view with: python vga_viewer.py --file frame_0.ppm"

# Run live visual testbench with viewer
live: $(TOP_VVP)
	@echo "Starting live VGA viewer..."
	@echo "Open a second terminal and run: python vga_viewer.py --live"
	@echo "Press Ctrl+C to stop simulation"
	$(VVP) $(TOP_VVP) +live=1

# View frames with Python viewer
view-frames:
	@echo "Opening VGA viewer..."
	python vga_viewer.py --file frame_0.ppm

# Stream mode - true real-time video streaming!
stream: $(TOP_STREAM_VVP)
	@echo "Starting VGA video stream..."
	@echo "Press Ctrl+C to stop"
	@echo ""
	$(VVP) $(TOP_STREAM_VVP) 2>&1 | python vga_stream_viewer.py

# View VGA generator waveform
view: $(VGA_GEN_VCD)
	@echo "Opening waveform viewer..."
	$(GTKWAVE) $(VGA_GEN_VCD) &

# View visual testbench waveform
view-visual: $(TOP_VCD)
	@echo "Opening visual testbench waveform..."
	$(GTKWAVE) $(TOP_VCD) &

# Run simulation and view waveform
run: sim view

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f $(VGA_GEN_VVP) $(VGA_GEN_VCD) $(TOP_VVP) $(TOP_VCD) $(TOP_STREAM_VVP)
	rm -f frame_*.ppm frame_*.png
	@echo "Clean complete!"

# Help target
help:
	@echo "VGA Testbench Makefile"
	@echo "======================"
	@echo "Targets:"
	@echo "  make compile        - Compile VGA generator testbench"
	@echo "  make compile-visual - Compile visual testbench"
	@echo "  make compile-stream - Compile streaming testbench"
	@echo "  make sim            - Run VGA generator simulation"
	@echo "  make visual         - Run visual testbench (generates PPM images)"
	@echo "  make stream         - Real-time video streaming (RECOMMENDED!)"
	@echo "  make live           - Run continuous simulation for live viewing"
	@echo "  make view-frames    - View generated frames with Python viewer"
	@echo "  make view           - Open VGA gen waveform viewer (GTKWave)"
	@echo "  make view-visual    - Open visual testbench waveform"
	@echo "  make run            - Run sim and view waveform"
	@echo "  make clean          - Remove all generated files"
	@echo "  make all            - Default target (same as sim)"
	@echo "  make help           - Show this help message"
	@echo ""
	@echo "Visual Debugging:"
	@echo "  🎥 BEST - Real-time streaming (single command):"
	@echo "    make stream"
	@echo ""
	@echo "  📸 Quick start (static frames):"
	@echo "    make visual && make view-frames"
	@echo ""
	@echo "  🔴 Live viewing (2 terminals):"
	@echo "    Terminal 1: make live"
	@echo "    Terminal 2: python vga_viewer.py --live"
