#####################################################
## OpenSTA Basic Timing Flow
#####################################################

# Must set these environment variables, everything else is optional (hopefully)
set BSG_CHIP_TCL_DIR   $::env(BSG_CHIP_TCL_DIR)
set BSG_DESIGN_TCL_DIR $::env(BSG_DESIGN_TCL_DIR)
set BSG_LOG_LEVEL      $::env(BSG_LOG_LEVEL)
source ${BSG_CHIP_TCL_DIR}/bsg_utils.tcl
source ${BSG_CHIP_TCL_DIR}/opensta_utils.tcl

#####################################################
## OpenSTA
#####################################################
bsg_opensta_setup_init ${BSG_LOG_LEVEL}

#####################################################
## STEP: bsg
#####################################################
set step bsg
bsg_pr_info "Setting up design environment"
set BSG_DESIGN_SETUP_SCRIPT [bsg_get_env BSG_DESIGN_SETUP_SCRIPT design_setup.tcl]

bsg_pr_info "Reading hooks"
set BSG_DESIGN_CONSTRAINTS_SCRIPT [bsg_get_env BSG_DESIGN_CONSTRAINTS_SCRIPT ${BSG_DESIGN_TCL_DIR}/constraints.tcl]

#####################################################
## STEP: design
#####################################################
set step design
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_SETUP_SCRIPT}

set PDK_ROOT [bsg_get_env PDK_ROOT]
set PDK [bsg_get_env PDK]
set PDK_LIB [bsg_get_env PDK_LIB]
set PDK_CORNER [bsg_get_env PDK_CORNER]

set DESIGN [bsg_get_env DESIGN]
set TOP_MODULE [bsg_get_env TOP_MODULE]
set SYN_NETLIST [bsg_get_env SYN_NETLIST]
set TEMP_NETLIST [bsg_get_env TEMP_NETLIST]
set HARD_NSOURCES [bsg_get_env HARD_NSOURCES]

#####################################################
## STEP: library
#####################################################
set step library
bsg_pr_info "Running step: ${step}"

set TECHMAP_ROOT ${PDK_ROOT}/${PDK}/libs.tech
set TECHLIB_ROOT ${PDK_ROOT}/${PDK}/libs.ref

set all_libs [glob ${TECHLIB_ROOT}/*/lib/*${PDK_CORNER}.lib]

bsg_pr_info "Reading liberty files"
foreach l ${all_libs} {
    bsg_pr_debug "Reading liberty file: $l"
    read_liberty $l
}

set final_netlist ${SYN_NETLIST}
set final_nsources ${HARD_NSOURCES}

set netlist_name ${TEMP_NETLIST}
set yosys_cmd ""
foreach n ${final_nsources} {
    append yosys_cmd "read_verilog $n; "
}
append yosys_cmd "read_verilog ${final_netlist}; "
append yosys_cmd "write_verilog -nostr -noattr -noexpr -nohex -nodec ${netlist_name}; "

bsg_pr_info "Converting hard netlist sources ${final_nsources}"
bsg_pr_debug "yosys_cmd -> ${yosys_cmd}"
exec -- yosys -p "${yosys_cmd}"

#####################################################
## STEP: elab
#####################################################
set step elab
bsg_pr_info "Running step: ${step}"

bsg_pr_info "Reading consolidated netlist ${netlist_name}"
read_verilog ${netlist_name}

set top_module ${TOP_MODULE}
bsg_pr_info "Linking design with toplevel ${top_module}"
link_design ${top_module}

#####################################################
## STEP: constrain
#####################################################
set step constrain
bsg_pr_info "Running step: ${step}"

bsg_pr_info "Sourcing constraints"
bsg_source_if_exists ${BSG_DESIGN_CONSTRAINTS_SCRIPT}

set design ${DESIGN}
bsg_pr_info "Constraining design: ${design}"
bsg_design_constrain {} {}

bsg_pr_info "Creating path groups"
group_path -name R2R -from [all_registers] -to [all_registers]
group_path -name R2O -from [all_registers] -to [all_outputs]
group_path -name I2R -from [all_inputs -no_clocks] -to [all_registers]
group_path -name I2O -from [all_inputs -no_clocks] -to [all_outputs]

#####################################################
## STEP: report
#####################################################
set step report
bsg_pr_info "Running step ${step}"

set design ${DESIGN}
bsg_pr_info "Reporting checks for design ${design}"
check_setup -verbose -unconstrained_endpoints > ${design}.check.unconstrained.rpt
check_setup -verbose -multiple_clock          > ${design}.check.multiclock.rpt
check_setup -verbose -no_clock                > ${design}.check.no_clock.rpt
check_setup -verbose -no_input_delay          > ${design}.check.no_idelay.rpt
check_setup -verbose -generated_clocks        > ${design}.check.genclock.rpt

bsg_pr_info "Reporting path delays"
report_checks -path_delay min_max > ${design}.minmax.rpt

bsg_pr_info "Reporting path groups"
foreach group [list R2R R2O I2R I2O] {
    report_checks -format full_clock -path_group ${group} > ${design}.timing.${group}.rpt
}

bsg_pr_info "Reporting per-clock delays"
foreach c [all_clocks] {
    set name [get_name $c]
    bsg_pr_debug "Reporting for clock ${name}"
    report_checks -from $c > ${design}.timing.${name}.rpt
}

bsg_pr_info "Writing final SDC"
write_sdc -gzip ${design}.sdc.gz

bsg_pr_info "Writing final lib"
write_timing_model -library_name ${design} -cell_name ${design} ${design}.lib

#exit

