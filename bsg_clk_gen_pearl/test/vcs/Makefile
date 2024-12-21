TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(BSG_PEARLS_MK_DIR)/Makefile.common

# hardware definitions

include $(BSG_DESIGN_MK_DIR)/Makefile.hardware
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.hardware

# collateral options

BUILD_SOURCES := bsg_chip_pkg.sv bsg_chip_defines.svh

VDEFINES := BSG_NO_TIMESCALE
VDEFINES += BSG_OSC_BASE_DELAY=125
VDEFINES += BSG_OSC_GRANULARITY=50
VDEFINES += BSG_RP_CLK_GEN_SIM_DELAY=50

tag_tr := tag_boot.tr
test_tr := test1.tr
RUN_SOURCES := $(tag_tr) $(test_tr)

include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.collateral

# tool options
RUN_ARGS := +TAG_TRACE=$(tag_tr)
RUN_ARGS += +TEST_TRACE=$(test_tr)

TRACE := 1
ENABLE_VERDI := 0

include $(BSG_PEARLS_MK_DIR)/Makefile.vcs

