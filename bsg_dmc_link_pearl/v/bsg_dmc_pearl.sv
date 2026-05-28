
`include "bsg_tag.svh"
`include "bsg_dmc.svh"

module bsg_dmc_pearl
 import bsg_tag_pkg::*;
 import bsg_dmc_pkg::*;
 import bsg_dmc_pearl_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(num_taps_p)
   , parameter `BSG_INV_PARAM(ds_width_p)
   , parameter `BSG_INV_PARAM(ui_addr_width_p)
   , parameter `BSG_INV_PARAM(ui_data_width_p)
   , parameter `BSG_INV_PARAM(ui_burst_len_p)
   , parameter `BSG_INV_PARAM(dq_data_width_p)
   , parameter `BSG_INV_PARAM(cmd_afifo_depth_p)
   , parameter `BSG_INV_PARAM(cmd_sfifo_depth_p)
   , parameter `BSG_INV_PARAM(trace_tfifo_depth_p)
   , parameter `BSG_INV_PARAM(trace_rfifo_depth_p)

   , localparam trace_data_width_lp = `bsg_dmc_trace_entry_width(ui_data_width_p, ui_addr_width_p)
   , localparam ui_mask_width_lp    = ui_data_width_p >> 3
   , localparam dfi_data_width_lp   = dq_data_width_p << 1
   , localparam dfi_mask_width_lp   = (dq_data_width_p >> 3) << 1
   , localparam dq_group_lp         = dq_data_width_p >> 3
   )
   (input                                    ui_clk_i
    , output logic                           ui_reset_o
    , input                                  ext_dfi_clk_2x_i
    , output logic                           dfi_clk_1x_o

    , input                                  tag_clk_i
    , input                                  tag_data_i
    , input [`BSG_SAFE_CLOG2(tag_els_p)-1:0] tag_node_id_offset_i

    // User interface signals
    , input [ui_addr_width_p-1:0]            app_addr_i
    , input app_cmd_e                        app_cmd_i
    , input                                  app_en_i
    , output logic                           app_rdy_o
    , input                                  app_wdf_wren_i
    , input [ui_data_width_p-1:0]            app_wdf_data_i
    , input [ui_mask_width_lp-1:0]           app_wdf_mask_i
    , input                                  app_wdf_end_i
    , output logic                           app_wdf_rdy_o
    , output logic                           app_rd_data_valid_o
    , output logic [ui_data_width_p-1:0]     app_rd_data_o
    , output logic                           app_rd_data_end_o

    // Status signals
    , output logic                           dfi_clk_1x_monitor_o
    , output logic                           dfi_clk_2x_monitor_o
    , output logic                           calib_clk_monitor_o
    , output logic                           calib_dqs_monitor_o
    , output logic                           calib_dqs_dly_monitor_o
    , output logic                           dfi_init_calib_complete_o
    , output logic                           dfi_stall_transactions_o
    , output logic                           ui_transaction_in_progress_o
    , output logic                           dfi_refresh_in_progress_o
    , output logic                           dfi_test_mode_o

    // Trace-replay interface
    , output logic                           trace_ready_and_o
    , input [trace_data_width_lp-1:0]        trace_data_i
    , input                                  trace_v_i

    // Read data to consumer
    , output logic [ui_data_width_p-1:0]     trace_data_o
    , output logic                           trace_v_o
    , input                                  trace_yumi_i

    // DDR interface signals
    // Physically compatible with (LP)DDR3/DDR2/DDR, but only (LP)DDR
    // protocal is logically implemented in the controller
    // Command and Address interface
    , output logic                           ddr_ck_p_o
    , output logic                           ddr_ck_n_o
    , output logic                           ddr_cke_o
    , output logic [2:0]                     ddr_ba_o
    , output logic [15:0]                    ddr_addr_o
    , output logic                           ddr_cs_n_o
    , output logic                           ddr_ras_n_o
    , output logic                           ddr_cas_n_o
    , output logic                           ddr_we_n_o
    , output logic                           ddr_reset_n_o
    , output logic                           ddr_odt_o
    // Data interface
    , output logic [dq_group_lp-1:0]         ddr_dm_oen_o
    , output logic [dq_group_lp-1:0]         ddr_dm_o
    , output logic [dq_group_lp-1:0]         ddr_dqs_p_oen_o
    , output logic [dq_group_lp-1:0]         ddr_dqs_p_ien_o
    , output logic [dq_group_lp-1:0]         ddr_dqs_p_o
    , input [dq_group_lp-1:0]                ddr_dqs_p_i
    , output logic [dq_group_lp-1:0]         ddr_dqs_n_oen_o
    , output logic [dq_group_lp-1:0]         ddr_dqs_n_ien_o
    , output logic [dq_group_lp-1:0]         ddr_dqs_n_o
    , input [dq_group_lp-1:0]                ddr_dqs_n_i
    , output logic [dq_data_width_p-1:0]     ddr_dq_oen_o
    , output logic [dq_data_width_p-1:0]     ddr_dq_o
    , input [dq_data_width_p-1:0]            ddr_dq_i
    );

  bsg_dmc_pearl_tag_lines_s tag_lines_lo;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(bsg_dmc_pearl_tag_local_els_gp)
     ,.lg_width_p(tag_lg_width_p)
     )
   btm
    (.clk_i(tag_clk_i)
     ,.data_i(tag_data_i)
     ,.node_id_offset_i(tag_node_id_offset_i)
     ,.clients_o(tag_lines_lo)
     );

  logic [ui_addr_width_p-1:0]      trace_app_addr;
  app_cmd_e                        trace_app_cmd;
  logic                            trace_app_en;
  logic                            trace_app_rdy;
  logic                            trace_app_wdf_wren;
  logic [ui_data_width_p-1:0]      trace_app_wdf_data;
  logic [(ui_data_width_p>>3)-1:0] trace_app_wdf_mask;
  logic                            trace_app_wdf_end;
  logic                            trace_app_wdf_rdy;

  logic                            trace_app_rd_data_valid;
  logic [ui_data_width_p-1:0]      trace_app_rd_data;
  logic                            trace_app_rd_data_end;

  bsg_dmc_xilinx_ui_trace_replay
   #(.data_width_p(ui_data_width_p)
     ,.addr_width_p(ui_addr_width_p)
     ,.burst_len_p(ui_burst_len_p)
     ,.tfifo_depth_p(trace_tfifo_depth_p)
     ,.rfifo_depth_p(trace_rfifo_depth_p)
     )
   trace_replay
    (.clk_i(ui_clk_i)
     ,.reset_i(ui_reset_o)

     ,.data_i(trace_data_i)
     ,.v_i(trace_v_i)
     ,.ready_and_o(trace_ready_and_o)

     ,.data_o(trace_data_o)
     ,.v_o(trace_v_o)
     ,.yumi_i(trace_yumi_i)

     ,.app_addr_o(trace_app_addr)
     ,.app_cmd_o(trace_app_cmd)
     ,.app_en_o(trace_app_en)
     ,.app_rdy_i(trace_app_rdy)
     ,.app_wdf_wren_o(trace_app_wdf_wren)
     ,.app_wdf_data_o(trace_app_wdf_data)
     ,.app_wdf_mask_o(trace_app_wdf_mask)
     ,.app_wdf_end_o(trace_app_wdf_end)
     ,.app_wdf_rdy_i(trace_app_wdf_rdy)
     ,.app_rd_data_valid_i(trace_app_rd_data_valid)
     ,.app_rd_data_i(trace_app_rd_data)
     ,.app_rd_data_end_i(trace_app_rd_data_end)
     );

  logic [ui_addr_width_p-1:0]      app_addr;
  app_cmd_e                        app_cmd;
  logic                            app_en;
  logic                            app_rdy;
  logic                            app_wdf_wren;
  logic [ui_data_width_p-1:0]      app_wdf_data;
  logic [(ui_data_width_p>>3)-1:0] app_wdf_mask;
  logic                            app_wdf_end;
  logic                            app_wdf_rdy;

  logic                            app_rd_data_valid;
  logic [ui_data_width_p-1:0]      app_rd_data;
  logic                            app_rd_data_end;

  logic [dq_group_lp-1:0] dqs_clk_lo, dqs_clk_dly_lo;
  logic dfi_clk_1x_lo, dfi_clk_2x_lo;
  bsg_dmc
   #(.num_taps_p(num_taps_p)
     ,.ui_addr_width_p(ui_addr_width_p)
     ,.ui_data_width_p(ui_data_width_p)
     ,.burst_data_width_p(ui_burst_len_p*ui_data_width_p)
     ,.dq_data_width_p(dq_data_width_p)
     ,.cmd_afifo_depth_p(cmd_afifo_depth_p)
     ,.cmd_sfifo_depth_p(cmd_sfifo_depth_p)
     )
   dmc
    (.dly_tag_lines_i(tag_lines_lo.dly)
     ,.cfg_tag_lines_i(tag_lines_lo.cfg)
     ,.sys_tag_lines_i(tag_lines_lo.sys)
     ,.osc_tag_lines_i(tag_lines_lo.osc)

     ,.app_addr_i(app_addr)
     ,.app_cmd_i(app_cmd)
     ,.app_en_i(app_en)
     ,.app_rdy_o(app_rdy)
     ,.app_wdf_wren_i(app_wdf_wren)
     ,.app_wdf_data_i(app_wdf_data)
     ,.app_wdf_mask_i(app_wdf_mask)
     ,.app_wdf_end_i(app_wdf_end)
     ,.app_wdf_rdy_o(app_wdf_rdy)
     ,.app_rd_data_valid_o(app_rd_data_valid)
     ,.app_rd_data_o(app_rd_data)
     ,.app_rd_data_end_o(app_rd_data_end)

     ,.app_ref_req_i('0)
     ,.app_ref_ack_o()
     ,.app_zq_req_i('0)
     ,.app_zq_ack_o()
     ,.app_sr_req_i('0)
     ,.app_sr_active_o()

     ,.dfi_init_calib_complete_o(dfi_init_calib_complete_o)
     ,.ui_transaction_in_progress_o(ui_transaction_in_progress_o)
     ,.dfi_stall_transactions_o(dfi_stall_transactions_o)
     ,.dfi_refresh_in_progress_o(dfi_refresh_in_progress_o)
     ,.dfi_test_mode_o(dfi_test_mode_o)

     ,.ddr_ck_p_o(ddr_ck_p_o)
     ,.ddr_ck_n_o(ddr_ck_n_o)
     ,.ddr_cke_o(ddr_cke_o)
     ,.ddr_ba_o(ddr_ba_o)
     ,.ddr_addr_o(ddr_addr_o)
     ,.ddr_cs_n_o(ddr_cs_n_o)
     ,.ddr_ras_n_o(ddr_ras_n_o)
     ,.ddr_cas_n_o(ddr_cas_n_o)
     ,.ddr_we_n_o(ddr_we_n_o)
     ,.ddr_reset_n_o(ddr_reset_n_o)
     ,.ddr_odt_o(ddr_odt_o)

     ,.ddr_dm_oen_o(ddr_dm_oen_o)
     ,.ddr_dm_o(ddr_dm_o)
     ,.ddr_dqs_p_oen_o(ddr_dqs_p_oen_o)
     ,.ddr_dqs_p_ien_o(ddr_dqs_p_ien_o)
     ,.ddr_dqs_p_o(ddr_dqs_p_o)
     ,.ddr_dqs_p_i(ddr_dqs_p_i)
     ,.ddr_dqs_n_oen_o(ddr_dqs_n_oen_o)
     ,.ddr_dqs_n_ien_o(ddr_dqs_n_ien_o)
     ,.ddr_dqs_n_o(ddr_dqs_n_o)
     ,.ddr_dqs_n_i(ddr_dqs_n_i)
     ,.ddr_dq_oen_o(ddr_dq_oen_o)
     ,.ddr_dq_o(ddr_dq_o)
     ,.ddr_dq_i(ddr_dq_i)

     ,.ui_clk_i(ui_clk_i)

     ,.ui_clk_sync_rst_o(ui_reset_o)
     ,.ext_dfi_clk_2x_i(ext_dfi_clk_2x_i)
     ,.dfi_clk_2x_o(dfi_clk_2x_lo)
     ,.dfi_clk_1x_o(dfi_clk_1x_lo)
     ,.dqs_clk_o(dqs_clk_lo)
     ,.dqs_clk_dly_o(dqs_clk_dly_lo)
     ,.device_temp_o()
     );

  always_comb
    begin
      app_addr                = '0;
      app_cmd                 = '0;
      app_en                  = '0;
      app_rdy_o               = '0;
      trace_app_rdy           = '0;

      app_wdf_wren            = '0;
      app_wdf_data            = '0;
      app_wdf_mask            = '0;
      app_wdf_end             = '0;
      app_wdf_rdy_o           = '0;
      trace_app_wdf_rdy       = '0;

      trace_app_rd_data_valid = '0;
      trace_app_rd_data       = '0;
      trace_app_rd_data_end   = '0;

      app_rd_data_valid_o = '0;
      app_rd_data_o       = '0;
      app_rd_data_end_o   = '0;

      if (dfi_test_mode_o)
        begin
          app_addr                = trace_app_addr;
          app_cmd                 = trace_app_cmd;
          app_en                  = trace_app_en;
          trace_app_rdy           = app_rdy;
          app_wdf_wren            = trace_app_wdf_wren;
          app_wdf_data            = trace_app_wdf_data;
          app_wdf_mask            = trace_app_wdf_mask;
          app_wdf_end             = trace_app_wdf_end;
          trace_app_wdf_rdy       = app_wdf_rdy;
          trace_app_rd_data_valid = app_rd_data_valid;
          trace_app_rd_data       = app_rd_data;
          trace_app_rd_data_end   = app_rd_data_end;
        end
      else
        begin
          app_addr            = app_addr_i;
          app_cmd             = app_cmd_i;
          app_en              = app_en_i;
          app_rdy_o           = app_rdy;
          app_wdf_wren        = app_wdf_wren_i;
          app_wdf_data        = app_wdf_data_i;
          app_wdf_mask        = app_wdf_mask_i;
          app_wdf_end         = app_wdf_end_i;
          app_wdf_rdy_o       = app_wdf_rdy;
          app_rd_data_valid_o = app_rd_data_valid;
          app_rd_data_o       = app_rd_data;
          app_rd_data_end_o   = app_rd_data_end;
        end
    end

  `declare_bsg_clk_gen_ds_tag_payload_s(ds_width_p);
  bsg_clk_gen_ds_tag_payload_s ds_tag_payload_r;

  bsg_tag_client_unsync
   #(.width_p($bits(bsg_clk_gen_ds_tag_payload_s)))
   btc_ds
    (.bsg_tag_i(tag_lines_lo.monitor_ds)
     ,.data_async_r_o(ds_tag_payload_r)
     );

  logic [1:0] monitor_sel_r;
  bsg_tag_client_unsync
   #(.width_p(2))
   btc_sel
    (.bsg_tag_i(tag_lines_lo.monitor_sel)
     ,.data_async_r_o(monitor_sel_r)
     );

  bsg_counter_clock_downsample
   #(.width_p(ds_width_p), .harden_p(1))
   dfi_ds
    (.clk_i(dfi_clk_1x_lo)
    ,.reset_i(ds_tag_payload_r.reset)
    ,.val_i(ds_tag_payload_r.val)
    ,.clk_r_o(calib_clk_monitor_o)
    );

  logic dqs_sel_lo;
  bsg_mux
   #(.width_p(1), .els_p(4), .balanced_p(1), .harden_p(1))
   dqs_mux
    (.data_i(dqs_clk_lo)
     ,.sel_i(monitor_sel_r)
     ,.data_o(dqs_sel_lo)
     );

  bsg_counter_clock_downsample
   #(.width_p(ds_width_p), .harden_p(1))
   dqs_ds
    (.clk_i(dqs_sel_lo)
     ,.reset_i(ds_tag_payload_r.reset)
     ,.val_i(ds_tag_payload_r.val)
     ,.clk_r_o(calib_dqs_monitor_o)
     );

  logic dqs_dly_sel_lo;
  bsg_mux
   #(.width_p(1), .els_p(4), .balanced_p(1), .harden_p(1))
   dqs_dly_mux
    (.data_i(dqs_clk_dly_lo)
     ,.sel_i(monitor_sel_r)
     ,.data_o(dqs_dly_sel_lo)
     );

  bsg_counter_clock_downsample
   #(.width_p(ds_width_p), .harden_p(1))
   dqs_dly_ds
    (.clk_i(dqs_dly_sel_lo)
     ,.reset_i(ds_tag_payload_r.reset)
     ,.val_i(ds_tag_payload_r.val)
     ,.clk_r_o(calib_dqs_dly_monitor_o)
     );

  bsg_clk_gen_pearl_monitor
   monitor_dfi_2x
    (.bsg_tag_i(tag_lines_lo.monitor_reset)
     ,.clk_i(dfi_clk_2x_lo)
     ,.clk_monitor_o(dfi_clk_2x_monitor_o)
     );

  bsg_clk_gen_pearl_monitor
   monitor_dfi_1x
    (.bsg_tag_i(tag_lines_lo.monitor_reset)
     ,.clk_i(dfi_clk_1x_lo)
     ,.clk_monitor_o(dfi_clk_1x_monitor_o)
     );
  assign dfi_clk_1x_o = dfi_clk_1x_lo;

endmodule


