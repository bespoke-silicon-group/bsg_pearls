database -open dump -shm
probe -create testbench.harness.dut.chip -depth all -all -shm -database dump
run
