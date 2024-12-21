config config_vlog;
    design testlib.testbench;
    default liblist testlib;
    instance testbench.harness.dut.chip liblist vloglib;
endconfig

config config_hard;
    design testlib.testbench;
    default liblist testlib;
    instance testbench.harness.dut.chip liblist pdklib hardlib vloglib;
    // Use version with nonsynth delay
    cell bsg_rp_clk_gen_osc_v3_row use pdklib.bsg_rp_clk_gen_osc_v3_row;
endconfig

