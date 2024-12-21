
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
    bsg_pr_info "Renaming module ${curr_name} -> ${new_name}"
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

    bsg_pr_info "Renaming top to ${new_top}"
    yosys rename -top ${new_top}

    set new_file ${design}.${step}.v
    yosys write_verilog -nostr -noattr -noexpr -nohex -nodec ${new_file}
}

proc bsg_yosys_read_design_slang { design vsources vdefines vincludes vparams } {
    set slang_cmd "yosys read_slang"
    foreach def ${vdefines} {
        append slang_cmd " -D${def}"
    }
    foreach inc ${vincludes} {
        append slang_cmd " -I${inc}"
    }
    foreach param ${vparams} {
        append slang_cmd " -G ${param}"
    }

    bsg_pr_info "Ingesting the design with slang"
    append slang_cmd " --top ${design}"
    append slang_cmd " --ignore-initial"
    append slang_cmd " --ignore-timing"
    append slang_cmd " --ignore-unknown-modules"
    append slang_cmd " --best-effort-hierarchy"
    bsg_pr_debug "Slang cmd:\n\t${slang_cmd}"
    eval ${slang_cmd} {{*}${vsources}}
}

# Leaving for posterity, but not used at the moment
proc bsg_yosys_unwrap_design { wrapper design } {
    bsg_pr_info "Unwrapping ${wrapper}"
    yosys select N:${wrapper}/* t:*${design}* %i %M
    yosys tee -q -o $::G_TEMP_FILE select -list %
    yosys select -clear
    set curr_top [exec -- head -n 1 $::G_TEMP_FILE]
    bsg_yosys_rename_module ${curr_top} ${design}

    bsg_pr_info "Generating wrapper verilog"
    yosys select ${wrapper}
    yosys write_verilog -selected -nostr -noattr -noexpr -nohex -nodec ${wrapper}.wrapper.v
    set sed_command "s|${design}|`BSG_CHIP_DUT_NAME|g"
    exec -- sed -i ${sed_command} ${design}.wrapper.v
    yosys select -clear

    yosys delete ${wrapper}
    bsg_pr_info "Deleting ${wrapper}"

    return ${design}
}

# Leaving for posterity, but not used at the moment
proc bsg_yosys_strip_modules { wrapper design } {
    bsg_pr_info "Stripping module names"
    yosys tee -q -o $::G_TEMP_FILE select N:* N:${wrapper} %d -list-mod
    set module_list [split [read [open $::G_TEMP_FILE r]] "\n"]
    set sed_command "s|\$${design}\\.\[^\\.\]*\\.|.|"
    exec -- sed -i ${sed_command} $::G_TEMP_FILE
    set stripped_lines [open $::G_TEMP_FILE r]
    foreach module ${module_list} {
        if {${module} == ""} continue;
        gets ${stripped_lines} stripped_name
        puts "Stripping auto-generated name ${module} -> ${stripped_name}"
        bsg_yosys_rename_module ${module} ${stripped_name}
    }
}

