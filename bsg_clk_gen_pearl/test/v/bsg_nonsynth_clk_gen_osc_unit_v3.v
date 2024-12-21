
module bsg_rp_clk_gen_osc_v3_row
 (input    async_reset_neg_i
  , input  async_set_neg_i
  , input  clkgate_i
  , input  clkdly_i
  , input  clkfb_i
  , input  ctl_i
  , output clk_o
  );

  wire lobit = 1'b0;
  wire hibit = 1'b1;

  logic ctl_r;
  always_ff @(posedge clkgate_i or negedge async_set_neg_i or negedge async_reset_neg_i)
    if (~async_set_neg_i)
      ctl_r <= 1'b1;
    else if (~async_reset_neg_i)
      ctl_r <= 1'b0;
    else
      ctl_r <= ctl_i;

  wire ctl_en = ~(clkdly_i & ctl_r);
  wire fb = ~(clkfb_i & hibit);
  wire clk = ~(fb & ctl_en);

  assign #50ps clk_o = clk;

endmodule

