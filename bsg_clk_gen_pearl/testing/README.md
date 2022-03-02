# Bsg_clk_gen_pearl Testbench User Guide

## Run RTL Simulation
```
cd bsg_clk_gen_pearl/testing/rtl
make
```
## Run RTL OSC Sweep
```
cd bsg_clk_gen_pearl/testing/clk_gen_sweep/rtl
make
```
## Use Testbench on ASIC
1. Update `bsg_clk_gen_pearl/tcl/filelist.tcl` and `bsg_clk_gen_pearl/tcl/parameters.tcl` accordingly
2. Create a new version of `bsg_clk_gen_pearl/testing/v/bsg_clk_gen_pearl_pcb.v`, in which the DUT ASIC should be attached to the testbench
*Note that the watch_clk bind pin should be up-to-date
3. Update `bsg_clk_gen_pearl/testing/tcl/filelist.tcl` accordingly
4. Update the following variables in `bsg_clk_gen_pearl/testing/rtl/Makefile`: `BSG_TOP_SIM_MODULE`, `BSG_CHIP_INSTANCE_PATH`, `BSG_OSC_BASE_DELAY` and `BSG_OSC_GRANULARITY`
