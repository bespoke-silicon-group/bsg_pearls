TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(BSG_PEARLS_MK_DIR)/Makefile.common

# hardware definitions

include $(BSG_DESIGN_MK_DIR)/Makefile.hardware
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.hardware

# collateral options

BUILD_SOURCES := bsg_chip_pkg.sv bsg_chip_pkg.tcl

include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.collateral

# tool options

include $(BSG_PEARLS_MK_DIR)/Makefile.yosys

