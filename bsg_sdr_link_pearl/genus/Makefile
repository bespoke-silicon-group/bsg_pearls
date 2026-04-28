TOP := $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

include $(BSG_PEARLS_MK_DIR)/Makefile.genus

# Dynamic rules to create the sims
$(eval $(call bsg_fn_design_gen))
$(eval $(call bsg_fn_config_gen))

$(eval $(call bsg_fn_genus_synth,basic))

