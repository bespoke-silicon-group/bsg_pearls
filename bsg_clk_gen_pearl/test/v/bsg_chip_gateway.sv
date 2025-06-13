
`include "bsg_chip_defines.svh"
`include "bsg_tag.svh"

module bsg_chip_gateway
 import bsg_chip_pkg::*;
 import bsg_tag_pkg::*;
  (
    output bit gateway_clk_o
    , output bit gateway_reset_o

    , output bit gateway_tag_clk_o
    , output bit gateway_tag_en_o
    , output bit gateway_tag_data_o
    , output bit [tag_lg_clients_gp-1:0] gateway_tag_node_id_offset_o
    , output bit [gateway_tag_local_els_gp-1:0][$bits(bsg_tag_s)-1:0] gateway_tag_lines_o

    , output bit [asic_num_clocks_gp-1:0] asic_clk_o

    , output bit asic_tag_clk_o
    , output bit asic_tag_en_o
    , output bit asic_tag_data_o
    , output bit [tag_lg_clients_gp-1:0] asic_tag_node_id_offset_o
    , output bit [asic_tag_local_els_gp-1:0][$bits(bsg_tag_s)-1:0] mirror_tag_lines_o

    , output bit test_clk_o
    , output bit test_reset_o
    , output bit [test_rom_payload_width_gp-1:0] test_data_o
    , output bit test_v_o
    , input bit test_yumi_i

    , input bit [test_rom_payload_width_gp-1:0] test_data_i
    , input bit test_v_i
    , output bit test_ready_and_o

    , output bit startup_o
    , output bit tag_done_o
    , output bit tag_error_o
    , output bit test_done_o
    , output bit test_error_o
    );

  bsg_chip_tester
   #(.tag_masters_p(tag_masters_gp)
     ,.tag_els_p(tag_els_gp)
     ,.tag_lg_clients_p(tag_lg_clients_gp)
     ,.tag_max_payload_width_p(tag_max_payload_width_gp)
     ,.tag_lg_width_p(tag_lg_width_gp)
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
   bct
    (.*);

endmodule

