TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common

include $(BSG_DESIGN_MK_DIR)/Makefile.hardware
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.hardware

BUILD_SOURCES := $(VPKG) $(VSOURCES) $(TEST_VSOURCES)

VDEFINES :=

tag_tr := tag_boot.tr
test_tr := test1.tr
RUN_SOURCES := $(tag_tr) $(test_tr)

RUN_ARGS := +TAG_TRACE=$(tag_tr)
RUN_ARGS += +TEST_TRACE=$(test_tr)

include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.collateral
include $(BSG_PEARLS_MK_DIR)/Makefile.verilator

