
`include "bsg_noc_links.svh"

module bsg_ddr_link_pearl
 import bsg_dmc_pkg::*;
 import bsg_cache_pkg::*;
 import bsg_noc_pkg::*;
 import bsg_link_pkg::*;
 import bsg_link_pearl_pkg::*;
 import bsg_clk_gen_pearl_pkg::*;
 #(`BSG_INV_PARAM(tag_els_p)
   , `BSG_INV_PARAM(tag_lg_width_p)
   , `BSG_INV_PARAM(core_data_width_p)
   , `BSG_INV_PARAM(io_data_width_p)
   , `BSG_INV_PARAM(clk_gen_ds_width_p)
   , `BSG_INV_PARAM(clk_gen_num_taps_p)
   , `BSG_INV_PARAM(ddr_lg_fifo_depth_p)
   , `BSG_INV_PARAM(ddr_lg_credit_to_token_decimation_p)
   , `BSG_INV_PARAM(ddr_use_extra_data_bit_p)
   )
  (input                                                       clk_i
   , input                                                     reset_i

   // Tag Interface
   , input                                                     tag_clk_i
   , input                                                     tag_data_i
   , input [`BSG_SAFE_CLOG2(tag_els_p)-1:0]                    tag_node_id_offset_i

   , input [core_data_width_p-1:0]                             core_data_i
   , input                                                     core_v_i
   , output logic                                              core_ready_and_o

   , output logic [core_data_width_p-1:0]                      core_data_o
   , output logic                                              core_v_o
   , input                                                     core_yumi_i

   , input                                                     ext_io_clk_i
   , output logic                                              io_clk_monitor_o
   , input                                                     async_clk_output_disable_i

   , output logic                                              io_link_clk_o
   , output logic [io_data_width_p-1:0]                        io_link_data_o
   , output logic                                              io_link_v_o
   , input                                                     io_link_token_i

   , input                                                     io_link_clk_i
   , input [io_data_width_p-1:0]                               io_link_data_i
   , input                                                     io_link_v_i
   , output logic                                              io_link_token_o
   );

  wire [`BSG_SAFE_CLOG2(tag_els_p)-1:0] clk_gen_tag_node_offset_li = tag_node_id_offset_i + '0;
  wire [`BSG_SAFE_CLOG2(tag_els_p)-1:0] ddr_tag_node_offset_li = clk_gen_tag_node_offset_li + bsg_clk_gen_pearl_tag_local_els_gp;

  logic io_clk_lo;
  bsg_clk_gen_pearl
   #(.ds_width_p(clk_gen_ds_width_p)
     ,.num_taps_p(clk_gen_num_taps_p)
     ,.tag_els_p(tag_els_p)
     ,.tag_lg_width_p(tag_lg_width_p)
     )
   io_clk_gen
    (.ext_clk_i(ext_io_clk_i)
     ,.async_output_disable_i(async_clk_output_disable_i)

     ,.tag_clk_i(tag_clk_i)
     ,.tag_data_i(tag_data_i)
     ,.tag_node_id_offset_i(clk_gen_tag_node_offset_li)

     ,.clk_o(io_clk_lo)
     ,.clk_monitor_o(io_clk_monitor_o)
     );

  bsg_link_ddr_tag_lines_s tag_lines_lo;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(tag_ddr_local_els_gp)
     ,.lg_width_p(tag_lg_width_p)
     )
   btm
    (.clk_i(tag_clk_i)
     ,.data_i(tag_data_i)
     ,.node_id_offset_i(ddr_tag_node_offset_li)
     ,.clients_o(tag_lines_lo)
     );

  logic ddr_uplink_reset_li;
  bsg_tag_client
   #(.width_p(1))
   btc_ddr_uplink_reset
    (.bsg_tag_i(tag_lines_lo.io_uplink_reset)
     ,.recv_clk_i(io_clk_lo)
     ,.recv_new_r_o()
     ,.recv_data_r_o(ddr_uplink_reset_li)
     );

  logic ddr_async_token_reset_li;
  bsg_tag_client_unsync
   #(.width_p(1))
   btc_async_token_reset
    (.bsg_tag_i(tag_lines_lo.io_async_token_reset)
     ,.data_async_r_o(ddr_async_token_reset_li)
     );

  logic core_downlink_reset_li;
  bsg_tag_client
   #(.width_p(1))
   btc_downlink_reset
    (.bsg_tag_i(tag_lines_lo.core_downlink_reset)
     ,.recv_clk_i(clk_i)
     ,.recv_new_r_o()
     ,.recv_data_r_o(core_downlink_reset_li)
     );

  logic core_uplink_reset_li;
  bsg_tag_client
   #(.width_p(1))
   btc_core_uplink_reset
    (.bsg_tag_i(tag_lines_lo.core_uplink_reset)
     ,.recv_clk_i(clk_i)
     ,.recv_new_r_o()
     ,.recv_data_r_o(core_uplink_reset_li)
     );

  logic ddr_downlink_reset_unsync_li;
  bsg_tag_client
   #(.width_p(1))
   btc_downlink_reset_unsync
    (.bsg_tag_i(tag_lines_lo.io_downlink_reset)
     ,.recv_clk_i(io_clk_lo)
     ,.recv_new_r_o()
     ,.recv_data_r_o(ddr_downlink_reset_unsync_li)
     );

  logic ddr_downlink_reset_li;
  bsg_sync_sync
   #(.width_p(1))
   bss
    (.oclk_i(io_link_clk_i)
     ,.iclk_data_i(ddr_downlink_reset_unsync_li)
     ,.oclk_data_o(ddr_downlink_reset_li)
     );

  logic [io_data_width_p-1:0] io_link_data_lo;
  logic io_link_clk_lo, io_link_v_lo;
  bsg_link_ddr_upstream
   #(.width_p(core_data_width_p)
     ,.channel_width_p(io_data_width_p)
     ,.lg_fifo_depth_p(ddr_lg_fifo_depth_p)
     ,.lg_credit_to_token_decimation_p(ddr_lg_credit_to_token_decimation_p)
     ,.use_extra_data_bit_p(ddr_use_extra_data_bit_p)
     )
   uplink
    (.core_clk_i(clk_i)
     ,.core_link_reset_i(core_uplink_reset_li)

     ,.core_data_i(core_data_i)
     ,.core_v_i(core_v_i)
     ,.core_ready_and_o(core_ready_and_o)

     ,.io_clk_i(io_clk_lo)
     ,.io_link_reset_i(ddr_uplink_reset_li)
     ,.async_token_reset_i(ddr_async_token_reset_li)

     ,.io_clk_r_o(io_link_clk_lo)
     ,.io_data_r_o(io_link_data_lo)
     ,.io_v_r_o(io_link_v_lo)
     ,.token_clk_i(io_link_token_i)
     );

  logic [io_data_width_p-1:0] io_link_data_li;
  logic io_link_clk_li, io_link_v_li;
  bsg_link_ddr_downstream 
   #(.width_p(core_data_width_p)
     ,.channel_width_p(io_data_width_p)
     ,.lg_fifo_depth_p(ddr_lg_fifo_depth_p)
     ,.lg_credit_to_token_decimation_p(ddr_lg_credit_to_token_decimation_p)
     ,.use_extra_data_bit_p(ddr_use_extra_data_bit_p)
     )
   downlink
    (.core_clk_i(clk_i)
     ,.core_link_reset_i(core_downlink_reset_li)

     ,.core_data_o(core_data_o)
     ,.core_v_o(core_v_o)
     ,.core_yumi_i(core_yumi_i)

     ,.io_link_reset_i(ddr_downlink_reset_li)

     ,.io_clk_i(io_link_clk_li)
     ,.io_data_i(io_link_data_li)
     ,.io_v_i(io_link_v_li)
     ,.core_token_r_o(io_link_token_o)
     );

  bsg_link_delay_line
   idelay
    (.tag_clk_i(tag_clk_i)
     ,.tag_lines_i(tag_lines_lo.idelay)
     ,.i({io_link_clk_i, io_link_v_i, io_link_data_i})
     ,.o({io_link_clk_li, io_link_v_li, io_link_data_li})
     );

  bsg_link_delay_line
   odelay
    (.tag_clk_i(tag_clk_i)
     ,.tag_lines_i(tag_lines_lo.odelay)
     ,.i({io_link_clk_lo, io_link_v_lo, io_link_data_lo})
     ,.o({io_link_clk_o, io_link_v_o, io_link_data_o})
     );

endmodule

