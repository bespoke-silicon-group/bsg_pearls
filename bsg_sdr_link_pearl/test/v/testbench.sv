
`timescale 1ns/1ps

`include "bsg_defines.sv"
`include "bsg_tag.svh"

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

  bsg_chip_tester
   #(.tag_masters_p(tag_masters_gp)
     ,.tag_els_p(tag_els_gp)
     ,.tag_max_payload_width_p(tag_max_payload_width_gp)
     ,.gateway_tag_local_els_p(gateway_tag_local_els_gp)
     ,.gateway_tag_node_id_offset_p(gateway_tag_node_id_offset_gp)
     ,.asic_num_clocks_p(asic_num_clocks_gp)
     ,.asic_tag_local_els_p(asic_tag_local_els_gp)
     ,.asic_tag_node_id_offset_p(asic_tag_node_id_offset_gp)

     ,.tag_rom_str_p(tag_rom_str_gp)
     ,.tag_rom_data_width_p(tag_rom_data_width_gp)
     ,.tag_rom_addr_width_p(tag_rom_addr_width_gp)
     ,.tag_rom_payload_width_p(tag_rom_payload_width_gp)

     ,.test_rom_str_p(test_rom_str_gp)
     ,.test_rom_data_width_p(test_rom_data_width_gp)
     ,.test_rom_addr_width_p(test_rom_addr_width_gp)
     ,.test_rom_payload_width_p(test_rom_payload_width_gp)

     ,.trace_str_p(trace_str_gp)
     )
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

  logic core_clk_li, core_reset_li;
  logic tag_clk_li, tag_data_li;
  logic [tag_lg_clients_gp-1:0] tag_node_id_offset_li;
  logic link_clk_lo, link_v_lo, link_token_li, async_link_o_disable_lo;
  logic [sdr_data_width_gp-1:0] link_data_lo;
  logic link_clk_li, link_v_li, link_token_lo, async_link_i_disable_lo;
  logic [sdr_data_width_gp-1:0] link_data_li;
  logic core_v_lo, core_ready_and_li;
  logic [core_data_width_gp-1:0] core_data_lo;
  logic core_v_li, core_ready_and_lo;
  logic [core_data_width_gp-1:0] core_data_li;
  bsg_chip
   dut
    (.core_clk_i(core_clk_li)
 	 ,.core_reset_i(core_reset_li)

	 ,.tag_clk_i(tag_clk_li)
	 ,.tag_data_i(tag_data_li)
	 ,.tag_node_id_offset_i(tag_node_id_offset_li)

	 ,.link_clk_o(link_clk_lo)
	 ,.link_data_o(link_data_lo)
	 ,.link_v_o(link_v_lo)
	 ,.link_token_i(link_token_lo)
	 ,.async_link_o_disable_o(async_link_o_disable_lo)

	 ,.link_clk_i(link_clk_li)
	 ,.link_data_i(link_data_lo)
	 ,.link_v_i(link_v_lo)
	 ,.link_token_o(link_token_lo)
	 ,.async_link_i_disable_o(async_link_i_disable_lo)

	 ,.core_data_i(core_data_li)
	 ,.core_v_i(core_v_li)
	 ,.core_ready_and_o(core_ready_and_lo)

	 ,.core_data_o(core_data_lo)
	 ,.core_v_o(core_v_lo)
	 ,.core_ready_and_i(core_ready_and_li)
	 );

  assign core_clk_li = test_clk_lo;
  assign core_reset_li = test_reset_lo;

  assign tag_clk_li = asic_tag_clk_lo;
  assign tag_data_li = asic_tag_data_lo;
  assign tag_node_id_offset_li = asic_tag_node_id_offset_lo;

  assign link_clk_li = link_clk_lo;
  assign link_v_li = link_v_lo;
  assign link_data_li = link_data_lo;
  assign link_token_li = link_token_lo;

  // Stub core link for now
  assign core_data_li = '0;
  assign core_v_li = 1'b0;
  assign core_ready_and_li = 1'b0;

  initial begin #100000; $finish(); end

endmodule

