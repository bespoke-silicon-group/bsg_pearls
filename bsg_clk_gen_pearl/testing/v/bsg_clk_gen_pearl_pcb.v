`timescale 1ps/1ps
`include "bsg_defines.v"

module bsg_clk_gen_pearl_pcb

 import bsg_clk_gen_pearl_pkg::*;

 #(parameter `BSG_INV_PARAM(toplevel_tag_els_p)
  ,parameter `BSG_INV_PARAM(toplevel_tag_max_payload_width_p)
  ,parameter `BSG_INV_PARAM(toplevel_tag_node_id_offset_p)
  ,parameter `BSG_INV_PARAM(toplevel_ds_width_p)
  ,parameter `BSG_INV_PARAM(toplevel_num_adgs_p)
  )

  ();

  logic ext_clk, async_clk_gen_disable;
  logic tag_clk, tag_data, tag_en;

  bsg_clk_gen_pearl
 #(.ds_width_p(toplevel_ds_width_p)
  ,.num_adgs_p(toplevel_num_adgs_p)
  ,.tag_els_p(toplevel_tag_els_p)
  ,.tag_lg_width_p(`BSG_SAFE_CLOG2(toplevel_tag_max_payload_width_p+1))
  ,.tag_local_els_p(bsg_clk_gen_pearl_tag_local_els_gp)
  ) IC
  (.ext_clk_i(ext_clk)
  ,.async_output_disable_i(async_clk_gen_disable)

  ,.tag_clk_i(tag_clk)
  ,.tag_data_i(tag_data & tag_en)
  ,.tag_node_id_offset_i((`BSG_SAFE_CLOG2(toplevel_tag_els_p))'(toplevel_tag_node_id_offset_p))

  ,.clk_o()
  ,.clk_monitor_o()
  );

  bsg_clk_gen_pearl_testbench GW
  (.ext_clk_o(ext_clk)
  ,.async_clk_gen_disable_o(async_clk_gen_disable)

  ,.tag_clk_o(tag_clk)
  ,.tag_data_o(tag_data)
  ,.tag_en_o(tag_en)
  
  ,.watch_clk_i(bsg_clk_gen_pearl_pcb.IC.clk_o)
  );

endmodule
