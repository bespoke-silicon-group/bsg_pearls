### filelist.tcl

#-------------------------------------------------------------------------------
# Do NOT arbitrarily change the order of files. Some module and macro
# definitions may be needed by the subsequent files
#-------------------------------------------------------------------------------

set bsg_designs_target_dir  $::env(BSG_DESIGNS_TARGET_DIR)
set basejump_stl_dir        $::env(BASEJUMP_STL_DIR)

set SVERILOG_INCLUDE_PATHS [join "
  $basejump_stl_dir/bsg_clk_gen
  $basejump_stl_dir/bsg_misc
  $basejump_stl_dir/bsg_tag
"]

set SVERILOG_PACKAGE_FILES [join "
  $basejump_stl_dir/bsg_tag/bsg_tag_pkg.v
  $bsg_designs_target_dir/bsg_clk_gen_pearl_pkg.v
"]

set SVERILOG_SOURCE_FILES [join "
  $SVERILOG_PACKAGE_FILES
  $basejump_stl_dir/bsg_async/bsg_launch_sync_sync.v
  $basejump_stl_dir/bsg_async/bsg_sync_sync.v
  $basejump_stl_dir/bsg_clk_gen/bsg_clk_gen.v
  $basejump_stl_dir/bsg_clk_gen/bsg_clk_gen_osc.v
  $basejump_stl_dir/bsg_misc/bsg_buf.v
  $basejump_stl_dir/bsg_misc/bsg_counter_clock_downsample.v
  $basejump_stl_dir/bsg_misc/bsg_dff.v
  $basejump_stl_dir/bsg_misc/bsg_dff_en.v
  $basejump_stl_dir/bsg_misc/bsg_dff_reset_en.v
  $basejump_stl_dir/bsg_misc/bsg_dff_async_reset.v
  $basejump_stl_dir/bsg_misc/bsg_mux.v
  $basejump_stl_dir/bsg_misc/bsg_mux2_gatestack.v
  $basejump_stl_dir/bsg_misc/bsg_muxi2_gatestack.v
  $basejump_stl_dir/bsg_misc/bsg_nand.v
  $basejump_stl_dir/bsg_misc/bsg_nor3.v
  $basejump_stl_dir/bsg_misc/bsg_reduce.v
  $basejump_stl_dir/bsg_misc/bsg_strobe.v
  $basejump_stl_dir/bsg_misc/bsg_xnor.v
  $basejump_stl_dir/bsg_misc/bsg_counter_clear_up.v
  $basejump_stl_dir/bsg_tag/bsg_tag_master_decentralized.v
  $basejump_stl_dir/bsg_tag/bsg_tag_client.v
  $basejump_stl_dir/bsg_tag/bsg_tag_client_unsync.v
  $bsg_designs_target_dir/bsg_clk_gen_pearl_lfsr_div30.v
  $bsg_designs_target_dir/bsg_clk_gen_pearl_monitor_clk_buf.v
  $bsg_designs_target_dir/bsg_clk_gen_pearl_monitor.v
  $bsg_designs_target_dir/bsg_clk_gen_pearl.v
"]

