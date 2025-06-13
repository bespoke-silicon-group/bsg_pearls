TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

# hardware definitions
TRACE := 1
ENABLE_SURFER := 1

VDEFINES += BSG_OSC_BASE_DELAY=125
VDEFINES += BSG_OSC_GRANULARITY=50
VDEFINES += BSG_RP_CLK_GEN_OSC_SIM_DELAY=125
VDEFINES += BSG_RP_CLK_GEN_UNIT_SIM_DELAY=50

include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.collateral
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.hardware
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.verilator

$(eval $(call bsg_fn_verilator_sim,vlog,testA,tag_boot,test1))
$(eval $(call bsg_fn_verilator_sim,vlog,testB,tag_boot,test1))
$(eval $(call bsg_fn_verilator_sim,hard,testA,tag_boot,test1))
$(eval $(call bsg_fn_verilator_sim,hard,testB,tag_boot,test1))

