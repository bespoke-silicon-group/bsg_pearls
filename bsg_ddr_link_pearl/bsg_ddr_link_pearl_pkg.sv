
package bsg_ddr_link_pearl_pkg;

  import bsg_tag_pkg::*;
  import bsg_link_pkg::*;
  import bsg_clk_gen_pearl_pkg::*;

  typedef struct packed
  {
    bsg_clk_gen_pearl_tag_lines_s io_clk_gen;
    bsg_link_ddr_tag_lines_s      ddr;
  }  bsg_ddr_link_pearl_tag_lines_s;
  localparam bsg_ddr_link_pearl_tag_local_els_gp =
    $bits(bsg_ddr_link_pearl_tag_lines_s)/$bits(bsg_tag_s);

endpackage

