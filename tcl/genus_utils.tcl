
variable G_WORK_DIR

proc bsg_genus_setup_init { log_level } {
    bsg_logging_init ${log_level}

    set_db max_cpus_per_server 4
    set_db information_level 7

    set_db hdl_unconnected_value 0
    suppress_message LBR-9; # decaps have no output

}

proc bsg_genus_unwrap_design { wrapper design } {
    bsg_pr_info "Unwrapping ${wrapper}"
    set top [get_cells *]
    set_db $top .ungroup true
    ungroup -simple $top
    bsg_pr_info "Toplevel is now ${design}"
    return ${design}
}

proc bsg_genus_save_step { design step } {
    set new_top ${design}_${step}
    set new_prefix [bsg_str_to_prefix ${new_top}]

    bsg_pr_info "Renaming designs with prefix ${new_prefix}"
    set all_designs [get_db modules]
    foreach_in_collection d ${all_designs} {
        set module [get_db $d .name]
        set old_prefix [lindex [split ${module} "_"] 0]
        set new_name [string map [list ${old_prefix} ${new_prefix}] ${module}]
        bsg_pr_debug "Renaming ${old_prefix} ${module} to ${new_name}"
        rename_obj -flexible [get_db modules ${module}] ${new_name}
    }

    bsg_pr_info "Renaming top to ${new_top}"
    rename_obj [current_design] ${new_top}

    set new_file ${design}.${step}.v
    write_hdl > ${new_file}
}

proc _bsg_get_cells_impl { regex } {
    set cells [get_cells -quiet -hier -regex $regex]
    return $cells
}

proc _bsg_get_name_impl { cells } {
    return [get_db "${cells}" .full_name]
}

proc _bsg_dont_touch_cells_impl { cells } {
    set_db [get_pins -of_objects ${cells} -filter "is_data_pin==true"] .dont_touch true
}

proc _bsg_dont_gate_cells_impl { cells } {
    set_db ${cells} .lp_clock_gating_exclude true
}

proc _bsg_set_ungroup_cells_impl { cells } {
    set_db ${cells} .ungroup true
}

proc _bsg_set_size_only_impl { cells } {
    set_db ${cells} .dont_touch size_ok
}

proc _bsg_set_disable_timing_impl { cells } {
    set_disable_timing ${cells}
}

proc _bsg_set_synchronizer_impl { cells } {
    set ipins [get_pins -of_objects ${cells} -filter "direction==in&&is_data_pin==true"]
    set opins [get_pins -of_objects ${cells} -filter "direction==out"]
    set_false_path -to   ${ipins} -hold -setup
    set_false_path -from ${opins} -hold
}

proc _bsg_constrain_synchronizer_impl { cells } {
    bsg_pr_info "constraining synchronizers"
    foreach_in_collection s1 ${cells} {
        set cpins [get_pins -of_objects ${s1} -filter "direction==in&&is_clock_pin==true"]
        set ipins [get_pins -of_objects ${s1} -filter "direction==in&&is_data_pin==true"]
        set opins [get_pins -of_objects ${s1} -filter "direction==out"]

        set launch_src [all_fanin -flat -to $ipins]
        set launch_clk [get_db $launch_src .clocks]
        set latch_clk [get_db $cpins .clocks]
        set launch_period_ns [lindex [get_db $launch_clk .period] 0]
        set latch_period_ns [lindex [get_db $latch_clk .period] 0]
        set max_delay_ns [expr min($launch_period_ns, $latch_period_ns) / 2.0]
        set min_delay_ns 0

        set_max_delay $max_delay_ns -from $launch_clk -to $latch_clk -ignore_clock_latency
        set_min_delay $min_delay_ns -from $launch_clk -to $latch_clk -ignore_clock_latency

        set_false_path -to      ${ipins} -hold -setup
        set_false_path -through ${opins} -hold
    }
}

