
# Global arrays for various parameters and settings
variable G_BSG_INFO

# 0: error
# 1: error, warn
# 2: error, warn, info (default)
# 3: error, warn, info, debug
# 99: absolutely everything
variable E_BSG_LOG_LEVEL_ERROR 0
variable E_BSG_LOG_LEVEL_WARN  1
variable E_BSG_LOG_LEVEL_INFO  2
variable E_BSG_LOG_LEVEL_DEBUG 3
variable E_BSG_LOG_LEVEL_FORCE 99
variable G_BSG_LOG_LEVEL

proc _bsg_pr_level { arg level } {
    if {$::G_BSG_INFO(BSG_LOG_LEVEL) >= ${level}} {
        puts "${arg}"
    }
}

proc bsg_pr_debug { arg { level "" } } {
    if {$level eq ""} { set level $::E_BSG_LOG_LEVEL_DEBUG }
    _bsg_pr_level "\[BSG-DEBUG\]: ${arg}" ${level}
}

proc bsg_pr_info { arg { level "" } } {
    if {$level eq ""} { set level $::E_BSG_LOG_LEVEL_INFO }
    _bsg_pr_level "\[BSG-INFO\]: ${arg}" ${level}
}

proc bsg_pr_warn { arg { level "" } } {
    if {$level eq ""} { set level $::E_BSG_LOG_LEVEL_WARN }
    _bsg_pr_level "\[BSG-WARN\]: ${arg}" ${level}
}

proc bsg_pr_error { arg { level "" } } {
    if {$level eq ""} { set level $::E_BSG_LOG_LEVEL_ERROR }
    _bsg_pr_level "\[BSG-ERROR\]: ${arg}" ${level}
}

proc bsg_get_env { var {def "xxundefxx"} } {
    if {[info exists ::env(${var})]} {
        set val $::env(${var})
        set src env
    } elseif {${def} ne "xxundefxx"} {
        set val ${def}
        set src def
    } else {
        bsg_pr_error "${var} could not be resolved from environment or default"
        return -code error "Exiting..."
    }
    bsg_pr_debug "${var} getting ${src} value ${val}"

    return ${val}
}

proc bsg_source_if_exists { filename } {
    if {[file exists ${filename}]} {
        bsg_pr_info "sourcing ${filename}"
        source ${filename}
    } else {
        bsg_pr_info "${filename} not present, skipping..."
    }
}

proc bsg_str_to_prefix { str } {
    set words [split ${str} "_"]
    set prefix ""

    foreach word ${words} {
        append prefix [string index ${word} 0]
    }
    bsg_pr_debug "Generating prefix ${prefix} from ${str}"

    return ${prefix}
}

proc bsg_source_swap { vpkg vsources hard_vsources hard_nsources } {
    set final_vsources {}
    foreach p ${vpkg} {
        bsg_pr_info "Reading package $p"
        bsg_pr_debug "\t from $p"
        lappend final_vsources $p
    }
    foreach v ${vsources} {
        set swap 0
        foreach h ${hard_vsources} {
            set v_tail [file tail $v]
            set h_tail [file tail $h]
    
            if {${v_tail} == ${h_tail}} {
                set swap 1
            }
        }
    
        if {!${swap}} {
            bsg_pr_info "Adding source: ${v_tail}"
            bsg_pr_debug "\t from $v"
            lappend final_vsources $v
        }
    }
    foreach h ${hard_vsources} {
        set h_tail [file tail $h]
        bsg_pr_info "Adding hardened source: ${h_tail}"
        bsg_pr_debug "\t from $h"
        lappend final_vsources $h
    }
    foreach n ${hard_nsources} {
        set n_tail [file tail $n]
        bsg_pr_info "Adding hardened netlist: ${n_tail}"
        bsg_pr_debug "\t from $n"
        lappend final_vsources $n
    }

    return ${final_vsources}
}

proc bsg_design_init { design_name } {
    set ::G_BSG_INFO(DESIGN_NAME) ${design_name}
    bsg_pr_info "Initializing ${design_name}" $::E_BSG_LOG_LEVEL_FORCE
}

proc bsg_logging_init { level } {
    set ::G_BSG_INFO(BSG_LOG_LEVEL) ${level}
    bsg_pr_info "G_BSG_LOG_LEVEL set to ${level}" $::E_BSG_LOG_LEVEL_FORCE
    bsg_pr_info "Logging is now live..." $::E_BSG_LOG_LEVEL_FORCE
}

proc _uniq { } {
    # Make a unique id by using pid and current history index
    regexp {^\s+(\d+)} [history -r 1] junk uniqid
    return "[pid] ${uniqid}"
}

