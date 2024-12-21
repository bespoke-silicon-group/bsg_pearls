
config config_vlog;
    design testbench;
    instance testbench.chip.dut liblist vloglib;
endconfig

config config_hard;
    design testbench;
    instance testbench.chip.dut liblist pdklib hardlib vloglib;
    // Use version with nonsynth delay
    cell bsg_rp_clk_gen_osc_v3_row use pdklib.bsg_rp_clk_gen_osc_v3_row;
endconfig

config config_syn;
    design testbench;
    instance testbench.chip.dut liblist pdklib synlib;
    // Use version with nonsynth delay
    cell bsg_rp_clk_gen_osc_v3_row use pdklib.bsg_rp_clk_gen_osc_v3_row;
endconfig

