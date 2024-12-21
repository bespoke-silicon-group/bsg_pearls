

`include "bsg_defines.sv"

module bsg_sdr_link_pearl
 import bsg_link_pearl_pkg::*;
 import bsg_link_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(sdr_data_width_p)
   , parameter `BSG_INV_PARAM(sdr_lg_fifo_depth_p)
   , parameter `BSG_INV_PARAM(sdr_lg_credit_to_token_decimation_p)
   , localparam tag_lg_els_lp = `BSG_SAFE_CLOG2(tag_els_p)
   )
  (input                                    core_clk_i
   , input                                  core_reset_i

   , input                                  tag_clk_i
   , input                                  tag_data_i
   , input [tag_lg_els_lp-1:0]              tag_node_id_offset_i

   , output logic                           link_clk_o
   , output logic [sdr_data_width_p-1:0]    link_data_o
   , output logic                           link_v_o
   , input                                  link_token_i
   , output logic                           async_link_o_disable_o

   , input                                  link_clk_i
   , input [sdr_data_width_p-1:0]           link_data_i
   , input                                  link_v_i
   , output logic                           link_token_o
   , output logic                           async_link_i_disable_o

   , input [sdr_data_width_p-1:0]           core_data_i
   , input                                  core_v_i
   , output logic                           core_ready_and_o

   , output logic [sdr_data_width_p-1:0]    core_data_o
   , output logic                           core_v_o
   , input                                  core_ready_and_i
   );

  wire [tag_lg_els_lp-1:0] sdr_tag_node_offset_li = tag_node_id_offset_i + '0;

  bsg_sdr_link_pearl_tag_lines_s tag_lines_lo;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(bsg_sdr_link_pearl_tag_local_els_gp)
     ,.lg_width_p(tag_lg_width_p)
     )
   btm
    (.clk_i(tag_clk_i)
     ,.data_i(tag_data_i)
     ,.node_id_offset_i(sdr_tag_node_offset_li)
     ,.clients_o(tag_lines_lo)
     );
  `declare_bsg_tag_client_unsync(sdr_token_reset_li, tag_lines_lo.sdr.token_reset, 1);
  `declare_bsg_tag_client(sdr_downstream_reset_li, tag_lines_lo.sdr.downstream_reset, 1, core_clk_i);
  `declare_bsg_tag_client_unsync(sdr_downlink_reset_li, tag_lines_lo.sdr.downlink_reset, 1);
  `declare_bsg_tag_client(sdr_uplink_reset_li, tag_lines_lo.sdr.uplink_reset, 1, core_clk_i);

  `declare_bsg_tag_client_unsync(async_link_i_disable_o, tag_lines_lo.link_i_disable, 1);
  `declare_bsg_tag_client_unsync(async_link_o_disable_o, tag_lines_lo.link_o_disable, 1);

  bsg_link_sdr
   #(.width_p(sdr_data_width_p)
     ,.lg_fifo_depth_p(sdr_lg_fifo_depth_p)
     ,.lg_credit_to_token_decimation_p(sdr_lg_credit_to_token_decimation_p)
     )
   sdr
    (.core_clk_i(core_clk_i)
     ,.core_uplink_reset_i(sdr_uplink_reset_li)
     ,.core_downstream_reset_i(sdr_downstream_reset_li)
     ,.async_downlink_reset_i(sdr_downlink_reset_li)
     ,.async_token_reset_i(sdr_token_reset_li)

     ,.core_data_i(core_data_i)
     ,.core_v_i(core_v_i)
     ,.core_ready_and_o(core_ready_and_o)

     ,.core_data_o(core_data_o)
     ,.core_v_o(core_v_o)
     ,.core_yumi_i(core_ready_and_i & core_v_o)

     ,.*
     );

endmodule

`BSG_ABSTRACT_MODULE(bsg_sdr_link_pearl)

