
proc bsg_get_pinports { name } {
    set ports [get_ports -quiet ${name}]
    if {[sizeof_collection ${ports}] > 0} {
        bsg_pr_debug "${name} found at port [bsg_get_name ${ports}]"
        return ${ports}
    }
    
    bsg_pr_warn "${name} cannot be found"
    return {}
}

proc bsg_unwrap_pinports { p } {

    set p [get_ports $p]

    set dir [get_attribute $p direction]
    if {[string match ${dir} "out|output"]} {
        append_to_collection f [all_fanout -endpoints_only -from $p]
    } elseif {[string match ${dir} "in|input"]} {
        append_to_collection f [all_fanin -startpoints_only -to $p]
    } else {
        append_to_collection f [all_fanin -startpoints_only -to $p]
        append_to_collection f [all_fanout -endpoints_only -from $p]
    }

    if {[sizeof_collection $f] > 0} {
        bsg_pr_debug "(returning f) F: $f P: $p"
        return $f
    } else {
        bsg_pr_debug "(returning p) F: $f P: $p"
        return $p
    }
}

proc bsg_tag_bus_create { name root prefix } {
    set tag [dict create]

    dict set tag name ${name}
    dict set tag root ${root}

    dict set tag p_clk_name ${root}${prefix}clk_i
    dict set tag p_data_name ${root}${prefix}data_i
    dict set tag p_offset_name ${root}${prefix}node_id_offset_i[*]

    return ${tag}
}

proc bsg_tag_bus_populate { tag } {
    set root [dict get ${tag} root]
    dict set tag p_clk [bsg_unwrap_pinports [dict get ${tag} p_clk_name]]
    dict set tag p_data [bsg_unwrap_pinports [dict get ${tag} p_data_name]]
    dict set tag p_offset [bsg_unwrap_pinports [dict get ${tag} p_offset_name]]

    return ${tag}
}

proc bsg_tag_bus_constrain { tag period_ns } {
    dict set tag period_ns ${period_ns}

    set clk_name "[dict get ${tag} name]_clk"
    set clk_src [dict get ${tag} p_clk]
    set clk [bsg_clock_create ${clk_name}]
    set clk [bsg_clock_populate ${clk} ${clk_src}]
    set clk [bsg_clock_constrain ${clk} ${period_ns}] 

    set clk_name [dict get ${clk} name]
    set clk_period_ns [dict get ${clk} period_ns]
    set ps_data_in {}
    append_to_collection ps_data_in [dict get ${tag} p_data]
    append_to_collection ps_data_in [dict get ${tag} p_offset]

    set idelay_per_max 60.0
    set idelay_per_min 40.0
    set idelay_max_ns [expr ${clk_period_ns}*${idelay_per_max}/100.0]
    set idelay_min_ns [expr ${clk_period_ns}*${idelay_per_min}/100.0]
    set_input_delay -clock ${clk_name} -max ${idelay_max_ns} ${ps_data_in} -source_latency_included -network_latency_included
    set_input_delay -clock ${clk_name} -min ${idelay_min_ns} ${ps_data_in} -source_latency_included -network_latency_included

    return ${tag}
}

proc bsg_clock_create { name } {
    set clk [dict create]

    dict set clk name ${name}

    return ${clk}
}

proc bsg_clock_populate { clk p_src } {

    dict set clk p_src ${p_src}
    dict set clk p_src_name [bsg_get_name ${p_src}]

    return ${clk}
}

proc bsg_clock_constrain { clk period_ns } {
    set name [dict get ${clk} name]
    set p_src [dict get ${clk} p_src]
    set uncertainty_ns 0.020; # Global

    set existing_clocks [get_attribute -quiet ${p_src} clocks]
    set existing_name [get_attribute -quiet ${existing_clocks} name]
    set existing_period_ns [get_attribute ${existing_clocks} period]
    if {[sizeof_collection ${existing_clocks}] > 0} {
        bsg_pr_info "Reusing existing ${existing_period_ns}ns clock at [get_attribute ${p_src} full_name]"
        if {${existing_period_ns} != ${period_ns}} {
            bsg_pr_warn "Existing period ${existing_period_ns} does not match requested period ${period_ns}"
        }
        dict set clk name ${existing_name}
        dict set clk period_ns ${existing_period_ns}
    } else {
        bsg_pr_info "Creating ${period_ns}ns clock ${name} at pin [get_attribute ${p_src} name]"
        create_clock -period ${period_ns} -name ${name} ${p_src}
        set_clock_uncertainty ${uncertainty_ns} [get_clocks ${name}]
        dict set clk name ${name}
        dict set clk period_ns ${period_ns}
    }

    return ${clk}
}

