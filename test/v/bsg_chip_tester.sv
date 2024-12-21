
`include "bsg_defines.sv"
`include "bsg_tag.svh"

module bsg_chip_tester
 import bsg_tag_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_masters_p)
   , parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_clients_p)
   , parameter `BSG_INV_PARAM(tag_max_payload_width_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(gateway_tag_local_els_p)
   , parameter `BSG_INV_PARAM(gateway_tag_node_id_offset_p)
   , parameter `BSG_INV_PARAM(asic_num_clocks_p)
   , parameter `BSG_INV_PARAM(asic_tag_local_els_p)
   , parameter `BSG_INV_PARAM(asic_tag_node_id_offset_p)

   , parameter `BSG_INV_PARAM(tag_rom_str_p)
   , parameter `BSG_INV_PARAM(tag_rom_data_width_p)
   , parameter `BSG_INV_PARAM(tag_rom_addr_width_p)
   , parameter `BSG_INV_PARAM(tag_rom_payload_width_p)

   , parameter `BSG_INV_PARAM(test_rom_str_p)
   , parameter `BSG_INV_PARAM(test_rom_data_width_p)
   , parameter `BSG_INV_PARAM(test_rom_addr_width_p)
   , parameter `BSG_INV_PARAM(test_rom_payload_width_p)
   
   , parameter `BSG_INV_PARAM(trace_str_p)
   )
  (
    output bit gateway_clk_o
    , output bit gateway_reset_o

    , output bit gateway_tag_clk_o
    , output bit gateway_tag_en_o
    , output bit gateway_tag_data_o
    , output logic [tag_lg_clients_p-1:0] gateway_tag_node_id_offset_o
    , output bsg_tag_s [gateway_tag_local_els_p-1:0] gateway_tag_lines_o

    , output bit [asic_num_clocks_p-1:0] asic_clk_o

    , output bit asic_tag_clk_o
    , output bit asic_tag_en_o
    , output bit asic_tag_data_o
    , output logic [tag_lg_clients_p-1:0] asic_tag_node_id_offset_o
    , output bsg_tag_s [asic_tag_local_els_p-1:0] mirror_tag_lines_o

    , output bit test_clk_o
    , output logic test_reset_o
    , output logic [test_rom_payload_width_p-1:0] test_data_o
    , output logic test_v_o
    , input test_yumi_i

    , input [test_rom_payload_width_p-1:0] test_data_i
    , input test_v_i
    , output logic test_ready_and_o

    , output logic startup_o
    , output logic tag_done_o
    , output logic tag_error_o
    , output logic test_done_o
    , output logic test_error_o
    );

  //////////////////////////////////////////////////
  // Clock generation
  //////////////////////////////////////////////////
  localparam gateway_clk_period_lp = 1000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(gateway_clk_period_lp))
   gateway_clk_gen
    (.o(gateway_clk_o));

  localparam clk_A_period_lp = 6000;
  for (genvar i = 0; i < asic_num_clocks_p; i++)
    begin : cg
      bsg_nonsynth_clock_gen
       #(.cycle_time_p(clk_A_period_lp))
       inst
        (.o(asic_clk_o[i]));
    end

  bit tag_clk_lo;
  localparam tag_clk_period_lp = 5000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(tag_clk_period_lp))
   tag_clk_gen
    (.o(tag_clk_lo));

  //////////////////////////////////////////////////
  // Reset generation
  //////////////////////////////////////////////////
  localparam async_resetl_lp = 5;
  localparam async_reseth_lp = 20;
  bit async_reset_lo;
  // Not liked by verilator 5.030 (MULTIDRIVEN)
  //bsg_nonsynth_reset_gen
  // #(.num_clocks_p(2)
  //   ,.reset_cycles_lo_p(async_resetl_lp)
  //   ,.reset_cycles_hi_p(async_reseth_lp)
  //   )
  // async_reset_gen
  //  (.clk_i({tag_clk_lo, gateway_clk_o})
  //   ,.async_reset_o(async_reset_lo)
  //   );
  bit gateway_async_reset_lo;
  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(async_resetl_lp)
     ,.reset_cycles_hi_p(async_reseth_lp)
     )
   gateway_async_reset_gen
    (.clk_i(gateway_clk_o)
     ,.async_reset_o(gateway_async_reset_lo)
     );
  bit tag_async_reset_lo;
  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(async_resetl_lp)
     ,.reset_cycles_hi_p(async_reseth_lp)
     )
   tag_async_reset_gen
    (.clk_i(tag_clk_lo)
     ,.async_reset_o(tag_async_reset_lo)
     );
  wire async_reset_n = gateway_async_reset_lo | tag_async_reset_lo; 
  bsg_sync_sync
   #(.width_p(1))
   bss
    (.oclk_i(gateway_clk_o)
     ,.iclk_data_i(async_reset_n)
     ,.oclk_data_o(async_reset_lo)
     );
  assign gateway_reset_o = async_reset_lo;

  //////////////////////////////////////////////////
  // Tag generation
  //////////////////////////////////////////////////
  wire tag_trace_clk_lo = tag_clk_lo;
  wire tag_trace_reset_lo = async_reset_lo;
  wire tag_trace_en_lo = ~async_reset_lo;

  logic [tag_rom_addr_width_p-1:0] tag_rom_addr_li;
  logic [tag_rom_data_width_p-1:0] tag_rom_data_lo;
  bsg_nonsynth_test_rom_plusargs
   #(.data_width_p(tag_rom_data_width_p)
     ,.addr_width_p(tag_rom_addr_width_p)
     ,.plusargs_str_p(tag_rom_str_p)
     )
   tag_rom
    (.addr_i(tag_rom_addr_li), .data_o(tag_rom_data_lo));

  logic [tag_masters_p-1:0] tag_trace_en_r_lo;
  logic [tag_max_payload_width_p-1:0] tag_trace_data_li;
  logic tag_trace_v_li, tag_trace_ready_and_lo;
  logic tag_trace_data_lo;
  logic tag_trace_v_lo, tag_trace_yumi_li;
  logic tag_trace_done_lo, tag_trace_error_lo;
  bsg_tag_trace_replay
   #(.rom_addr_width_p(tag_rom_addr_width_p)
     ,.rom_data_width_p(tag_rom_data_width_p)
     ,.num_masters_p(tag_masters_p)
     ,.num_clients_p(tag_els_p)
     ,.max_payload_width_p(tag_max_payload_width_p)
     )
   tag_trace_replay
    (.clk_i(tag_trace_clk_lo)
     ,.reset_i(tag_trace_reset_lo)
     ,.en_i(tag_trace_en_lo)

     ,.rom_addr_o(tag_rom_addr_li)
     ,.rom_data_i(tag_rom_data_lo)

     ,.valid_i(1'b0)
     ,.data_i('0)
     ,.ready_o()

     ,.tag_data_o(tag_trace_data_lo)
     ,.en_r_o(tag_trace_en_r_lo)
     ,.valid_o(tag_trace_v_lo)
     ,.yumi_i(tag_trace_yumi_li)

     ,.done_o(tag_trace_done_lo)
     ,.error_o(tag_trace_error_lo)
    );
  assign tag_trace_yumi_li = tag_trace_v_lo;

  assign gateway_tag_clk_o = tag_trace_done_lo ? 1'b1 : tag_clk_lo;
  assign gateway_tag_en_o = tag_trace_en_r_lo[1] & tag_trace_v_lo;
  assign gateway_tag_data_o = gateway_tag_en_o ? tag_trace_data_lo : 1'b0;
  assign gateway_tag_node_id_offset_o = gateway_tag_node_id_offset_p;

  wire gateway_tag_clk_li = tag_clk_lo;
  wire gateway_tag_data_li = gateway_tag_en_o ? gateway_tag_data_o : 1'b0;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(gateway_tag_local_els_p)
     ,.lg_width_p(tag_lg_width_p)
     )
   gateway_btm
    (.clk_i(gateway_tag_clk_o)
     ,.data_i(gateway_tag_data_o)
     ,.node_id_offset_i(gateway_tag_node_id_offset_o)
     ,.clients_o(gateway_tag_lines_o)
     );

  assign asic_tag_clk_o = tag_trace_done_lo ? 1'b1 : ~tag_clk_lo;
  assign asic_tag_en_o = tag_trace_en_r_lo[0] & tag_trace_v_lo;
  assign asic_tag_data_o = asic_tag_en_o ? tag_trace_data_lo : 1'b0;
  assign asic_tag_node_id_offset_o = asic_tag_node_id_offset_p;

  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.lg_width_p(tag_lg_width_p)
     ,.local_els_p(asic_tag_local_els_p)
     )
   mirror_btm
    (.clk_i(asic_tag_clk_o)
     ,.data_i(asic_tag_data_o)
     ,.node_id_offset_i(asic_tag_node_id_offset_o)
     ,.clients_o(mirror_tag_lines_o)
     );

  //////////////////////////////////////////////////
  // Test generation
  //////////////////////////////////////////////////
  assign test_clk_o = gateway_clk_o;
  assign test_reset_o = async_reset_lo;
  wire test_trace_en_li = ~async_reset_lo & tag_trace_done_lo;

  logic [test_rom_addr_width_p-1:0] test_rom_addr_li;
  logic [test_rom_data_width_p-1:0] test_rom_data_lo;
  bsg_nonsynth_test_rom_plusargs
   #(.data_width_p(test_rom_data_width_p)
     ,.addr_width_p(test_rom_addr_width_p)
     ,.plusargs_str_p(test_rom_str_p)
     )
   test_rom
    (.addr_i(test_rom_addr_li), .data_o(test_rom_data_lo));

  logic test_trace_done_lo, test_trace_error_lo;  
  bsg_trace_replay
   #(.payload_width_p(test_rom_payload_width_p)
     ,.rom_addr_width_p(test_rom_addr_width_p)
     ,.debug_p(2)
     )
   test_trace_replay
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)
     ,.en_i(test_trace_en_li)

     ,.rom_addr_o(test_rom_addr_li)
     ,.rom_data_i(test_rom_data_lo)

     ,.data_o(test_data_o)
     ,.v_o(test_v_o)
     ,.yumi_i(test_yumi_i)

     ,.data_i(test_data_i)
     ,.v_i(test_v_i)
     ,.ready_o(test_ready_and_o)

     ,.done_o(test_trace_done_lo)
     ,.error_o(test_trace_error_lo)
     );

  //////////////////////////////////////////////////
  // Testbench functionality
  //////////////////////////////////////////////////
  wire waveform_en_li = 1'b1;
  bsg_nonsynth_waveform_tracer
   #(.trace_str_p("bsg_trace"))
   tracer
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)
     ,.en_i(waveform_en_li)
     );
 
  wire assert_en_li = 1'b1;
  bsg_nonsynth_assert
   _assert
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)
     ,.en_i(assert_en_li)                                                   );

  logic startup;
  initial
    begin
      startup = 1'b0;
      @(negedge async_reset_lo);
      startup = 1'b1;
      @(posedge tag_done_o)
      $display("BSG-INFO: Tag finished");
      @(posedge test_done_o)
      $display("BSG-PASS: Test finished");
      @(posedge test_clk_o);
      @(posedge test_clk_o);
      @(posedge test_clk_o);
      $finish();
    end

  assign startup_o = startup;
  assign tag_done_o = startup && tag_trace_done_lo;
  assign tag_error_o = startup && tag_trace_error_lo;
  assign test_done_o = startup && test_trace_done_lo;
  assign test_error_o = startup && test_trace_error_lo;

endmodule

`BSG_ABSTRACT_MODULE(bsg_chip_tester)

