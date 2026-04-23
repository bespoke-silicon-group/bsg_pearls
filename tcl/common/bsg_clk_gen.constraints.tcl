puts "Info: Start script [info script]\n"

proc bsg_clk_gen_clock_create { osc_path clk_name clk_gen_period_int clk_gen_period_ext osc_uncertainty ds_uncertainty clk_uncertainty} {
  # very little is actually timed with this domain; just the receive
  # side of the bsg_tag_client and the downsampler.
  #
  # Although the fastest target period of the oscillator itself is below
  # this, we don't want this support logic to not be able to keep up
  # in the event that oscillator runs faster than the tools say
  #

  # this is for the output of the downsampler, goes to the clock selection mux
  set clk_gen_period_ds [expr $clk_gen_period_int * 2.0]

  set clk_osc_out_pin [get_pins -leaf -of_objects [get_nets ${osc_path}osc_clk_out] -filter "pin_direction==out"]

  set osc_clk_name ${clk_name}_osc_clk
  set ds_clk_name ${clk_name}_ds_clk
  set out_clk_name ${clk_name}_out_clk
  set int_clk_name ${clk_name}_int_clk
  set mon_clk_name ${clk_name}_mon_clk

  echo "Detecting Version 1/2 of bsg_clk_gen"
  set buf_btc_o_search [sizeof_collection [get_pins -quiet ${osc_path}clk_gen_osc_inst/fdt/buf_btc_o]]
  set col_search [sizeof_collection [get_cells -quiet ${osc_path}clk_gen_osc_inst/osc_BSG_DONT_TOUCH/col_0_BSG_DONT_TOUCH]]
  echo $buf_btc_o_search
  # for version 1 bsg_clk_gen
  if { $buf_btc_o_search } {
    echo "Detected Version 1 of bsg_clk_gen"
    # this is for the output of the oscillator, which goes to the osc's bt client
    create_clock -period $clk_gen_period_int -name ${clk_name}_btc [get_pins ${osc_path}clk_gen_osc_inst/fdt/buf_btc_o]
    # clock domains being crossed into via bsg_tag
    bsg_tag_add_client_cdc_timing_constraints $bsg_tag_clk_name ${clk_name}_btc
  } elseif { $col_search } {
    echo "Detected Version 3 of bsg_clk_gen"
    set clk_osc_out_src [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects [get_cells -of_objects $clk_osc_out_pin] -filter "pin_direction==in"]] -filter "pin_direction==out"]
    create_clock -period $clk_gen_period_int -name ${osc_clk_name} $clk_osc_out_src
    set_clock_uncertainty $osc_uncertainty [get_clocks ${osc_clk_name}]
  } else {
    echo "Detected Version 2 of bsg_clk_gen"
    # this is for the output of the oscillator, which goes to the downsampler
    create_clock -period $clk_gen_period_int -name ${osc_clk_name} $clk_osc_out_pin
    set_clock_uncertainty $osc_uncertainty [get_clocks ${osc_clk_name}]

    # if we do this, it adds lots of buffers which is a big problem.
    #create_clock -period $clk_gen_period_int -name ${clk_name}_btc [get_pins ${osc_path}/clk_gen_osc_inst/fdt/o]
    # clock domains being crossed into via bsg_tag
    #bsg_tag_add_client_cdc_timing_constraints $bsg_tag_clk_name ${clk_name}_btc
  }

  # these are generated clocks; we call them clocks to get preferred shielding and routing
  # nothing is actually timed with these
  #create_clock -period $clk_gen_period_ds -name ${clk_name}_ds_clk [get_pins -leaf -of_objects [get_nets ${osc_path}ds_clk_out] -filter "pin_direction==out"]
  #set_clock_uncertainty $ds_uncertainty [get_clocks ${clk_name}_ds_clk]
  set ds_out_pin [get_pins -leaf -of_objects [get_nets ${osc_path}ds_clk_out] -filter "pin_direction==out"]
  set ds_in_pin [get_pins -of_objects [get_cells -of_objects $ds_out_pin] -filter "is_data_pin==true"]
  set ds_ck_pin [get_pins -of_objects [get_cells -of_objects $ds_out_pin] -filter "is_clock_pin==true"]
  #create_generated_clock -name $ds_clk_name -divide_by 2 -source $ds_ck_pin $ds_out_pin
  set ds_mux_pin [get_pins -of_objects [get_nets ${osc_path}mux_inst/data_i[1][0]]]
  create_generated_clock -name $ds_clk_name -divide_by 2 -source $ds_ck_pin $ds_mux_pin
  set ds_sel_pins [get_pins ${osc_path}clk_gen_ds_inst/val_i[*]]
  set_case_analysis 0 $ds_sel_pins

  # the output of the mux is the externally visible bonafide clock
  create_clock -period $clk_gen_period_ext -name $out_clk_name [get_pins -leaf -of_objects [get_nets ${osc_path}clk_o] -filter "pin_direction==out"]
  set_clock_uncertainty $clk_uncertainty [get_clocks $out_clk_name]

  # select downsampler statically
  set_case_analysis 1 [get_pins -of_objects [get_nets ${osc_path}select_i[0]]]
  set_case_analysis 0 [get_pins -of_objects [get_nets ${osc_path}select_i[1]]]
}

puts "Info: Completed script [info script]\n"
