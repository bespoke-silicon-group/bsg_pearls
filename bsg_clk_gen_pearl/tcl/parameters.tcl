
proc design_extract_vparams { gparams } {
    set my_dict [dict create {*}${gparams}]

    set vparams {}
    append vparams "ds_width_p=[dict get ${my_dict} ds_width_gp] "
    append vparams "num_taps_p=[dict get ${my_dict} num_taps_gp] "
    append vparams "tag_els_p=[dict get ${my_dict} tag_els_gp] "
    append vparams "tag_lg_width_p=[dict get ${my_dict} tag_lg_width_gp]"

    return ${vparams}
}

