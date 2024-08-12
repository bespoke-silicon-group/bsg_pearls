

`include "bsg_defines.sv"

module bsg_sdr_link_pearl
 import bsg_link_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(sdr_data_width_p)
   , parameter `BSG_INV_PARAM(sdr_lg_fifo_depth_p)
   , parameter `BSG_INV_PARAM(sdr_lg_credit_to_token_decimation_p)
   , parameter core_credit_on_input_p = 0
   , parameter core_credit_on_output_p = 0
   , parameter credit_fifo_els_p = 3
   )
  (input                                    core_clk_i
   , input                                  core_reset_i

   , input                                  tag_clk_i
   , input                                  tag_data_i
   , input [`BSG_SAFE_CLOG2(tag_els_p)-1:0] tag_node_id_offset_i

   , output logic                           link_clk_o
   , output logic [sdr_data_width_p-1:0]    link_data_o
   , output logic                           link_v_o
   , input                                  link_token_i

   , input                                  link_clk_i
   , input [sdr_data_width_p-1:0]           link_data_i
   , input                                  link_v_i
   , output logic                           link_token_o

   , input [sdr_data_width_p-1:0]           core_data_i
   , input                                  core_v_i
   , output logic                           core_credit_or_ready_o

   , output logic [sdr_data_width_p-1:0]    core_data_o
   , output logic                           core_v_o
   , input                                  core_credit_or_ready_i
   );

  wire [`BSG_SAFE_CLOG2(tag_els_p)-1:0] sdr_tag_node_offset_li = tag_node_id_offset_i + '0;

  bsg_link_sdr_tag_lines_s tag_lines_lo;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(bsg_link_sdr_tag_local_els_gp)
     ,.lg_width_p(tag_lg_width_p)
     )
   btm
    (.clk_i(tag_clk_i)
     ,.data_i(tag_data_i)
     ,.node_id_offset_i(sdr_tag_node_offset_li)
     ,.clients_o(tag_lines_lo)
     );

  bsg_tag_client_unsync
   #(.width_p(1))
   btc_token_reset
    (.bsg_tag_i(tag_lines_lo.token_reset)
     ,.data_async_r_o(sdr_token_reset_li)
     );

  bsg_tag_client
   #(.width_p(1))
   btc_downstream_reset
    (.recv_clk_i(core_clk_i)
     ,.recv_new_r_o()
     ,.recv_data_r_o(sdr_downstream_reset_li)
     );

  bsg_tag_client_unsync
   #(.width_p(1))
   btc_downlink_reset
    (.bsg_tag_i(tag_lines_lo.downlink_reset)
     ,.data_async_r_o(sdr_downlink_reset_li)
     );

  bsg_tag_client
   #(.width_p(1))
   btc_uplink_reset
    (.recv_clk_i(core_clk_i)
     ,.recv_new_r_o()
     ,.recv_data_r_o(sdr_uplink_reset_li)
     );

  logic [sdr_data_width_p-1:0] sdr_data_lo;
  logic sdr_v_lo, sdr_ready_and_li;
  logic [sdr_data_width_p-1:0] sdr_data_li;
  logic sdr_v_li, sdr_ready_and_lo;

  if (core_credit_on_input_p)
    begin : coi
      bsg_fifo_1r1w_small_credit_on_input
       #(.width_p(sdr_data_width_p), .els_p(credit_fifo_els_p))
       credit_fifo
        (.clk_i(core_clk_i)
         ,.reset_i(core_reset_i)
         
         ,.data_i(core_data_i)
         ,.v_i(core_v_i)
         ,.credit_o(core_credit_or_ready_o)
         
         ,.data_o(sdr_data_li)
         ,.v_o(sdr_v_li)
         ,.yumi_i(sdr_ready_and_lo & sdr_v_li)
         );
    end
  else
    begin : coi
      assign sdr_data_li = core_data_i;
      assign sdr_v_li = core_v_i;
      assign core_credit_or_ready_o = sdr_ready_and_lo;
    end

  if (core_credit_on_output_p)
    begin : coo
      bsg_fifo_1r1w_small_credit_on_input
       #(.width_p(sdr_data_width_p), .els_p(credit_fifo_els_p))
       credit_fifo
        (.clk_i(core_clk_i)
         ,.reset_i(core_reset_i)
         
         ,.data_i(sdr_data_lo)
         ,.v_i(sdr_v_lo)
         ,.credit_o(sdr_ready_and_li)
         
         ,.data_o(core_data_o)
         ,.v_o(core_v_o)
         ,.yumi_i(core_credit_or_ready_i & core_v_o)
         );
      end
    else
      begin : coo
        assign core_data_o = sdr_data_lo;
        assign core_v_o = sdr_v_lo;
        assign sdr_ready_and_li = core_credit_or_ready_i;
      end

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

     ,.core_data_i(sdr_data_li)
     ,.core_v_i(sdr_v_li)
     ,.core_ready_and_o(sdr_ready_and_lo)

     ,.core_data_o(sdr_data_lo)
     ,.core_v_o(sdr_v_lo)
     ,.core_yumi_i(sdr_ready_and_li & sdr_v_lo)

     ,.*
     );

endmodule

`BSG_ABSTRACT_MODULE(bsg_sdr_link_pearl)

