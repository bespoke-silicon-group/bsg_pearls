
module bsg_clk_gen_pearl_monitor
 import bsg_tag_pkg::*;
  (input bsg_tag_s bsg_tag_i
   , input         clk_i
   , output logic  clk_monitor_o
   );

  logic clk_buf_lo;
  bsg_clk_gen_pearl_monitor_clk_buf
   monitor_clk_buf
    (.i(clk_i)
     ,.o(clk_buf_lo)
     );

  logic reset_lo;
  bsg_tag_client
   #(.width_p(1))
   btc_monitor_reset
    (.bsg_tag_i(bsg_tag_i)
     ,.recv_clk_i(clk_i)

     ,.recv_new_r_o()
     ,.recv_data_r_o(reset_lo)
     );

  bsg_clk_gen_pearl_lfsr_div30
   monitor_ds
    (.clk_i(clk_buf_lo)
     ,.reset_i(reset_lo)
     ,.clk_div_o(clk_monitor_o)
     );

endmodule

