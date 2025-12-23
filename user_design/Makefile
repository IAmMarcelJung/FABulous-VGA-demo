# Makefile for VGA Generator Testbench

# Verilog compiler
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files
DUT = vga_gen.v
TB = vga_gen_tb.v

# Output files
VVP_OUT = vga_gen_tb.vvp
VCD_OUT = vga_gen_tb.vcd

# Compiler flags
IVERILOG_FLAGS = -g2012 -Wall

.PHONY: all compile sim view clean help

all: sim

# Compile the testbench
compile: $(VVP_OUT)

$(VVP_OUT): $(DUT) $(TB)
	@echo "Compiling Verilog sources..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(VVP_OUT) $(DUT) $(TB)
	@echo "Compilation successful!"

# Run simulation
sim: $(VVP_OUT)
	@echo "Running simulation..."
	$(VVP) $(VVP_OUT)
	@echo "Simulation complete!"

# View waveform
view: $(VCD_OUT)
	@echo "Opening waveform viewer..."
	$(GTKWAVE) $(VCD_OUT) &

# Run simulation and view waveform
run: sim view

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f $(VVP_OUT) $(VCD_OUT)
	@echo "Clean complete!"

# Help target
help:
	@echo "VGA Generator Testbench Makefile"
	@echo "================================"
	@echo "Targets:"
	@echo "  make compile  - Compile the testbench"
	@echo "  make sim      - Run the simulation"
	@echo "  make view     - Open waveform viewer (GTKWave)"
	@echo "  make run      - Run simulation and view waveform"
	@echo "  make clean    - Remove generated files"
	@echo "  make all      - Default target (same as sim)"
	@echo "  make help     - Show this help message"
