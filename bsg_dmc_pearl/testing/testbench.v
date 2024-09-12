module testbench();
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
  import bsg_dmc_pearl_pkg::*;

  parameter clk_gen_num_adgs_p = 1;
  parameter ui_addr_width_p    = 28;
  parameter ui_data_width_p    = 32;
  parameter ui_burst_length_p  = 8;
  parameter dq_data_width_p    = 32;
  parameter cmd_afifo_depth_p  = 6;
  parameter cmd_sfifo_depth_p  = 6;
  parameter debug_p            = 1'b1;

  localparam burst_data_width_lp = ui_data_width_p * ui_burst_length_p;
  localparam ui_mask_width_lp    = ui_data_width_p >> 3;
  localparam dq_group_lp         = dq_data_width_p >> 3;
  localparam dq_burst_length_lp  = burst_data_width_lp / dq_data_width_p;
  localparam trace_data_width_lp = `bsg_dmc_trace_entry_width(ui_data_width_p, ui_addr_width_p);


  genvar i;

  integer j,k;

  bsg_dmc_s                        dmc_p;

  logic							   stall_transactions_lo;
  logic							   transaction_in_progress_lo;
  logic							   test_mode_lo;
  logic							   refresh_in_progress_lo;

  logic                            sys_reset;
  logic							   clock_monitor_clk_lo;

  // User interface signals
  logic      [ui_addr_width_p-1:0] app_addr;
  app_cmd_e                        app_cmd;
  logic                            app_en;
  wire                             app_rdy;
  logic                            app_wdf_wren;
  logic      [ui_data_width_p-1:0] app_wdf_data;
  logic [(ui_data_width_p>>3)-1:0] app_wdf_mask;
  logic                            app_wdf_end;
  wire                             app_wdf_rdy;

  wire                             app_rd_data_valid;
  wire       [ui_data_width_p-1:0] app_rd_data;
  wire                             app_rd_data_end;

  wire                             app_ref_req;
  wire                             app_ref_ack;
  wire                             app_zq_req;
  wire                             app_zq_ack;
  wire                             app_sr_req;
  wire                             app_sr_active;
  // Status signal
  wire                             init_calib_complete;
  logic							   frequency_mismatch_lo;

  logic                            ui_clk;
  wire                             ui_clk_sync_rst;

  logic                            dfi_clk_2x;
  logic                            dfi_clk_1x;

  wire                      [11:0] device_temp;

  wire                             ddr_ck_p, ddr_ck_n;
  wire                             ddr_cke;
  wire                             ddr_cs_n;
  wire                             ddr_ras_n;
  wire                             ddr_cas_n;
  wire                             ddr_we_n;
  wire                       [2:0] ddr_ba;
  wire                      [15:0] ddr_addr;

  wire                             ddr_reset_n;
  wire                             ddr_odt;

  wire  [(dq_data_width_p>>3)-1:0] ddr_dm_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dm_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_ien_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_li;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_ien_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_li;
  wire       [dq_data_width_p-1:0] ddr_dq_oen_lo;
  wire       [dq_data_width_p-1:0] ddr_dq_lo;
  wire       [dq_data_width_p-1:0] ddr_dq_li;
  
  wire  [(dq_data_width_p>>3)-1:0] ddr_dm;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n;
  wire       [dq_data_width_p-1:0] ddr_dq;

  // All tag lines from the btm
  localparam tag_dmc_local_els_lp = tag_dmc_dly_local_els_gp+tag_dmc_cfg_local_els_gp+tag_dmc_sys_local_els_gp+tag_dmc_osc_local_els_gp;

  logic tag_clk_lo;
  logic tag_data_lo;

  logic send_dynamic_tag, irritate_clock, clock_correction_done_lo;
   
  logic                           trace_ready_li;
  logic [trace_data_width_lp-1:0] trace_data_lo;
  logic                           trace_v_lo;

  logic [ui_data_width_p-1:0]     trace_data_li;
  logic                           trace_v_li;
  logic                           trace_yumi_lo;

  traffic_generator #
    (.num_adgs_p         ( clk_gen_num_adgs_p  )
    ,.ui_addr_width_p    ( ui_addr_width_p     )
    ,.ui_data_width_p    ( ui_data_width_p     )
    ,.burst_data_width_p ( burst_data_width_lp )
    ,.dq_data_width_p    ( dq_data_width_p     )
    ,.cmd_afifo_depth_p  ( cmd_afifo_depth_p   )
    ,.cmd_sfifo_depth_p  ( cmd_sfifo_depth_p   ))
    // Tag lines
  traffic_generator_inst
    // Global asynchronous reset input, will be synchronized to each clock domain
    // Consistent with the reset signal defined in Xilinx UI interface
    // User interface signals
    (.app_addr_o            ( app_addr            )
    ,.app_cmd_o             ( app_cmd             )
    ,.app_en_o              ( app_en              )
    ,.app_rdy_i             ( app_rdy             )
    ,.app_wdf_wren_o        ( app_wdf_wren        )
    ,.app_wdf_data_o        ( app_wdf_data        )
    ,.app_wdf_mask_o        ( app_wdf_mask        )
    ,.app_wdf_end_o         ( app_wdf_end         )
    ,.app_wdf_rdy_i         ( app_wdf_rdy         )
    ,.app_rd_data_valid_i   ( app_rd_data_valid   )
    ,.app_rd_data_i         ( app_rd_data         )
    ,.app_rd_data_end_i     ( app_rd_data_end     )
    // Reserved to be compatible with Xilinx IPs
    ,.app_ref_req_o         ( app_ref_req         )
    ,.app_ref_ack_i         ( app_ref_ack         )
    ,.app_zq_req_o          ( app_zq_req          )
    ,.app_zq_ack_i          ( app_zq_ack          )
    ,.app_sr_req_o          ( app_sr_req          )
    ,.app_sr_active_i       ( app_sr_active       )
    // Status signal
    ,.init_calib_complete_i ( init_calib_complete )
    ,.ui_clk_o              ( ui_clk              )
    ,.ui_clk_sync_rst_i     ( ui_clk_sync_rst     )
    ,.dfi_clk_o             ( dfi_clk             )
    ,.tag_clk_o             ( tag_clk_lo          )  
	,.tag_master_data_o 	(tag_data_lo)
	,.stall_trace_reading_i (send_dynamic_tag)
	,.irritate_clock_i		(irritate_clock)
	,.refresh_in_progress_i (refresh_in_progress_lo)
	,.clock_monitor_clk_i	(clock_monitor_clk_lo)
	,.frequency_mismatch_o	(frequency_mismatch_lo)
	,.clock_correction_done_o(clock_correction_done_lo)

    ,.trace_ready_i         (trace_ready_li)
    ,.trace_data_o          (trace_data_lo)
    ,.trace_v_o             (trace_v_lo)

    ,.trace_data_i          (trace_data_li)
    ,.trace_v_i             (trace_v_li)
    ,.trace_yumi_o          (trace_yumi_lo)
	);

  logic tag_node_id_offset_li;
  assign tag_node_id_offset_li = 0;
  logic calib_clk_monitor_lo;

  bsg_dmc_pearl #
    (.tag_lg_width_p        ( tag_lg_max_payload_width_gp   )
    ,.num_adgs_p            ( clk_gen_num_adgs_p            )
    ,.ui_addr_width_p       ( ui_addr_width_p               )
    ,.ui_data_width_p       ( ui_data_width_p               )
    ,.dq_data_width_p       ( dq_data_width_p               )
    ,.cmd_afifo_depth_p     ( cmd_afifo_depth_p             )
    ,.cmd_sfifo_depth_p     ( cmd_sfifo_depth_p             )
    ,.ds_width_p            ( 2                             )
    ,.ui_burst_len_p        ( ui_burst_length_p             )
    ,.trace_tfifo_depth_p   ( 3*ui_burst_length_p           )
    ,.trace_rfifo_depth_p   ( 2*ui_burst_length_p           )
    )
  dmc_pearl_inst
    (
    .app_addr_i            ( app_addr            )
    ,.app_cmd_i             ( app_cmd             )
    ,.app_en_i              ( app_en              )
    ,.app_rdy_o             ( app_rdy             )
    ,.app_wdf_wren_i        ( app_wdf_wren        )
    ,.app_wdf_data_i        ( app_wdf_data        )
    ,.app_wdf_mask_i        ( app_wdf_mask        )
    ,.app_wdf_end_i         ( app_wdf_end         )
    ,.app_wdf_rdy_o         ( app_wdf_rdy         )
    ,.app_rd_data_valid_o   ( app_rd_data_valid   )
    ,.app_rd_data_o         ( app_rd_data         )
    ,.app_rd_data_end_o     ( app_rd_data_end     )
    
    ,.init_calib_complete_o ( init_calib_complete )

    ,.ddr_ck_p_o            ( ddr_ck_p            )
    ,.ddr_ck_n_o            ( ddr_ck_n            )
    ,.ddr_cke_o             ( ddr_cke             )
    ,.ddr_ba_o              ( ddr_ba              )
    ,.ddr_addr_o            ( ddr_addr            )
    ,.ddr_cs_n_o            ( ddr_cs_n            )
    ,.ddr_ras_n_o           ( ddr_ras_n           )
    ,.ddr_cas_n_o           ( ddr_cas_n           )
    ,.ddr_we_n_o            ( ddr_we_n            )
    ,.ddr_reset_n_o         ( ddr_reset_n         )
    ,.ddr_odt_o             ( ddr_odt             )

    ,.ddr_dm_oen_o          ( ddr_dm_oen_lo       )
    ,.ddr_dm_o              ( ddr_dm_lo           )
    ,.ddr_dqs_p_oen_o       ( ddr_dqs_p_oen_lo    )
    ,.ddr_dqs_p_ien_o       ( ddr_dqs_p_ien_lo    )
    ,.ddr_dqs_p_o           ( ddr_dqs_p_lo        )
    ,.ddr_dqs_p_i           ( ddr_dqs_p_li        )
    ,.ddr_dqs_n_oen_o       ( ddr_dqs_n_oen_lo    )
    ,.ddr_dqs_n_ien_o       ( ddr_dqs_n_ien_lo    )
    ,.ddr_dqs_n_o           ( ddr_dqs_n_lo        )
    ,.ddr_dqs_n_i           ( ddr_dqs_n_li        )
    ,.ddr_dq_oen_o          ( ddr_dq_oen_lo       )
    ,.ddr_dq_o              ( ddr_dq_lo           )
    ,.ddr_dq_i              ( ddr_dq_li           )

    ,.ui_clk_i              ( ui_clk              )
    ,.ui_reset_o            ( ui_clk_sync_rst     )
    ,.ext_dfi_clk_2x_i      ( dfi_clk             )
    ,.dfi_clk_1x_o          ( dfi_clk_1x          )
    ,.dfi_clk_2x_o          ( dfi_clk_2x          )
    
    ,.trace_ready_o         (trace_ready_li)
    ,.trace_data_i          (trace_data_lo)
    ,.trace_v_i             (trace_v_lo)
    
    ,.trace_data_o          (trace_data_li)
    ,.trace_v_o             (trace_v_li)
    ,.trace_yumi_i          (trace_yumi_lo)

    ,.calib_clk_monitor_o   (calib_clk_monitor_lo)
    ,.stall_transactions_o  (stall_transactions_lo)
    ,.transaction_in_progress_o (transaction_in_progress_lo)
    ,.refresh_in_progress_o (refresh_in_progress_lo)
    ,.test_mode_o           (test_mode_lo)

    ,.tag_clk_i             (tag_clk_lo)
    ,.tag_data_i            (tag_data_lo)
    ,.tag_node_id_offset_i  (tag_node_id_offset_li)

    );

  generate
    for(i=0;i<dq_group_lp;i++) begin: dm_io
      assign ddr_dm[i]       = !ddr_dm_oen_lo[i]? ddr_dm_lo[i]: 1'bz;
    end
    for(i=0;i<dq_group_lp;i++) begin: dqs_io
      assign ddr_dqs_p[i]    = !ddr_dqs_p_oen_lo[i]? ddr_dqs_p_lo[i]: 1'bz;
      assign ddr_dqs_p_li[i] = !ddr_dqs_p_ien_lo[i]? ddr_dqs_p[i]: 1'b0;
      assign ddr_dqs_n[i]    = !ddr_dqs_n_oen_lo[i]? ddr_dqs_n_lo[i]: 1'bz;
      assign ddr_dqs_n_li[i] = !ddr_dqs_n_ien_lo[i]? ddr_dqs_n[i]: 1'b1;
    end
    for(i=0;i<dq_data_width_p;i++) begin: dq_io
      assign ddr_dq[i]    = !ddr_dq_oen_lo[i]? ddr_dq_lo[i]: 1'bz;
      assign ddr_dq_li[i] = ddr_dq[i];
    end
  endgenerate

  generate
    for(i=0;i<2;i++) begin: lpddr
      mobile_ddr mobile_ddr_inst
        (.Dq    (ddr_dq[16*i+15:16*i])
        ,.Dqs   (ddr_dqs_p[2*i+1:2*i])
        ,.Addr  (ddr_addr[13:0])
        ,.Ba    (ddr_ba[1:0])
        ,.Clk   (ddr_ck_p)
        ,.Clk_n (ddr_ck_n)
        ,.Cke   (ddr_cke)
        ,.Cs_n  (ddr_cs_n)
        ,.Ras_n (ddr_ras_n)
        ,.Cas_n (ddr_cas_n)
        ,.We_n  (ddr_we_n)
        ,.Dm    (ddr_dm[2*i+1:2*i]));
    end
  endgenerate

  initial begin
	  irritate_clock = 0;
      send_dynamic_tag = 0;
	  if($test$plusargs("irritate_clk")) begin
      	#212us;
	  	irritate_clock = 1;
	  	#0.5us;
	  	irritate_clock = 0;
	  	@(frequency_mismatch_lo);
      	send_dynamic_tag = 1;
	  	@(clock_correction_done_lo);
	  	send_dynamic_tag = 0;
	 end
  end
endmodule
