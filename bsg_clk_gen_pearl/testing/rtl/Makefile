
# Note: most variables that are file/dir paths are ?= because they can be
# overriden by the chip repo if this makefile is called from the chip
# infrastructure.

.DEFAULT_GOAL=run
.SECONDARY:

export BSG_DESIGNS_TARGET_DIR ?= $(abspath ../../)
export BASEJUMP_STL_DIR       ?= $(BSG_DESIGNS_TARGET_DIR)/basejump_stl

include $(BSG_DESIGNS_TARGET_DIR)/bsg_cadenv/cadenv.mk
#include $(BSG_DESIGNS_TARGET_DIR)/mk/hier.mk

BSG_WORK_DIR := $(abspath ./)
BSG_OUT_DIR  := $(BSG_WORK_DIR)/out
BSG_OUT_SIM  := $(BSG_OUT_DIR)/simv

# ==========================================================
# VCS OPTIONS
# ==========================================================

VCS_OPTIONS := -full64
VCS_OPTIONS += -notice
VCS_OPTIONS += -debug_pp
VCS_OPTIONS += +vcs+vcdpluson
VCS_OPTIONS += -V
VCS_OPTIONS += +v2k
VCS_OPTIONS += -sverilog
VCS_OPTIONS += -assert svaext
VCS_OPTIONS += +noportcoerce
VCS_OPTIONS += +vc
VCS_OPTIONS += +vcs+loopreport
VCS_OPTIONS += -timescale=1ps/1ps
VCS_OPTIONS += -diag timescale 
VCS_OPTIONS += -o $(BSG_OUT_SIM)
VCS_OPTIONS += -Mdir=$(BSG_OUT_DIR)
VCS_OPTIONS += -top bsg_config bsg_config.v
VCS_OPTIONS += +vcs+lic+wait

# ==========================================================
# CHIP AND TESTING FILELISTS AND LIBLISTS
# ==========================================================

BSG_TOP_SIM_MODULE     = bsg_clk_gen_pearl_pcb
BSG_CHIP_INSTANCE_PATH = $(BSG_TOP_SIM_MODULE).IC

VCS_OPTIONS += +define+BSG_TOP_SIM_MODULE=$(BSG_TOP_SIM_MODULE)
VCS_OPTIONS += +define+BSG_CHIP_INSTANCE_PATH=$(BSG_CHIP_INSTANCE_PATH)

export BSG_CHIP_LIBRARY_NAME = bsg_chip
export BSG_CHIP_FILELIST     = $(BSG_OUT_DIR)/$(BSG_CHIP_LIBRARY_NAME).filelist
export BSG_CHIP_LIBRARY      = $(BSG_OUT_DIR)/$(BSG_CHIP_LIBRARY_NAME).library

VCS_OPTIONS += +define+BSG_CHIP_LIBRARY_NAME=$(BSG_CHIP_LIBRARY_NAME)
VCS_OPTIONS += -f $(BSG_CHIP_FILELIST)
VCS_OPTIONS += -libmap $(BSG_CHIP_LIBRARY)

export BSG_DESIGNS_TESTING_LIBRARY_NAME = bsg_design_testing
export BSG_DESIGNS_TESTING_FILELIST     = $(BSG_OUT_DIR)/$(BSG_DESIGNS_TESTING_LIBRARY_NAME).filelist
export BSG_DESIGNS_TESTING_LIBRARY      = $(BSG_OUT_DIR)/$(BSG_DESIGNS_TESTING_LIBRARY_NAME).library

VCS_OPTIONS += +define+BSG_DESIGNS_TESTING_LIBRARY_NAME=$(BSG_DESIGNS_TESTING_LIBRARY_NAME)
VCS_OPTIONS += -f $(BSG_DESIGNS_TESTING_FILELIST)
VCS_OPTIONS += -libmap $(BSG_DESIGNS_TESTING_LIBRARY)

$(BSG_CHIP_FILELIST): $(BSG_DESIGNS_TESTING_LIBRARY)
$(BSG_CHIP_LIBRARY): $(BSG_DESIGNS_TESTING_LIBRARY)
$(BSG_DESIGNS_TESTING_FILELIST): $(BSG_DESIGNS_TESTING_LIBRARY)
$(BSG_DESIGNS_TESTING_LIBRARY): $(BSG_OUT_DIR)
	/usr/bin/tclsh bsg_config.tcl

