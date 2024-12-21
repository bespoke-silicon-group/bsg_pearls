
`include "bsg_defines.sv"

module bsg_chip
 import bsg_chip_pkg::*;
  (input                                    core_clk_i
   , input                                  core_reset_i

   , input                                  tag_clk_i
   , input                                  tag_data_i
   , input [tag_lg_clients_gp-1:0]          tag_node_id_offset_i

   , output logic                           link_clk_o
   , output logic [sdr_data_width_gp-1:0]   link_data_o
   , output logic                           link_v_o
   , input                                  link_token_i
   , output logic                           async_link_o_disable_o

   , input                                  link_clk_i
   , input [sdr_data_width_gp-1:0]          link_data_i
   , input                                  link_v_i
   , output logic                           link_token_o
   , output logic                           async_link_i_disable_o

   , input [core_data_width_gp-1:0]         core_data_i
   , input                                  core_v_i
   , output logic                           core_ready_and_o

   , output logic [core_data_width_gp-1:0]  core_data_o
   , output logic                           core_v_o
   , input                                  core_ready_and_i
   );

`ifdef POSTSYNTH_SIM
  bsg_sdr_link_pearl_synth
`else
  bsg_sdr_link_pearl
   #(.tag_els_p(tag_els_gp)
     ,.tag_lg_width_p(tag_lg_width_gp)
     ,.core_data_width_p(core_data_width_gp)
     ,.sdr_data_width_p(sdr_data_width_gp)
     ,.sdr_lg_fifo_depth_p(sdr_lg_fifo_depth_gp)
     ,.sdr_lg_credit_to_token_decimation_p(sdr_lg_credit_to_token_decimation_gp)
     )
`endif
   chip
    (.*);
   

endmodule

