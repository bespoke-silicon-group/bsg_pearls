
`include "bsg_defines.sv"

module bsg_nonsynth_test_rom_plusargs
 #(parameter `BSG_INV_PARAM(data_width_p)
   , parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(plusargs_str_p)
   , parameter hex_not_bin_p = 0
   )
  (
   input [addr_width_p-1:0] addr_i
   , output logic [data_width_p-1:0] data_o
   );

  localparam els_lp = 2**addr_width_p;

  logic [data_width_p-1:0] rom [0:els_lp-1];

  string memfile;
  initial
    if ($value$plusargs({plusargs_str_p,"=%s"}, memfile))
      if (hex_not_bin_p)
        $readmemh(memfile, rom);
      else
        $readmemb(memfile, rom);
    else
      $warning("BSG-WARN: No memfile specified for plusargs_str: %s", plusargs_str_p);

  assign data_o = rom[addr_i];

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_test_rom_plusargs)

