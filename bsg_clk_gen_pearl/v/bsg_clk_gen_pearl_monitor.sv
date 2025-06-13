
module bsg_clk_gen_pearl_monitor
  (input           clk_i
   , input         reset_i
   , output logic  monitor_o
   );

  logic clkbuf_lo;
  bsg_clkbuf
   #(.width_p(1), .harden_p(1))
   ibuf
    (.i(clk_i)
     ,.o(clkbuf_lo)
     );

  logic clk_div_lo;
  bsg_clk_gen_pearl_lfsr_div30
   lfsr
    (.clk_i(clkbuf_lo)
     ,.reset_i(reset_i)
     ,.clk_div_o(clk_div_lo)
     );

  logic monitor_lo;
  bsg_clkbuf
   #(.width_p(1), .harden_p(1))
   obuf
    (.i(clk_div_lo)
     ,.o(monitor_lo)
     );
  assign monitor_o = monitor_lo;

endmodule

