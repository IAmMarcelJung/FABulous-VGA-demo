BUILD_DIR=build
DESIGN=pacman
DESIGN_FILE=../${DESIGN}.v
TESTBENCH=${DESIGN}_tb
VVP_ARGS=+output_waveform=${BUILD_DIR}/${DESIGN}.${WAVEFORM_TYPE}
VVP_ARGS+=-fst
SAVEFILE_TYPE=gtkw

sim:
	iverilog -s ${TESTBENCH} -o ${BUILD_DIR}/${DESIGN}.vvp  ${DESIGN_FILE} ${TESTBENCH}.v -g2012 ../pacman_open_bitmap.vh ../pacman_closed_bitmap.vh
	vvp ${BUILD_DIR}/${DESIGN}.vvp ${VVP_ARGS}

view:
	gtkwave ${BUILD_DIR}/${DESIGN}.${WAVEFORM_TYPE}

view-saved:
	gtkwave ${DESIGN}.${SAVEFILE_TYPE}
