
variable G_WORK_DIR

proc bsg_genus_setup_init { log_level } {
    bsg_logging_init ${log_level}

    set_db max_cpus_per_server 4
    set_db information_level 7

    set_db hdl_unconnected_value 0
}

proc _bsg_get_name_impl { cells } {
    return [get_db ${cells} .full_name]
}

proc _bsg_dont_touch_cells_impl { cells } {
    bsg_pr_warn "_bsg_dont_touch_cells_impl not implemented, called on:\n\t$cells"
}

proc _bsg_dont_gate_cells_impl { cells } {
    bsg_pr_warn "_bsg_dont_gate_cells_impl not implemented, called on:\n\t$cells"
}

proc _bsg_set_ungroup_cells_impl { cells } {
    bsg_pr_warn "_bsg_set_ungroup_cells_impl not implemented, called on:\n\t$cells"
}

proc _bsg_set_size_only_impl { cells } {
    bsg_pr_warn "_bsg_set_size_only_impl not implemented, called on:\n\t$cells"
}

proc _bsg_set_disable_timing_impl { cells } {
    bsg_pr_warn "_bsg_set_disable_timing_impl not implemented, called on:\n\t$cells"
}

proc _bsg_set_synchronizer_impl { cells } {
    bsg_pr_warn "_bsg_set_synchronizer_impl not implemented, called on:\n\t$cells"
}

