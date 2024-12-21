TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(BSG_PEARLS_MK_DIR)/Makefile.common

# hardware definitions

include $(BSG_DESIGN_MK_DIR)/Makefile.hardware
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.hardware

# collateral definitions

BUILD_SOURCES := bsg_chip_pkg.tcl

VDEFINES += SYNTHESIS

include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.collateral

# tool options

# Set to relevant netlist
# TODO: Could automate this a little bit
TOP_MODULE := bsg_clk_gen_pearl_final
SYN_NETLIST := $(BSG_DESIGN_YOSYS_DIR)/$(BSG_DESIGN).final.v

include $(BSG_PEARLS_MK_DIR)/Makefile.opensta


