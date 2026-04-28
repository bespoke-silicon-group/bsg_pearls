
package bsg_sdr_link_pearl_pkg;

  import bsg_tag_pkg::*;
  import bsg_link_pkg::*;

  typedef struct packed
  {
    bsg_tag_s                link_o_disable;
    bsg_tag_s                link_i_disable;
    bsg_link_sdr_tag_lines_s sdr;
  }  bsg_sdr_link_pearl_tag_lines_s;
  localparam bsg_sdr_link_pearl_tag_local_els_gp =
    $bits(bsg_sdr_link_pearl_tag_lines_s)/$bits(bsg_tag_s);

endpackage