proc bsg_io_constrain { clk input output inout } {
    set clk_name [dict get ${clk} name]
    set clk_period_ns [dict get ${clk} period_ns]

    set ipins {}
    foreach_in_collection p ${input} {
        append_to_collection ipins [bsg_unwrap_pinports $p]
    }
    foreach_in_collection p ${inout} {
        append_to_collection ipins [bsg_unwrap_pinports $p]
    }

    if {[sizeof_collection ${ipins}] > 0} {
        set idelay_per_min  2.0
        set idelay_per_max 70.0
        set idelay_max_ns [expr ${clk_period_ns}*${idelay_per_max}/100.0]
        set idelay_min_ns [expr ${clk_period_ns}*${idelay_per_min}/100.0]
        set_input_delay -clock ${clk_name} -max ${idelay_max_ns} ${ipins} -add_delay
        set_input_delay -clock ${clk_name} -min ${idelay_max_ns} ${ipins} -add_delay
    }

    set opins {}
    foreach_in_collection p ${output} {
        append_to_collection opins [bsg_unwrap_pinports $p]
    }
    foreach_in_collection p ${inout} {
        append_to_collection opins [bsg_unwrap_pinports $p]
    }
    if {[sizeof_collection ${opins}] > 0} {
        set odelay_per_min  2.0
        set odelay_per_max 20.0
        set odelay_max_ns [expr ${clk_period_ns}*${odelay_per_max}/100.0]
        set odelay_min_ns [expr ${clk_period_ns}*${odelay_per_min}/100.0]
        set_output_delay -clock ${clk_name} -max ${odelay_max_ns} ${opins} -add_delay
        set_output_delay -clock ${clk_name} -min ${odelay_max_ns} ${opins} -add_delay
    }
}

proc bsg_clk_gen_pearl_create { name root inst } {
    set cgp [dict create]

    dict set cgp name ${name}
    dict set cgp root ${root}
    dict set cgp inst ${inst}

    dict set cgp p_iclk_name ${root}ext_clk_i
    dict set cgp p_disable_name ${root}async_output_disable_i
    dict set cgp p_oclk_name ${root}clk_o
    dict set cgp p_mclk_name ${root}clk_monitor_o

    set out_name "out_clk"
    dict set cgp out_clk [bsg_clock_create ${out_name}]

    set mon_name "mon_clk"
    dict set cgp mon_clk [bsg_clock_create ${mon_name}]

    set osc_name "osc_clk"
    dict set cgp osc_clk [bsg_clock_create ${osc_name}]

    set ext_name "ext_clk"
    dict set cgp ext_clk [bsg_clock_create ${ext_name}]

    set name "${name}_tag"
    set root "${root}"
    set prefix "tag_"
    dict set cgp tagbus [bsg_tag_bus_create ${name} ${root} ${prefix}]

    return ${cgp}
}

