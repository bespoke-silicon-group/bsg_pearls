
`include "bsg_chip_defines.svh"

module wrapper
 import bsg_chip_pkg::*;
 #(parameter ds_width_p = ds_width_gp
   , parameter num_taps_p = num_taps_gp
   , parameter tag_els_p = tag_els_gp
   , parameter tag_lg_width_p = tag_lg_width_gp
   , localparam tag_lg_els_lp = `BSG_SAFE_CLOG2(tag_els_p)
   )
  (input                                    ext_clk_i
   , input                                  async_output_disable_i

   , input                                  tag_clk_i
   , input                                  tag_data_i
   , input [tag_lg_els_lp-1:0]              tag_node_id_offset_i

   , output logic                           clk_o
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

  if (1'b0
      || (ds_width_p != ds_width_gp)
      || (num_taps_p != num_taps_gp)
      || (tag_els_p != tag_els_gp)
      || (tag_lg_width_p != tag_lg_width_gp)
      ) $error("Must not override parameters for bsg_chip!");

endmodule

