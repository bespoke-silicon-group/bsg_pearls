
`include "bsg_chip_defines.svh"

module bsg_chip_harness
 import bsg_chip_pkg::*;
 import bsg_tag_pkg::*;
  (
   input bit gateway_clk_i
   , input bit gateway_reset_i
   , input bit gateway_tag_clk_i
   , input bit gateway_tag_en_i
   , input bit gateway_tag_data_i
   , input bit [tag_lg_clients_gp-1:0] gateway_tag_node_id_offset_i
   , input bit [gateway_tag_local_els_gp-1:0][$bits(bsg_tag_s)-1:0] gateway_tag_lines_i

   , input bit [asic_num_clocks_gp-1:0] asic_clk_i
   , input bit asic_tag_clk_i
   , input bit asic_tag_en_i
   , input bit asic_tag_data_i
   , input bit [tag_lg_clients_gp-1:0] asic_tag_node_id_offset_i
   , input bit [asic_tag_local_els_gp-1:0][$bits(bsg_tag_s)-1:0] mirror_tag_lines_i

   , input bit test_clk_i
   , input bit test_reset_i
   , input bit [test_rom_payload_width_gp-1:0] test_data_i
   , input bit test_v_i
   , output bit test_yumi_o

   , output bit [test_rom_payload_width_gp-1:0] test_data_o
   , output bit test_v_o
   , input bit test_ready_and_i

   , input bit startup_i
   , input bit tag_done_i
   , input bit tag_error_i
   , input bit test_done_i
   , input bit test_error_i
   );

  logic ext_clk_li, async_output_disable_li;
  logic tag_clk_li, tag_data_li;
  logic [tag_lg_clients_gp-1:0] tag_node_id_offset_li;
  logic clk_lo, clk_monitor_lo;
  bsg_chip
   #(.ds_width_p(ds_width_gp)
     ,.num_taps_p(num_taps_gp)
     ,.tag_els_p(tag_els_gp)
     ,.tag_lg_width_p(tag_lg_width_gp)
     )
   dut
    (.ext_clk_i(ext_clk_li)
     ,.async_output_disable_i(async_output_disable_li)

     ,.tag_clk_i(tag_clk_li)
     ,.tag_data_i(tag_data_li)
     ,.tag_node_id_offset_i(tag_node_id_offset_li)

     ,.clk_o(clk_lo)
     ,.clk_monitor_o(clk_monitor_lo)
     );

  struct packed {
    logic [test_rom_payload_width_gp-1-1:0] padding;
    logic async_output_disable;
  } test_payload_lo, test_payload_li;
  assign test_payload_li = test_data_i;
  assign test_data_o = test_payload_lo;

  logic async_output_disable_r;
  bsg_dff_reset_en
   #(.width_p(1))
   output_disable_reg
    (.clk_i(test_clk_i)
     ,.reset_i(test_reset_i)
     ,.en_i(test_v_i)
     ,.data_i(test_payload_li.async_output_disable)
     ,.data_o(async_output_disable_r)
     );
  assign test_yumi_o = test_v_i;

  assign test_v_o = 1'b0;
  wire unused1 = &{test_ready_and_i};

  assign ext_clk_li = asic_clk_i;
  assign async_output_disable_li = async_output_disable_r;
  assign tag_clk_li = asic_tag_clk_i;
  assign tag_data_li = asic_tag_data_i;
  assign tag_node_id_offset_li = asic_tag_node_id_offset_i;

  bit watch_clk_li;
  assign watch_clk_li = tag_done_i ? 1'b1 : clk_lo;
  bsg_nonsynth_clk_watcher
   #(.tolerance_p(watcher_tolerance_gp))
   watcher
    (.clk_i(watch_clk_li));

endmodule

