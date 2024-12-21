
variable G_WORK_DIR

proc bsg_genus_setup_init { log_level } {
    bsg_logging_init ${log_level}

    # TODO: make into options
    set_db max_cpus_per_server 4
    set_db information_level 7

    set_db hdl_unconnected_value 0
    set_db iopt_ultra_optimization true
    set_db lp_insert_clock_gating true
}

proc _bsg_get_name_impl { cells } {
    return [get_db ${cells} .name]
}

proc _bsg_get_full_name_impl { cells } {
    return [get_db ${cells} .full_name]
}

proc _bsg_dont_touch_cells_impl { cells } {
    set_db [get_pins -of_objects ${cells}] .dont_touch true
}

proc _bsg_dont_gate_cells_impl { cells } {
    set_db ${cells} .lp_clock_gating_exclude true
}

proc _bsg_set_ungroup_cells_impl { cells } {
    puts [get_db ${cells} .name]
    # TODO: Filter by hinst
    error
    set_db ${cells} .ungroup true
}

proc _bsg_set_size_only_impl { cells } {
    set_db ${cells} .dont_touch size_ok
}

proc _bsg_set_disable_timing_impl { cells } {
    set_disable_timing ${cells}
}

proc _bsg_set_synchronizer_impl { cells } {
    set ipins [get_pins -of_objects ${cells} -regexp "direction==in&&is_data_pin==true"]
    set opins [get_pins -of_objects ${cells} -regexp "direction==out"]
    set_false_path -to   ${ipins} -hold -setup
    set_false_path -from ${opins} -hold

    bsg_pr_info "IPINS: [get_db ${ipins} .name]"
    bsg_pr_info "OPINS: [get_db ${opins} .name]"
}

