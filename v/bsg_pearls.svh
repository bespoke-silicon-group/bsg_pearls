
`ifndef BSG_PEARLS_SVH
`define BSG_PEARLS_SVH

`include "bsg_defines.sv"

`define declare_bsg_tag_client_unsync(name_mp, tag_line_mp, width_mp) \
  logic [width_mp-1:0] ``name_mp``_data_async_r_lo; \
  bsg_tag_client_unsync \
   #(.width_p(width_mp)) \
   btc_``name_mp`` \
    (.bsg_tag_i(tag_line_mp) \
     ,.data_async_r_o(``name_mp``_data_async_r_lo) \
     )

`define declare_bsg_tag_client_sync(name_mp, tag_line_mp, width_mp, recv_clk_mp) \
  logic [width_mp-1:0] ``name_mp``_data_r_lo; \
  logic ``name_mp``_new_r_lo; \
  bsg_tag_client \
   #(.width_p(width_mp)) \
   btc_``name_mp`` \
    (.bsg_tag_i(tag_line_mp) \
     ,.recv_clk_i(recv_clk_mp) \
     ,.recv_new_r_o(``name_mp``_new_r_lo) \
     ,.recv_data_r_o(``name_mp``_data_r_lo) \
     )

`endif