proc _open_editor { shell editor args } {
    set tmpfile .tmp4edt[pid][_uniq].swp
    set edtfile [lindex [split ${args}] 0]
    if {[info commands ${edtfile}] ne ""} {
        # This is command, execute and open the result
        # Without redirect, exec echos the PID of the new process to the screen
        # We use catch to run in background without errors
        redirect ${tmpfile} { uplevel ${args} }
        set edtfile ${tmpfile}
    } elseif {[llength args] > 1} {
        puts "Error: vim tcl proc cannot open more than 1 file"
    }

    set cmd "${editor} --nofork ${edtfile}; sleep 1; rm -f ${tmpfile};"
    redirect /dev/null { catch { exec ${shell} -c ${cmd} & } }
}

proc gvim { args } {
    set shell /bin/sh
    set editor gvim
    _open_editor ${shell} ${editor} ${args}
}

proc emacs { args } {
    set shell /bin/sh
    set editor emacs
    _open_editor ${shell} ${editor} ${args}
}

proc bsg_constraints_bleach { } {
    bsg_pr_info "Resetting constraints"
    remove_clock -all
    remove_generated_clock -all
    remove_clock_group -all -physically_exclusive
    remove_clock_group -all -logically_exclusive
    remove_clock_group -all -asynchronous
}

proc bsg_get_name { args } {
    return [_bsg_get_name_impl ${args}]
}

proc bsg_get_full_name { args } {
    return [_bsg_get_full_name_impl ${args}]
}

proc bsg_dont_touch_cells_regex { regex } {
    set cells [get_cells -quiet -hier -regexp "${regex}"]
    if {[sizeof_collection ${cells}]} {
        bsg_pr_info "Setting dont_touch on ${regex}"
        bsg_pr_debug "\t[bsg_get_name ${cells}]"
        _bsg_dont_touch_cells_impl ${cells}
    }
    set ::G_BSG_INFO(CELLS_DONT_TOUCH) ${cells}
}

proc bsg_dont_gate_cells_regex { regex } {
    set cells [get_cells -quiet -hier -regexp "${regex}"]
    if {[sizeof_collection ${cells}]} {
        bsg_pr_info "Setting dont_gate on ${regex}"
        bsg_pr_debug "\t[bsg_get_name ${cells}]"
        _bsg_dont_gate_cells_impl ${cells}
    }
    set ::G_BSG_INFO(CELLS_DONT_GATE) [bsg_get_full_name ${cells}]
}

proc bsg_set_ungroup_cells_regex { regex } {
    set cells [get_cells -quiet -hier -regexp "${regex}"]
    if {[sizeof_collection ${cells}]} {
        bsg_pr_info "Setting ungroup on ${regex}"
        bsg_pr_debug "\t[bsg_get_name ${cells}]"
        _bsg_set_ungroup_cells_impl ${cells}
    }
    set ::G_BSG_INFO(CELLS_UNGROUP) [bsg_get_full_name ${cells}]
}

proc bsg_set_size_only_regex { regex } {
    set cells [get_cells -quiet -hier -regexp "${regex}"]
    if {[sizeof_collection ${cells}]} {
        bsg_pr_info "Setting resize_only on ${regex}"
        bsg_pr_debug "\t[bsg_get_name ${cells}]"
        _bsg_set_size_only_impl ${cells}
    }
    set ::G_BSG_INFO(CELLS_SIZE_ONLY) [bsg_get_full_name ${cells}]
}

proc bsg_set_disable_timing_regex { regex } {
    set cells [get_cells -quiet -hier -regexp "${regex}"]
    if {[sizeof_collection ${cells}]} {
        bsg_pr_info "Setting disable_timing on ${regex}"
        bsg_pr_debug "\t[bsg_get_name ${cells}]"
        _bsg_set_disable_timing_impl ${cells}
    }
    set ::G_BSG_INFO(CELLS_DISABLE_TIMING) [bsg_get_full_name ${cells}]
}

proc bsg_set_synchronizer_regex { regex } {
    set cells [get_cells -quiet -hier -regexp "${regex}"]
    if {[sizeof_collection ${cells}]} {
        bsg_pr_info "Setting synchronizer on ${regex}"
        bsg_pr_info "\t(CDC constraints still required)"
        bsg_pr_debug "\t[bsg_get_name ${cells}]"
        _bsg_set_synchronizer_impl ${cells}
    }
    set ::G_BSG_INFO(CELLS_SYNCHRONIZER) [bsg_get_full_name ${cells}]
}

