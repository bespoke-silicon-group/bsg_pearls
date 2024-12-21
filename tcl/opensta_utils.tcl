
proc bsg_opensta_setup_init { log_level } {
    bsg_logging_init ${log_level}

    bsg_pr_info "Aliasing get_fanx to all_fanx"
    interp alias {} all_fanout {} get_fanout
    interp alias {} all_fanin  {} get_fanin
}

proc sizeof_collection { coll } {
    return [llength ${coll}]
}

proc get_attribute { coll attr } {
    set alist {}
    
    foreach c ${coll} {
        if {[string match "clocks" ${attr}]} {
            bsg_pr_warn "'clocks' is not a supported attribute, returning empty"
        } elseif {[string match "name" ${attr}]} {
            lappend alist [get_name $c]
        } elseif {[string match "name" ${attr}]} {
            lappend alist [get_full_name $c]
        } elseif {[string match "*_Port" $c]} {
            lappend alist [get_property -object_type port $c ${attr}]
        } elseif {[string match "*_Pin" $c]} {
            lappend alist [get_property -object_type pin $c ${attr}]
        } elseif {[string match "*_Net" $c]} {
            lappend alist [get_property -object_type net $c ${attr}]
        } elseif {[string match "*_Instance" $c]} {
            lappend alist [get_property -object_type cell $c ${attr}]
        } else {
            bsg_pr_error "Unrecognized instance type $c"
        }
    }

    return ${alist}
}

proc add_to_collection { coll x } {
    lappend coll {*}$x

    return ${coll}
}

proc append_to_collection { coll x } {
    upvar 1 ${coll} local
    lappend local {*}$x
}

proc foreach_in_collection { item coll body } {
    upvar 1 ${item} element
    set size [llength ${coll}]
    for {set i 0} {$i < ${size}} {incr i} {
        set element [lindex ${coll} ${i}]
        uplevel 1 ${body}
    }
}

