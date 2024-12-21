
`include "bsg_chip_defines.svh"

module testbench;
  import bsg_chip_pkg::*;
  import bsg_tag_pkg::*;

  bit gateway_clk_lo, gateway_reset_lo;
  bit gateway_tag_clk_lo, gateway_tag_en_lo, gateway_tag_data_lo;
  logic [tag_lg_clients_gp-1:0] gateway_tag_node_id_offset_lo;
  bsg_tag_s [gateway_tag_local_els_gp-1:0] gateway_tag_lines_lo;

  bit [asic_num_clocks_gp-1:0] asic_clk_lo;
  bit asic_tag_clk_lo, asic_tag_en_lo, asic_tag_data_lo;
  logic [tag_lg_clients_gp-1:0] asic_tag_node_id_offset_lo;
  bsg_tag_s [asic_tag_local_els_gp-1:0] mirror_tag_lines_lo;

  bit test_clk_lo;
  logic test_reset_lo;
  logic [test_rom_payload_width_gp-1:0] test_data_lo;
  logic test_v_lo, test_yumi_li;
  logic [test_rom_payload_width_gp-1:0] test_data_li;
  logic test_v_li, test_ready_and_lo;

  logic startup_lo;
  logic tag_done_lo, tag_error_lo;
  logic test_done_lo, test_error_lo;

  bsg_chip_gateway
   gateway
    (.gateway_clk_o(gateway_clk_lo)
     ,.gateway_reset_o(gateway_reset_lo)

     ,.gateway_tag_clk_o(gateway_tag_clk_lo)
     ,.gateway_tag_en_o(gateway_tag_en_lo)
     ,.gateway_tag_data_o(gateway_tag_data_lo)
     ,.gateway_tag_node_id_offset_o(gateway_tag_node_id_offset_lo)
     ,.gateway_tag_lines_o(gateway_tag_lines_lo)

     ,.asic_clk_o(asic_clk_lo)

     ,.asic_tag_clk_o(asic_tag_clk_lo)
     ,.asic_tag_en_o(asic_tag_en_lo)
     ,.asic_tag_data_o(asic_tag_data_lo)
     ,.asic_tag_node_id_offset_o(asic_tag_node_id_offset_lo)
     ,.mirror_tag_lines_o(mirror_tag_lines_lo)

     ,.test_clk_o(test_clk_lo)
     ,.test_reset_o(test_reset_lo)
     ,.test_data_o(test_data_lo)
     ,.test_v_o(test_v_lo)
     ,.test_yumi_i(test_yumi_li)

     ,.test_data_i(test_data_li)
     ,.test_v_i(test_v_li)
     ,.test_ready_and_o(test_ready_and_lo)

     ,.startup_o(startup_lo)
     ,.tag_done_o(tag_done_lo)
     ,.tag_error_o(tag_error_lo)
     ,.test_done_o(test_done_lo)
     ,.test_error_o(test_error_lo)
     );

  bsg_chip
   chip
    (.gateway_clk_i(gateway_clk_lo)
     ,.gateway_reset_i(gateway_reset_lo)
     ,.gateway_tag_clk_i(gateway_tag_clk_lo)
     ,.gateway_tag_en_i(gateway_tag_en_lo)
     ,.gateway_tag_data_i(gateway_tag_data_lo)
     ,.gateway_tag_node_id_offset_i(gateway_tag_node_id_offset_lo)
     ,.gateway_tag_lines_i(gateway_tag_lines_lo)

     ,.asic_clk_i(asic_clk_lo)
     ,.asic_tag_clk_i(asic_tag_clk_lo)
     ,.asic_tag_en_i(asic_tag_en_lo)
     ,.asic_tag_data_i(asic_tag_data_lo)
     ,.asic_tag_node_id_offset_i(asic_tag_node_id_offset_lo)
     ,.mirror_tag_lines_i(mirror_tag_lines_lo)

     ,.test_clk_i(test_clk_lo)
     ,.test_reset_i(test_reset_lo)
     ,.test_data_i(test_data_lo)
     ,.test_v_i(test_v_lo)
     ,.test_yumi_o(test_yumi_li)

     ,.test_data_o(test_data_li)
     ,.test_v_o(test_v_li)
     ,.test_ready_and_i(test_ready_and_lo)

     ,.startup_i(startup_lo)
     ,.tag_done_i(tag_done_lo)
     ,.tag_error_i(tag_error_lo)
     ,.test_done_i(test_done_lo)
     ,.test_error_i(test_error_lo)
     );

endmodule

