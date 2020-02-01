VHDL_SOURCES = $(PWD)/../MIPS-SingleCycle.vhdl
SIM=GHDL
TOPLEVEL_LANG=vhdl

# enable VCD?
ifeq ($(VCD),true)
	SIM_ARGS= --wave=sim.ghw --vcd=sim.vcd
endif

#arguments passed to GHDL
COMPILE_ARGS= --ieee=synopsys -fexplicit

# TOPLEVEL is the name of the toplevel module in your VHDL file:
TOPLEVEL=mips

# MODULE is the name of the Python test file:
MODULE=MIPS_tb

#included for cocotb
include $(shell cocotb-config --makefiles)/Makefile.inc
include $(shell cocotb-config --makefiles)/Makefile.sim
