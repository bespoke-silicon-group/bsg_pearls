
`include "bsg_defines.sv"

module bsg_sync_sync #(parameter `BSG_INV_PARAM(width_p), parameter harden_p=0)
   (
      input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

  for (genvar i = 0; i < width_p; i++)
    begin : u
      bsg_sync_sync_unit
       #(.harden_p(harden_p))
       unit
        (.oclk_i(oclk_i)
         ,.iclk_data_i(iclk_data_i[i])
         ,.oclk_data_o(oclk_data_o[i])
         );
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_sync_sync)

