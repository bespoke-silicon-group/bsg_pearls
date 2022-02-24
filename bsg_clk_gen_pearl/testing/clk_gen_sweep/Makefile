.DEFAULT_GOAL=run

export BSG_DESIGNS_DIR        := $(abspath ../../../)
export BSG_DESIGNS_TARGET_DIR := $(abspath ../../)

CLK_GEN_SWEEP_DIR := $(abspath ./)
POST_PTSI_SDF_DIR := $(BSG_DESIGNS_TARGET_DIR)/testing/rtl

SWEEP_RUNS_DIR    := $(CLK_GEN_SWEEP_DIR)/runs
SWEEP_RESULTS_DIR := $(CLK_GEN_SWEEP_DIR)/results

OUTPUT_CSV_PY  := $(CLK_GEN_SWEEP_DIR)/py/output_csv.py
RESULT_CSV     := $(SWEEP_RESULTS_DIR)/result.csv
PYTHON         := python3

PROCESSES   := ffpg_0p88v sspg_0p72v
TEMPS       := 125c m40c
RC_CORNERS  := sigcmax sigcmin sigrcmax sigrcmin
SDF_CORNERS := sdfmax sdfmin

CORNERS := $(foreach PROCESS_P, $(PROCESSES),                                \
             $(foreach TEMP_P, $(TEMPS),                                     \
               $(foreach RC_CORNER_P, $(RC_CORNERS),                         \
                 $(foreach SDF_CORNER_P, $(SDF_CORNERS),                     \
                   $(PROCESS_P)_$(TEMP_P)_$(RC_CORNER_P)_$(SDF_CORNER_P))))) \
           $(foreach SDF_CORNER_P, $(SDF_CORNERS),                           \
             tt_0p80v_25c_nominal_$(SDF_CORNER_P))

RUNS := $(foreach obj, $(CORNERS), run-$(obj))

run: $(RUNS)
	$(PYTHON) $(OUTPUT_CSV_PY) $(SWEEP_RESULTS_DIR) > $(RESULT_CSV)

run-%: $(SWEEP_RUNS_DIR) $(SWEEP_RESULTS_DIR)
	mkdir $(SWEEP_RUNS_DIR)/$*
	cd $(SWEEP_RUNS_DIR)/$*                                                    \
	&& ln -s $(POST_PTSI_SDF_DIR)/* .                                          \
	&& make run sdf_corner=$(subst sdf,,$(word 5, $(subst _, ,$*)))            \
	            corner=$(subst $(subst ,, ),_,$(wordlist 1,3,$(subst _, ,$*))) \
	            rc_corner=$(word 4, $(subst _, ,$*))                           \
	&& make summarize_details > $(SWEEP_RESULTS_DIR)/$*.log

csv:
	$(PYTHON) $(OUTPUT_CSV_PY) $(SWEEP_RESULTS_DIR) > $(RESULT_CSV)

$(SWEEP_RUNS_DIR):
	mkdir -p $@

$(SWEEP_RESULTS_DIR):
	mkdir -p $@

clean:
	rm -rf $(SWEEP_RUNS_DIR)
	rm -rf $(SWEEP_RESULTS_DIR)
