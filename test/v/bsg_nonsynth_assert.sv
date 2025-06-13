
//`define BSG_NONSYNTH_ASSERT_ENABLE

`include "bsg_defines.sv"

module bsg_nonsynth_assert
  (input                clk_i
   , input              reset_i
   , input              en_i
   );

`ifdef BSG_NONSYNTH_ASSERT_ENABLE
  initial
    begin
      $display("Turning off assertions at time [%t]", $time);
      $assertoff();
      @(posedge clk_i);
      @(negedge reset_i);
      wait (en_i);
      $display("Turning on assertions at time [%t]", $time);
      $asserton();
    end
`endif

endmodule

