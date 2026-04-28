
# Temporary text file used to pass yosys command output back to tcl
variable G_TEMP_FILE

proc bsg_yosys_setup_init { log_level } {
    bsg_logging_init ${log_level}

    set ::G_TEMP_FILE .temp.txt
    bsg_pr_info "Setting global G_TEMP_FILE as $::G_TEMP_FILE"

    # This is a dirty, dirty hack to order TCL output with yosys output
    rename puts tcl::puts
    proc puts { args } {
        # Flush the yosys stdout buffer
        yosys tee -q exec -- "true;"
        # Then do the normal print
        eval tcl::puts ${args}
    }
    bsg_pr_info "Dangerously renaming puts; revert before reporting bugs to anyone..."
}

proc bsg_yosys_rename_module { curr_name new_name } {
    bsg_pr_debug "Renaming module ${curr_name} -> ${new_name}"
    yosys rename ${curr_name} ${new_name}
    yosys chtype -map ${curr_name} ${new_name}
}

proc bsg_yosys_save_step { design step } {
    yosys tee -q -o $::G_TEMP_FILE select N:* A:top %d -list-mod
    set module [exec -- head -n 1 $::G_TEMP_FILE]
    set new_top ${design}_${step}
    set old_prefix [lindex [split ${module} "_"] 0]
    set new_prefix [bsg_str_to_prefix ${new_top}]
    set module_list [split [read [open $::G_TEMP_FILE r]] "\n"]
    set sed_command "s|${old_prefix}||g"
    exec -- sed -i ${sed_command} $::G_TEMP_FILE
    set sed_command "s|^|${new_prefix}|g"
    exec -- sed -i ${sed_command} $::G_TEMP_FILE
    set rename_input [open $::G_TEMP_FILE r]

    foreach module ${module_list} {
        if {${module} == ""} continue;
        gets ${rename_input} new_name
        bsg_yosys_rename_module ${module} ${new_name}
    }

    yosys write_verilog -nostr -noattr -noexpr -nohex -nodec ${design}.${step}.v
    close [open ${design}.${step}.sdc "a"]
}

proc bsg_yosys_read_design_slang { design vsources vdefines vincludes {vparams {}}} {
    set slang_cmd [list "read_slang"]
    foreach def ${vdefines} {
        lappend slang_cmd "-D${def}"
    }
    foreach inc ${vincludes} {
        lappend slang_cmd "-I${inc}"
    }
    foreach param ${vparams} {
        lappend slang_cmd "-G${param}"
    }

    bsg_pr_info "Ingesting the design with slang"
    lappend slang_cmd "--top" "${design}"
    lappend slang_cmd "--ignore-unknown-modules"
    lappend slang_cmd "--best-effort-hierarchy"

    lappend slang_cmd {*}${vsources}
    bsg_pr_debug "Slang cmd:\n\t${slang_cmd}"
    yosys {*}${slang_cmd}
}

proc bsg_yosys_unwrap_design { wrapper design } {
    bsg_pr_info "Stripping module names"
    yosys tee -q -o $::G_TEMP_FILE select N:* N:${wrapper} %d -list-mod

    set i 0
    foreach mod [split [read [open $::G_TEMP_FILE r]] "\n"] {
        incr i
        set mod [string trim $mod]
        if {[string match "*\$*" $mod]} {
            set tag ""
            set prefix [lindex [split $mod "\$"] 0]
            set suffix [lindex [split $mod "\$"] 1]
            if {[string match $design $prefix]} {
                set clean_name $prefix
            } else {
                foreach l [split $suffix "."] {
                    append tag [string index $l 0]
                }
                set clean_name ${prefix}__${tag}${i}
            }
            bsg_pr_debug "mangled: $mod -> clean: $clean_name"
            bsg_yosys_rename_module ${mod} ${clean_name}
        }
    }
    yosys hierarchy -check -top $design
}

# yosys is currently just passing cell names around
proc _bsg_get_name_impl { cells } {
    return $cells
}

proc _bsg_get_cells_impl { regex } {
    set regex [string map {".*" "*"} $regex]
    yosys tee -q -o $::G_TEMP_FILE select -list "c:${regex}"
    set cells [read [open $::G_TEMP_FILE r]]
    return $cells
}

proc sizeof_collection { coll } {
    return [llength $coll]
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

proc _bsg_constrain_synchronizer_impl { cells } {
    bsg_pr_warn "_bsg_constrain_synchronizer_impl not implemented, called on:\n\t$cells"
}

