
config config_hard;
    design testlib.testbench;

    instance testbench.gateway liblist testlib vloglib;
    instance testbench.harness liblist testlib vloglib;
    instance testbench.harness.dut.chip liblist vpdklib hardlib vloglib;
    default liblist vpdklib hardlib vloglib;
endconfig

