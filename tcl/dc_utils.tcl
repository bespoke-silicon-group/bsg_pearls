
variable G_WORK_DIR

proc bsg_dc_setup_init { log_level } {
    bsg_logging_init ${log_level}

    set ::G_WORK_DIR WORK
    bsg_pr_info "Setting global WORK_DIR as $::G_WORK_DIR"

    # TODO: make into options
    set_host_options -max_cores 4
    set_app_var sh_continue_on_error false

    # Suppress net is connecting multiple ports warning
    suppress_message UCN-1
    # Suppress specified replacement character conflicting
    suppress_message UCN-4
    # We always use DesignWare
    suppress_message UISN-40
    # Suppress BSG_ABSTRACT_MODULE warning
    suppress_message VER-988

    set_app_var timing_enable_multiple_clocks_per_reg false
    set_app_var hdlin_ff_always_sync_set_reset true
    set_app_var hdlin_ff_always_async_set_reset false

    set_app_var verilogout_no_tri true
    set_app_var hdlin_autoread_verilog_extensions {}
    set_app_var hdlin_autoread_sverilog_extensions {.v .sv}

    set_app_var compile_preserve_subdesign_interfaces true
    set_app_var link_portname_allow_period_to_match_underscore true

    exec mkdir $::G_WORK_DIR
    define_design_lib WORK -path $::G_WORK_DIR
}

proc bsg_dc_convert_libs { libs } {
    set all_dbs {}
    bsg_pr_info "Beginning .db generation"
    foreach lib ${libs} {
        set fbasename [file rootname [file tail ${lib}]]
        set lib_path [set lib]
        set lib_file "${fbasename}.lib"
        set db_file "$::G_WORK_DIR/${fbasename}.db"
        bsg_pr_info "Converting ${lib_file} to ${db_file}"
        set lc_cmd "read_lib {${lib_path}};"
        append lc_cmd " write_lib ${fbasename} -format db -output ${db_file}; "
        append lc_cmd "exit; "
        bsg_pr_debug "Running cmd: lc_shell ${lc_cmd}"
        exec -- lc_shell -64bit -x "${lc_cmd}"
        lappend all_dbs ${db_file}
    }

    return ${all_dbs}
}

proc bsg_dc_unwrap_design { design wrapper } {
    bsg_pr_info "Unwrapping ${wrapper}"
    set design_ref [get_attribute [get_cells * -filter "hdl_template=~${design}"] ref_name]
    rename_design ${design_ref} ${design}
    current_design ${design}
    bsg_pr_info "Toplevel is now ${design}"

    bsg_pr_info "Generating wrapper verilog"
    write_file -format verilog -output ${design}.wrapper.v ${wrapper}
    set sed_command "s|${design}|`BSG_CHIP_DUT_NAME|g"
    exec -- sed -i ${sed_command} ${design}.wrapper.v

    bsg_pr_info "Deleting ${wrapper}"
    remove_design ${wrapper}

    return ${design}
}

proc bsg_dc_save_step { design step } {
    set new_top ${design}_${step}
    set new_prefix [bsg_str_to_prefix ${new_top}]

    bsg_pr_info "Renaming designs with prefix ${new_prefix}"
    set all_designs [get_designs *]
    foreach_in_collection d ${all_designs} {
        set module [get_attribute $d name]
        set old_prefix [lindex [split ${module} "_"] 0]
        set new_name [string map [list ${old_prefix} ${new_prefix}] ${module}]
        bsg_pr_debug "Renaming ${old_prefix} ${module} to ${new_name}"
        rename_design ${module} ${new_name}
    }

    bsg_pr_info "Renaming top to ${new_top}"
    rename_design [current_design] ${new_top}

    set new_file ${design}.${step}.v
    set_fix_multiple_port_nets -all -buffer_constants
    define_name_rules verilog -add_dummy_nets
    change_names -rules verilog -hierarchy -verbose
    write_file -format verilog -hierarchy -output ${new_file}
}

proc _bsg_get_name_impl { cells } {
    return [get_attribute ${cells} name]
}

proc _bsg_get_full_name_impl { cells } {
    return [get_attribute ${cells} full_name]
}

proc _bsg_dont_touch_cells_impl { cells } {
    set_dont_touch ${cells}    
}

proc _bsg_dont_gate_cells_impl { cells} {
    set_clock_gating_objects -exclude ${cells}
}

proc _bsg_set_ungroup_cells_impl { cells } {
    set_ungroup ${cells}
}

proc _bsg_set_size_only_impl { cells } {
    foreach_in_collection c ${cells} {
        if {[get_attribute $c is_hierarchical]} {
            set leafs [get_cells "[bsg_get_full_name $c]/*"]
            _bsg_set_size_only_impl ${leafs}
        } else {
            set_size_only -all_instances $c
        }
    }
}

proc _bsg_set_disable_timing_impl { cells } {
    foreach_in_collection c ${cells} {
        set_disable_timing $c
    }
}

proc _bsg_set_synchronizer_impl { cells } {
    foreach_in_collection s1 ${cells} {
        set cpins [get_pins -of_objects ${s1} -filter "direction==in&&is_clock_pin==true"]
        set ipins [get_pins -of_objects ${s1} -filter "direction==in&&is_data_pin==true"]
        set opins [get_pins -of_objects ${s1} -filter "direction==out"]
        
        set oclk [get_attribute ${cpins} clocks]
        set operiod_ns [get_attribute ${oclk} period]
        set max_delay_ns [expr ${operiod_ns} / 2]
        set min_delay_ns [expr ${operiod_ns} / -10]

        set_max_delay ${max_delay_ns} -to ${ipins} -ignore_clock_latency
        set_min_delay ${min_delay_ns} -to ${ipins} -ignore_clock_latency
    }
}

