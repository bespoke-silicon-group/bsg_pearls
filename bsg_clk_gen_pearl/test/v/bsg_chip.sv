
`include "bsg_chip_defines.svh"

module bsg_chip
 import bsg_chip_pkg::*;
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

  bsg_clk_gen_pearl
   #(.ds_width_p(ds_width_p)
     ,.num_taps_p(num_taps_p)
     ,.tag_els_p(tag_els_p)
     ,.tag_lg_width_p(tag_lg_width_p)
     )
   chip
    (.*);

endmodule

`BSG_ABSTRACT_MODULE(bsg_chip)

