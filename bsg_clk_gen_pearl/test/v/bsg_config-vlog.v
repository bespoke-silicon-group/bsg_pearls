
config config_vlog;
    design testlib.testbench;

    instance testbench.gateway liblist testlib vloglib;
    instance testbench.harness liblist testlib vloglib;
    instance testbench.harness.dut.chip liblist vloglib;
    default liblist vloglib;
endconfig

