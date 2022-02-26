#------------------------------------------------------------
# Do NOT arbitrarily change the order of files. Some module
# and macro definitions may be needed by the subsequent files
#------------------------------------------------------------

set bsg_designs_target_dir $::env(BSG_DESIGNS_TARGET_DIR)
set basejump_stl_dir       $::env(BASEJUMP_STL_DIR)

set TESTING_INCLUDE_PATHS [join "
  $basejump_stl_dir/bsg_misc
  $basejump_stl_dir/bsg_tag
"]

set TESTING_PACKAGE_FILES [join "
  $basejump_stl_dir/bsg_tag/bsg_tag_pkg.v
  $bsg_designs_target_dir/bsg_clk_gen_pearl_pkg.v
"]

set TESTING_SOURCE_FILES [join "
  $TESTING_PACKAGE_FILES
  $basejump_stl_dir/bsg_clk_gen/bsg_nonsynth_clk_watcher.v
  $basejump_stl_dir/bsg_dataflow/bsg_one_fifo.v
  $basejump_stl_dir/bsg_dataflow/bsg_parallel_in_serial_out.v
  $basejump_stl_dir/bsg_dataflow/bsg_two_fifo.v
  $basejump_stl_dir/bsg_fsb/bsg_fsb_node_trace_replay.v
  $basejump_stl_dir/bsg_mem/bsg_mem_1r1w.v
  $basejump_stl_dir/bsg_mem/bsg_mem_1r1w_synth.v
  $basejump_stl_dir/bsg_misc/bsg_dff_en.v
  $basejump_stl_dir/bsg_misc/bsg_dff_reset.v
  $basejump_stl_dir/bsg_tag/bsg_tag_trace_replay.v
  $basejump_stl_dir/bsg_test/bsg_nonsynth_clock_gen.v
  $basejump_stl_dir/bsg_test/bsg_nonsynth_reset_gen.v
  $bsg_designs_target_dir/testing/v/bsg_clk_gen_pearl_testbench.v
  $bsg_designs_target_dir/testing/v/bsg_clk_gen_pearl_pcb.v
"]

