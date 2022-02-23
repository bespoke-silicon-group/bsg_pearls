
`include "bsg_defines.v"

module bsg_clk_gen_pearl
 import bsg_tag_pkg::*;
 import bsg_clk_gen_pkg::*;
 #(parameter `BSG_INV_PARAM(ds_width_p)
   , parameter `BSG_INV_PARAM(num_adgs_p)
   , parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(tag_local_els_p)
   )
  (input                                    ext_clk_i
   , input                                  async_output_disable_i

   , input                                  tag_clk_i
   , input                                  tag_data_i
   , input [`BSG_SAFE_CLOG2(tag_els_p)-1:0] tag_node_id_offset_i

   , output logic                           clk_o
   // downsampled clock, for viewing off-chip
   , output logic                           clk_monitor_o
   );

  bsg_clk_gen_pearl_tag_lines_s tag_lines_lo;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(tag_local_els_p)
     ,.lg_width_p(tag_lg_width_p)
     )
   btm
    (.clk_i(tag_clk_i)
     ,.data_i(tag_data_i)
     ,.node_id_offset_i(tag_node_id_offset_i)
     ,.clients_o(tag_lines_lo)
     );

  logic async_reset_lo;
  bsg_tag_client_unsync
   #(.width_p(1))
   btc_async_reset
    (.bsg_tag_i(tag_lines_lo.async_reset)
     ,.data_async_r_o(async_reset_lo)
     );

  logic [1:0] clk_select_lo;
  bsg_tag_client_unsync
   #(.width_p(2))
   btc_clk_select
    (.bsg_tag_i(tag_lines_lo.sel)
     ,.data_async_r_o(clk_select_lo)
     );

  wire [1:0] clk_select_n = async_output_disable_i ? 2'b11 : clk_select_lo;

  logic clk_lo;
  bsg_clk_gen
   #(.downsample_width_p(ds_width_p)
     ,.num_adgs_p(num_adgs_p)
     ,.version_p(2)
     )
   clk_gen_inst
    (.bsg_osc_tag_i(tag_lines_lo.osc)
     ,.bsg_osc_trigger_tag_i(tag_lines_lo.osc_trigger)
     ,.bsg_ds_tag_i(tag_lines_lo.ds)
     ,.async_osc_reset_i(async_reset_lo)
     ,.ext_clk_i(ext_clk_i)
     ,.select_i(clk_select_n)
     ,.clk_o(clk_lo)
     );

  bsg_clk_gen_pearl_monitor
   monitor
    (.bsg_tag_i(tag_lines_lo.monitor_reset)
     ,.clk_i(clk_lo)
     ,.clk_monitor_o(clk_monitor_o)
     );

  assign clk_o = clk_lo;

endmodule

