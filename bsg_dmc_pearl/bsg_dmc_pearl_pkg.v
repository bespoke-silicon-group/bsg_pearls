
package bsg_dmc_pearl_pkg;

  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
  import bsg_clk_gen_pearl_pkg::*;

  typedef struct packed
  {
    bsg_tag_s                     monitor_ds;
    bsg_dmc_osc_tag_lines_s       osc;
    bsg_dmc_cfg_tag_lines_s       sys;
    bsg_dmc_cfg_tag_lines_s       cfg;
    bsg_dmc_dly_tag_lines_s       dly;
  }  bsg_dmc_pearl_tag_lines_s;
  localparam bsg_dmc_pearl_tag_local_els_gp = $bits(bsg_dmc_pearl_tag_lines_s) / $bits(bsg_tag_s);

endpackage

