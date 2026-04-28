

`include "bsg_pearls.svh"

module bsg_sdr_link_pearl
 import bsg_sdr_link_pearl_pkg::*;
 import bsg_link_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(core_data_width_p)
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

   , input [core_data_width_p-1:0]          core_data_i
   , input                                  core_v_i
   , output logic                           core_ready_and_o

   , output logic [core_data_width_p-1:0]   core_data_o
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
  `declare_bsg_tag_client_unsync(sdr_token_reset, tag_lines_lo.sdr.token_reset, 1);
  `declare_bsg_tag_client_sync(sdr_downstream_reset, tag_lines_lo.sdr.downstream_reset, 1, core_clk_i);
  `declare_bsg_tag_client_unsync(sdr_downlink_reset, tag_lines_lo.sdr.downlink_reset, 1);
  `declare_bsg_tag_client_sync(sdr_uplink_reset, tag_lines_lo.sdr.uplink_reset, 1, core_clk_i);

  `declare_bsg_tag_client_unsync(async_link_i_disable, tag_lines_lo.link_i_disable, 1);
  `declare_bsg_tag_client_unsync(async_link_o_disable, tag_lines_lo.link_o_disable, 1);

  logic [sdr_data_width_p-1:0] sdr_data_li;
  logic sdr_v_li, sdr_ready_and_lo;
  logic [sdr_data_width_p-1:0] sdr_data_lo;
  logic sdr_v_lo, sdr_yumi_li;
  bsg_link_sdr
   #(.width_p(sdr_data_width_p)
     ,.lg_fifo_depth_p(sdr_lg_fifo_depth_p)
     ,.lg_credit_to_token_decimation_p(sdr_lg_credit_to_token_decimation_p)
     )
   sdr
    (.core_clk_i(core_clk_i)
     ,.core_uplink_reset_i(sdr_uplink_reset_data_r_lo)
     ,.core_downstream_reset_i(sdr_downlink_reset_data_async_r_lo)
     ,.async_downlink_reset_i(sdr_downlink_reset_data_async_r_lo)

     ,.async_token_reset_i(sdr_token_reset_data_async_r_lo)

     ,.core_data_i(sdr_data_li)
     ,.core_v_i(sdr_v_li)
     ,.core_ready_o(sdr_ready_and_lo)

     ,.core_data_o(sdr_data_lo)
     ,.core_v_o(sdr_v_lo)
     ,.core_yumi_i(sdr_yumi_li)

     ,.*
     );

  if (core_data_width_p > sdr_data_width_p)
    begin : narrow
      bsg_parallel_in_serial_out
       #(.width_p(sdr_data_width_p), .els_p(core_data_width_p/sdr_data_width_p))
       piso
        (.clk_i(core_clk_i)
         ,.reset_i(core_reset_i)

         ,.data_i(core_data_i)
         ,.valid_i(core_v_i)
         ,.ready_and_o(core_ready_and_o)

         ,.data_o(sdr_data_li)
         ,.valid_o(sdr_v_li)
         ,.yumi_i(sdr_ready_and_lo & sdr_v_li)
         );

	  logic sdr_ready_and_li;
	  bsg_serial_in_parallel_out_full
       #(.width_p(sdr_data_width_p), .els_p(core_data_width_p/sdr_data_width_p))
  	   sipo
		(.clk_i(core_clk_i)
	     ,.reset_i(core_reset_i)

		 ,.data_i(sdr_data_lo)
		 ,.v_i(sdr_v_lo)
		 ,.ready_and_o(sdr_ready_and_li)

		 ,.data_o(core_data_o)
		 ,.v_o(core_v_o)
		 ,.yumi_i(core_ready_and_i & core_v_o)
		 );
	  assign sdr_yumi_li = sdr_ready_and_li & sdr_v_lo;
    end
  else
	begin : widen
       logic sdr_ready_and_li;
       bsg_parallel_in_serial_out
        #(.width_p(core_data_width_p), .els_p(sdr_data_width_p/core_data_width_p))
        piso
         (.clk_i(core_clk_i)
          ,.reset_i(core_reset_i)
 
          ,.data_i(sdr_data_lo)
          ,.valid_i(sdr_v_lo)
          ,.ready_and_o(sdr_ready_and_li)    
     
          ,.data_o(core_data_o)
          ,.valid_o(core_v_o)
          ,.yumi_i(core_ready_and_i & core_v_o)
          );
       assign sdr_yumi_li = sdr_ready_and_li & sdr_v_lo;
 
       bsg_serial_in_parallel_out_full
        #(.width_p(core_data_width_p), .els_p(sdr_data_width_p/core_data_width_p))
        sipo
         (.clk_i(core_clk_i)
          ,.reset_i(core_reset_i)

          ,.data_i(core_data_i)
          ,.v_i(core_v_i)
          ,.ready_and_o(core_ready_and_o & core_v_i)
 
          ,.data_o(sdr_data_li)
          ,.v_o(sdr_v_li)
          ,.yumi_i(sdr_ready_and_lo & sdr_v_li)
          );
	end

endmodule

`BSG_ABSTRACT_MODULE(bsg_sdr_link_pearl)

