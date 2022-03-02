.DEFAULT_GOAL=run

export BSG_DESIGNS_DIR        := $(abspath ../../../../)
export BSG_DESIGNS_TARGET_DIR := $(abspath ../../../)

CLK_GEN_SWEEP_RUN_DIR := $(abspath ./)
CLK_GEN_SWEEP_DIR := $(CLK_GEN_SWEEP_RUN_DIR)/../
SIMULATION_DIR    := $(BSG_DESIGNS_TARGET_DIR)/testing/rtl

SWEEP_RUNS_DIR    := $(CLK_GEN_SWEEP_RUN_DIR)/runs
SWEEP_RESULTS_DIR := $(CLK_GEN_SWEEP_RUN_DIR)/results

OUTPUT_CSV_PY  := $(CLK_GEN_SWEEP_DIR)/py/output_csv.py
RESULT_CSV     := $(SWEEP_RESULTS_DIR)/result.csv
PYTHON         := python3

RUNS := run-rtl

run: $(RUNS)
	$(PYTHON) $(OUTPUT_CSV_PY) $(SWEEP_RESULTS_DIR) > $(RESULT_CSV)

run-%: $(SWEEP_RUNS_DIR) $(SWEEP_RESULTS_DIR)
	mkdir $(SWEEP_RUNS_DIR)/$*
	cd $(SWEEP_RUNS_DIR)/$*                                                    \
	&& ln -s $(SIMULATION_DIR)/* .                                             \
	&& make run                                                                \
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
