module bsg_clk_gen_pearl_lfsr_div30
  (input          clk_i
   , input        reset_i
   , output logic clk_div_o
   );

  logic [3:0] data_r;
  logic out_r;
  assign clk_div_o = out_r;

  // synopsys sync_set_reset "reset_i"
  always_ff @(posedge clk_i)
  begin
    if (reset_i)
      begin
        data_r[1] <= 1'b1;
        out_r     <= 1'b0;
      end
    else
      begin
        data_r[1] <= data_r[2];
        out_r     <= (~(| data_r[2:0]) ^ out_r);
      end
    data_r[0] <= data_r[1];
    data_r[2] <= data_r[0] ^ data_r[3];
    data_r[3] <= data_r[0];
  end

endmodule

