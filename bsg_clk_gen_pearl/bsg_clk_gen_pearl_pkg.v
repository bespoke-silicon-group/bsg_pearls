package bsg_clk_gen_pearl_pkg;

  import bsg_tag_pkg::*;

  typedef struct packed
  {
    bsg_tag_s monitor_reset;
    bsg_tag_s sel;
    bsg_tag_s ds;
    bsg_tag_s osc_trigger;
    bsg_tag_s osc;
    bsg_tag_s async_reset;
  }  bsg_clk_gen_pearl_tag_lines_s;
  localparam bsg_clk_gen_pearl_tag_local_els_gp =
    $bits(bsg_clk_gen_pearl_tag_lines_s) / $bits(bsg_tag_s);

endpackage
