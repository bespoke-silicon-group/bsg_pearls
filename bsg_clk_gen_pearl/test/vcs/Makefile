TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

# hardware definitions
TRACE := 1
ENABLE_VERDI := 0
ENABLE_DC := 1

VDEFINES := BSG_OSC_BASE_DELAY=125
VDEFINES += BSG_OSC_GRANULARITY=50
VDEFINES += BSG_RP_CLK_GEN_OSC_SIM_DELAY=100
VDEFINES += BSG_RP_CLK_GEN_UNIT_SIM_DELAY=50

include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.collateral
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.hardware
include $(BSG_DESIGN_TEST_MK_DIR)/Makefile.vcs

$(eval $(call bsg_fn_vcs_sim,vlog,testA,tag_boot,test1))
$(eval $(call bsg_fn_vcs_sim,vlog,testB,tag_boot,test1))
$(eval $(call bsg_fn_vcs_sim,hard,testA,tag_boot,test1))
$(eval $(call bsg_fn_vcs_sim,hard,testB,tag_boot,test1))

