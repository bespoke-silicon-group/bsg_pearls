
`include "bsg_pearls.svh"

module bsg_clk_gen_pearl
 import bsg_tag_pkg::*;
 import bsg_clk_gen_pearl_pkg::*;
 #(parameter `BSG_INV_PARAM(ds_width_p)
   , parameter `BSG_INV_PARAM(num_taps_p)
   , parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , localparam tag_lg_els_lp = `BSG_SAFE_CLOG2(tag_els_p)
   )
  (input                                    ext_clk_i
   , input                                  async_output_disable_i

   , input                                  tag_clk_i
   , input                                  tag_data_i
   , input [tag_lg_els_lp-1:0]              tag_node_id_offset_i

   , output logic                           clk_o
   // downsampled clock, for viewing off-chip
   , output logic                           clk_monitor_o
   );

  bsg_clk_gen_pearl_tag_lines_s tag_lines_lo;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(bsg_clk_gen_pearl_tag_local_els_gp)
     ,.lg_width_p(tag_lg_width_p)
     )
   btm
    (.clk_i(tag_clk_i)
     ,.data_i(tag_data_i)
     ,.node_id_offset_i(tag_node_id_offset_i)
     ,.clients_o(tag_lines_lo)
     );

  `declare_bsg_tag_client_unsync(async_reset, tag_lines_lo.async_reset, 1);
  `declare_bsg_tag_client_unsync(clk_select, tag_lines_lo.sel, 2);
  `declare_bsg_tag_client_sync(mon_reset, tag_lines_lo.monitor_reset, 1, clk_o);

  logic [1:0] clk_select_n;
  bsg_mux
   #(.width_p($bits(bsg_clk_gen_pearl_sel_e)), .els_p(2), .harden_p(1))
   disable_mux
    (.data_i({e_bsg_clk_gen_pearl_sel_disable, clk_select_data_async_r_lo})
     ,.sel_i(async_output_disable_i)
     ,.data_o(clk_select_n)
     );

  logic clk_lo;
  bsg_clk_gen_v3
   #(.downsample_width_p(ds_width_p)
     ,.num_taps_p(num_taps_p)
     )
   clk_gen_inst
    (.bsg_osc_tag_i(tag_lines_lo.osc)
     ,.bsg_osc_trigger_tag_i(tag_lines_lo.osc_trigger)
     ,.bsg_ds_tag_i(tag_lines_lo.ds)
     ,.async_osc_reset_i(async_reset_data_async_r_lo)
     ,.ext_clk_i(ext_clk_i)
     ,.select_i(clk_select_n)
     ,.clk_o(clk_lo)
     );

  bsg_clk_gen_pearl_monitor
   monitor
    (.clk_i(clk_lo)
     ,.reset_i(mon_reset_data_r_lo)
     ,.monitor_o(clk_monitor_o)
     );

  bsg_clkbuf
   #(.width_p(1), .harden_p(1))
   obuf
    (.i(clk_lo)
     ,.o(clk_o)
     );

  logic test_BSG_DONT_TOUCH_clk, test_BSG_DONT_TOUCH_n, test_BSG_DONT_TOUCH_r;
  bsg_dff
   #(.width_p(1))
   test_BSG_DONT_TOUCH_reg
    (.clk_i(test_BSG_DONT_TOUCH_clk)
     ,.data_i(test_BSG_DONT_TOUCH_n)
     ,.data_o(test_BSG_DONT_TOUCH_r)
     );

  logic test_BSG_NO_CLOCK_GATE_clk, test_BSG_NO_CLOCK_GATE_n, test_BSG_NO_CLOCK_GATE_r;
  bsg_dff
   #(.width_p(1))
   test_BSG_NO_CLOCK_GATE_reg
    (.clk_i(test_BSG_NO_CLOCK_GATE_clk)
     ,.data_i(test_BSG_NO_CLOCK_GATE_n)
     ,.data_o(test_BSG_NO_CLOCK_GATE_r)
     );

  logic test_BSG_UNGROUP_clk, test_BSG_UNGROUP_n, test_BSG_UNGROUP_r;
  bsg_dff
   #(.width_p(1))
   test_BSG_UNGROUP_reg
    (.clk_i(test_BSG_UNGROUP_clk)
     ,.data_i(test_BSG_UNGROUP_n)
     ,.data_o(test_BSG_UNGROUP_r)
     );

  logic test_BSG_RESIZE_OK_clk, test_BSG_RESIZE_OK_n, test_BSG_RESIZE_OK_r;
  bsg_dff
   #(.width_p(1))
   test_BSG_RESIZE_OK_reg
    (.clk_i(test_BSG_RESIZE_OK_clk)
     ,.data_i(test_BSG_RESIZE_OK_n)
     ,.data_o(test_BSG_RESIZE_OK_r)
     );

  logic test_BSG_TIMING_DISABLE_clk, test_BSG_TIMING_DISABLE_n, test_BSG_TIMING_DISABLE_r;
  bsg_dff
   #(.width_p(1))
   test_BSG_TIMING_DISABLE_reg
    (.clk_i(test_BSG_TIMING_DISABLE_clk)
     ,.data_i(test_BSG_TIMING_DISABLE_n)
     ,.data_o(test_BSG_TIMING_DISABLE_r)
     );

endmodule