# ==========================================================
# TOPLEVEL PARAMETERS
# ==========================================================

BSG_TOPLEVEL_PARAMS_DIR ?= $(BSG_DESIGNS_TARGET_DIR)/tcl/parameters.tcl
BSG_TOPLEVEL_PARAMS := $(shell grep "=" $(BSG_TOPLEVEL_PARAMS_DIR))
VCS_OPTIONS += $(foreach PARAM, $(BSG_TOPLEVEL_PARAMS), -pvalue+$(PARAM))

#VCS_OPTIONS += +define+DUT_MODULE_NAME=$(TOP_HIER_BLOCK)

VCS_OPTIONS += +define+BSG_OSC_BASE_DELAY=125
VCS_OPTIONS += +define+BSG_OSC_GRANULARITY=5

# ==========================================================
# TRACE REPLAY ROMS
# ==========================================================

BSG_TRACE_NAME  := bsg_tag_boot
BSG_TRACE_PY    := $(BSG_DESIGNS_TARGET_DIR)/testing/py/$(BSG_TRACE_NAME).py
BSG_TRACE_FILES := $(BSG_OUT_DIR)/$(BSG_TRACE_NAME).tr
BSG_TRACE_ROMS  := $(BSG_OUT_DIR)/$(BSG_TRACE_NAME)_rom.v
BSG_TRACE_PY_PARAMS := $(foreach PARAM, $(BSG_TOPLEVEL_PARAMS), $(word 2, $(subst =, ,$(PARAM))))

$(BSG_TRACE_FILES): $(BSG_TRACE_PY) | $(BSG_OUT_DIR)
	python $< $(BSG_TRACE_PY_PARAMS) > $@

$(BSG_TRACE_ROMS): $(BSG_TRACE_FILES) | $(BSG_OUT_DIR)
	$(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $< $(BSG_TRACE_NAME)_rom > $@

VCS_OPTIONS += $(addprefix -v ,$(BSG_TRACE_ROMS))

# ==========================================================
# RUN TARGETS
# ==========================================================

summarize:
	grep -o -E ".*NEGEDGE.*[0-9]+\s+ps" $(BSG_OUT_DIR)/run.log | grep -o -E "[0-9]+\s+ps" | grep -o -E "[0-9]+" | column -c 100
	grep -o -E ".*POSEDGE.*[0-9]+\s+ps" $(BSG_OUT_DIR)/run.log | grep -o -E "[0-9]+\s+ps" | grep -o -E "[0-9]+" | column -c 100

summarize_details:
	grep -o -E -n ".*NEGEDGE.*[0-9]+\s+ps" $(BSG_OUT_DIR)/run.log
	grep -o -E -n ".*POSEDGE.*[0-9]+\s+ps" $(BSG_OUT_DIR)/run.log

run: $(BSG_OUT_SIM)
	cd $(BSG_OUT_DIR); $(BSG_OUT_SIM) $(PLUSARGS) | tee -i run.log

run-no-tee: $(BSG_OUT_SIM)
	cd $(BSG_OUT_DIR); $(BSG_OUT_SIM) $(PLUSARGS)

rerun:
	cd $(BSG_OUT_DIR); $(BSG_OUT_SIM) $(PLUSARGS) | tee -i run.log

rerun-no-tee:
	cd $(BSG_OUT_DIR); $(BSG_OUT_SIM) $(PLUSARGS)

build: $(BSG_OUT_SIM)
$(BSG_OUT_SIM): $(BSG_CHIP_FILELIST) $(BSG_CHIP_LIBRARY) $(BSG_DESIGNS_TESTING_FILELIST) $(BSG_DESIGNS_TESTING_LIBRARY) $(BSG_TRACE_ROMS)
	$(VCS) $(VCS_OPTIONS) | tee -i $(BSG_OUT_DIR)/build.log

dve view:
	$(VCS_BIN)/dve -full64 -vpd $(BSG_OUT_DIR)/vcdplus.vpd

$(BSG_OUT_DIR):
	mkdir -p $@

clean:
	rm -rf $(BSG_OUT_DIR) DVEfiles
	rm -f stack.info.* vc_hdrs.h vcdplus.vpd inter.vpd ucli.key

