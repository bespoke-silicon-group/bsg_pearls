
`include "bsg_defines.sv"

module bsg_launch_sync_sync #(parameter `BSG_INV_PARAM(width_p)
                              , parameter use_negedge_for_launch_p = 0
                              , parameter use_async_reset_p = 0
                              , parameter harden_p=0)
   (input iclk_i
    , input iclk_reset_i
    , input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] iclk_data_o // after launch flop
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

  for (genvar i = 0; i < width_p; i++)
    begin : u
      if (use_async_reset_p == 0)
        begin : async
          if (use_negedge_for_launch_p == 0)
            begin : pos
              bsg_dff_reset
               #(.width_p(1), .harden_p(harden_p))
               lnch
                (.clk_i(iclk_i)
                 ,.reset_i(iclk_reset_i)
                 ,.data_i(iclk_data_i[i])
                 ,.data_o(iclk_data_o[i])
                 );
            end
          else
            begin : neg
              bsg_dff_negedge_reset
               #(.width_p(1), .harden_p(harden_p))
               lnch
                (.clk_i(iclk_i)
                 ,.reset_i(iclk_reset_i)
                 ,.data_i(iclk_data_i[i])
                 ,.data_o(iclk_data_o[i])
                 );
            end

      	  bsg_sync_sync_unit
      	   #(.harden_p(harden_p))
      	   bss
      	    (.oclk_i(oclk_i)
      	     ,.iclk_data_i(iclk_data_o[i])
      	     ,.oclk_data_o(oclk_data_o[i])
      	     );
        end
      else
	    begin : sync
	      if (use_negedge_for_launch_p == 0)
			begin : pos
              bsg_dff_async_reset
               #(.width_p(1), .harden_p(harden_p))
               lnch
                (.clk_i(iclk_i)
                 ,.async_reset_i(iclk_reset_i)
                 ,.data_i(iclk_data_i[i])
                 ,.data_o(iclk_data_o[i])
                 );
			end
		  else
			begin : neg
              bsg_dff_negedge_async_reset
               #(.width_p(1), .harden_p(harden_p))
               lnch
                (.clk_i(iclk_i)
                 ,.async_reset_i(iclk_reset_i)
                 ,.data_i(iclk_data_i[i])
                 ,.data_o(iclk_data_o[i])
                 );
			end

	      bsg_sync_sync_async_reset_unit
           #(.harden_p(harden_p))
           bss
            (.oclk_i(oclk_i)
             ,.iclk_reset_i(iclk_reset_i)
             ,.iclk_data_i(iclk_data_o[i])
             ,.oclk_data_o(oclk_data_o[i])
             );
	    end
	end

endmodule

`BSG_ABSTRACT_MODULE(bsg_launch_sync_sync)