proc bsg_clk_gen_pearl_populate { cgp } {
    set root [dict get ${cgp} root]
    set inst [dict get ${cgp} inst]

    dict set cgp p_iclk [get_ports [dict get ${cgp} p_iclk_name]]
    dict set cgp p_disable [get_ports [dict get ${cgp} p_disable_name]]
    dict set cgp p_oclk [get_ports [dict get ${cgp} p_oclk_name]]
    dict set cgp p_mclk [get_ports [dict get ${cgp} p_mclk_name]]

    set mux_inst [get_cells ${root}clk_gen_inst/mux_inst]
    dict set cgp mux_inst ${mux_inst}

    set mon_inst [get_cells ${root}monitor]
    dict set cgp mon_inst ${mon_inst}

    set fb_inst [get_cells ${root}clk_gen_inst/clk_gen_osc_inst/osc_BSG_DONT_TOUCH/fb_dly_BSG_TIMING_DISABLE]
    dict set cgp fb_inst ${fb_inst}

    set out_clk [dict get ${cgp} out_clk]
    set out_src [get_pins -of_objects ${mux_inst} -filter "direction=~out*"]
    dict set cgp out_clk [bsg_clock_populate ${out_clk} ${out_src}]

    set mon_clk [dict get ${cgp} mon_clk]
    set mon_src [get_pins -of_objects ${mon_inst} -filter "direction=~out*"]
    dict set cgp mon_clk [bsg_clock_populate ${mon_clk} ${mon_src}]

    set osc_clk [dict get ${cgp} osc_clk]
    set osc_src [get_pins -of_objects ${fb_inst} -filter "direction=~out*"]
    dict set cgp osc_clk [bsg_clock_populate ${osc_clk} ${osc_src}]

    set ext_clk [dict get ${cgp} ext_clk]
    set ext_pin [dict get ${cgp} p_iclk]
    dict set cgp ext_clk [bsg_clock_populate ${ext_clk} ${ext_pin}]

    set tagbus [dict get ${cgp} tagbus]
    dict set cgp tagbus [bsg_tag_bus_populate ${tagbus}]

    return ${cgp}
}

proc bsg_clk_gen_pearl_constrain { cgp osc_period_ns ext_period_ns tag_period_ns } {
    dict set cgp osc_period_ns ${osc_period_ns}
    dict set cgp ext_period_ns ${ext_period_ns}

    set out_clk [dict get ${cgp} out_clk]
    set out_period_ns ${osc_period_ns}
    dict set cgp out_clk [bsg_clock_constrain ${out_clk} ${out_period_ns}]

    set mon_clk [dict get ${cgp} mon_clk]
    set mon_period_ns ${ext_period_ns}
    dict set cgp mon_clk [bsg_clock_constrain ${mon_clk} ${mon_period_ns}]

    set osc_clk [dict get ${cgp} osc_clk]
    dict set cgp osc_clk [bsg_clock_constrain ${osc_clk} ${osc_period_ns}]

    set ext_clk [dict get ${cgp} ext_clk]
    dict set cgp ext_clk [bsg_clock_constrain ${ext_clk} ${ext_period_ns}]

    set tagbus [dict get ${cgp} tagbus]
    dict set cgp tagbus [bsg_tag_bus_constrain ${tagbus} ${tag_period_ns}]

    set ext_clk [dict get ${cgp} ext_clk]
    set ps_data_in [dict get ${cgp} p_disable]
    bsg_io_constrain ${ext_clk} ${ps_data_in} {} {}

    # generate from DS clock
    set_output_delay -clock out_clk 0.0 [get_ports clk_o]
    # generate from LSFR
    set_output_delay -clock out_clk 0.0 [get_ports clk_monitor_o]

    set_false_path -from [get_ports [dict get ${cgp} p_disable_name]]

    set mux_inst [dict get ${cgp} mux_inst]
    set_case_analysis 1 [get_pins -of_objects ${mux_inst} -filter "name=~sel_i[0]"]
    set_case_analysis 0 [get_pins -of_objects ${mux_inst} -filter "name=~sel_i[1]"]
    
    set cg_name [dict get ${cgp} name]_group
    set_clock_groups -name ${cg_name} \
        -asynchronous \
        -group [dict get ${ext_clk} name] \
        -group [dict get ${osc_clk} name] \
        -group [dict get ${out_clk} name] \
        -group [dict get ${mon_clk} name]

    return ${cgp}
}

#########################################
# The actual constraints
#########################################
proc bsg_design_constrain { design } {
    set name cgp; # clock gen pearl
    set root "chip/"
    set inst ""

    set osc_period_ns 10.0; # 100 MHz
    set ext_period_ns 100.0; # 10 MHz
    set tag_period_ns 50.0; # 20 MHz

    set cgp [bsg_clk_gen_pearl_create ${name} ${root} ${inst}]
    set cgp [bsg_clk_gen_pearl_populate ${cgp}]
    set cgp [bsg_clk_gen_pearl_constrain ${cgp} ${osc_period_ns} ${ext_period_ns} ${tag_period_ns}]

    return ${cgp}
}

