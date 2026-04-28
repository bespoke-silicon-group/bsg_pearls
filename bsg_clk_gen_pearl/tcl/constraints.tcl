
source $::env(BSG_PEARLS_TCL_DIR)/common/bsg_clk_gen.constraints.tcl
source $::env(BSG_PEARLS_TCL_DIR)/common/bsg_tag.constraints.tcl

#########################################
# The actual constraints
#########################################
proc bsg_design_constrain { hier } {
    puts "Constraining bsg_clk_gen_pearl at $hier"

    set ext_clk_name           "ext_clk"
    set ext_clk_period_ns      0.666 ; # 1.5 GHz
    set ext_clk_uncertainty_ns 0.100 ; # 100 ps

    set tag_clk_name "tag_clk"
    set tag_clk_period_ns 10 ; # 100 MHz
    set tag_clk_uncertainty_ns 0.100 ; # 100 ps

    set tag_clk_pin [get_pins $hier/tag_clk_i]
    set tag_data_pin [get_pins $hier/tag_data_i]
	set tag_node_pin [get_pins $hier/tag_node_id_offset_i[*]]
    set ext_clk_pin [get_pins $hier/ext_clk_i]
    set monitor_pin [get_pins $hier/clk_monitor_o]
    set output_pin [get_pins $hier/clk_o]
    set disable_pin [get_pins $hier/async_output_disable_i]

    set ext_clk_src [all_fanin -startpoints_only -to $ext_clk_pin]
    set tag_clk_src [all_fanin -startpoints_only -to $tag_clk_pin]
    set tag_data_src [all_fanin -startpoints_only -to $tag_data_pin]
	set tag_node_src [all_fanin -startpoints_only -to $tag_node_pin]
    set disable_src [all_fanin -startpoints_only -to $disable_pin]

    set output_sink [all_fanout -endpoints_only -from $output_pin]
    set monitor_sink [all_fanout -endpoints_only -from $monitor_pin]

	set clk_gen_inst "$hier/clk_gen_inst/"
    set gen_clk_name "gen"

	######################################################
	## Reg2Reg
	######################################################
    # Create the external clock
    create_clock -name $ext_clk_name -period $ext_clk_period_ns $ext_clk_src
    set_clock_uncertainty $ext_clk_uncertainty_ns [get_clocks $ext_clk_name]

	# Constrain the oscillator
	bsg_clk_gen_clock_create \
		$clk_gen_inst \
        $gen_clk_name \
        $ext_clk_period_ns \
        $ext_clk_period_ns \
        $ext_clk_uncertainty_ns \
        $ext_clk_uncertainty_ns \
        $ext_clk_uncertainty_ns

	# Constrain the tag bus
    bsg_tag_clock_create \
        $tag_clk_name \
        $tag_clk_src \
        $tag_data_src \
        $tag_node_src \
        $tag_clk_period_ns \
        $tag_clk_uncertainty_ns
    
	######################################################
	## In2Reg
	######################################################

    set_input_delay -clock [get_clock $ext_clk_name] [expr $ext_clk_period_ns / 2.0] $disable_src
    set_false_path -from $disable_src
    set_false_path -from $tag_node_src

	######################################################
	## Reg2Out
	######################################################

    set_output_delay -clock [get_clock $ext_clk_name] 0.0 $output_sink
    set_output_delay -clock [get_clock $ext_clk_name] 0.0 $monitor_sink
    set_false_path -to $output_sink
    set_false_path -to $monitor_sink

	######################################################
	## DRV
	######################################################

    set_load -min [load_of [get_lib_pin $::env(PDK_LOAD_MIN)]] [all_outputs]
    set_load -max [load_of [get_lib_pin $::env(PDK_LOAD_MAX)]] [all_outputs]

    set_driving_cell -min -lib_cell $::env(PDK_DRIVER_MIN) [all_inputs]
    set_driving_cell -max -lib_cell $::env(PDK_DRIVER_MAX) [all_inputs]
}

