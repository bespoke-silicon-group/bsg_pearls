TOP := $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

# Simulation defines
VDEFINES := BSG_OSC_BASE_DELAY=125
VDEFINES += BSG_OSC_GRANULARITY=50
VDEFINES += BSG_RP_CLK_GEN_OSC_SIM_DELAY=100
VDEFINES += BSG_RP_CLK_GEN_UNIT_SIM_DELAY=50

# Simulation parameters
TRACE := 1
COVERAGE := 1
ENABLE_SURFER := 1

include $(BSG_PEARLS_MK_DIR)/Makefile.verilator

# Dynamic rules to create the sims
$(eval $(call bsg_fn_design_gen))
$(eval $(call bsg_fn_config_gen))

$(eval $(call bsg_fn_verilator_build,vlog))
$(eval $(call bsg_fn_verilator_build,hard))

$(eval $(call bsg_fn_verilator_sim,vlog,testA,tag_boot,test1))
#$(eval $(call bsg_fn_verilator_sim,hard,testA,tag_boot,test1))

$(eval $(call bsg_fn_verilator_coverage,vlog))

