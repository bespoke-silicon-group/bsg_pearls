#####################################################
## Yosys Basic Synthesis Flow
#####################################################

# Must set these environment variables, everything else is optional (hopefully)
set BSG_CHIP_TCL_DIR   $::env(BSG_CHIP_TCL_DIR)
set BSG_DESIGN_TCL_DIR $::env(BSG_DESIGN_TCL_DIR)
set BSG_LOG_LEVEL      $::env(BSG_LOG_LEVEL)
source ${BSG_CHIP_TCL_DIR}/bsg_utils.tcl
source ${BSG_CHIP_TCL_DIR}/genus_utils.tcl

#####################################################
## dc
#####################################################
bsg_genus_setup_init ${BSG_LOG_LEVEL}

#####################################################
## STEP: bsg
#####################################################
set step bsg
bsg_pr_info "Running step: ${step}"

set BSG_DESIGN_SETUP_SCRIPT [bsg_get_env BSG_DESIGN_SETUP_SCRIPT design_setup.tcl]

bsg_pr_info "Reading hooks"
set BSG_DESIGN_PARAMETERS_SCRIPT [bsg_get_env BSG_DESIGN_PARAMETERS_SCRIPT ${BSG_DESIGN_TCL_DIR}/parameters.tcl]
set BSG_DESIGN_CONSTRAINTS_SCRIPT [bsg_get_env BSG_DESIGN_CONSTRAINTS_SCRIPT ${BSG_DESIGN_TCL_DIR}/constraints.tcl]
set BSG_DESIGN_PRELIBRARY_SCRIPT [bsg_get_env BSG_DESIGN_PRELIBRARY_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_library.tcl]

set BSG_DESIGN_PREELAB_SCRIPT [bsg_get_env BSG_DESIGN_PREELAB_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_elab.tcl]
set BSG_DESIGN_PREGEN_SCRIPT [bsg_get_env BSG_DESIGN_PREGEN_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_gen.tcl]
set BSG_DESIGN_PREOPT_SCRIPT [bsg_get_env BSG_DESIGN_PREOPT_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_opt.tcl]
set BSG_DESIGN_PRETECH_SCRIPT [bsg_get_env BSG_DESIGN_PRETECH_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_tech.tcl]
set BSG_DESIGN_PREFINAL_SCRIPT [bsg_get_env BSG_DESIGN_PREFINAL_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_final.tcl]

set BSG_DESIGN_POSTLIBRARY_SCRIPT [bsg_get_env BSG_DESIGN_POSTLIBRARY_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_library.tcl]
set BSG_DESIGN_POSTELAB_SCRIPT [bsg_get_env BSG_DESIGN_POSTELAB_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_elab.tcl]
set BSG_DESIGN_POSTGEN_SCRIPT [bsg_get_env BSG_DESIGN_POSTGEN_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_gen.tcl]
set BSG_DESIGN_POSTOPT_SCRIPT [bsg_get_env BSG_DESIGN_POSTOPT_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_opt.tcl]
set BSG_DESIGN_POSTTECH_SCRIPT [bsg_get_env BSG_DESIGN_POSTTECH_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_tech.tcl]
set BSG_DESIGN_POSTFINAL_SCRIPT [bsg_get_env BSG_DESIGN_POSTFINAL_SCRIPT ${BSG_DESIGN_TCL_DIR}/pre_final.tcl]

#####################################################
## STEP: design
#####################################################
bsg_source_if_exists ${BSG_DESIGN_SETUP_SCRIPT}
set step design

set PDK_ROOT [bsg_get_env PDK_ROOT]
set PDK [bsg_get_env PDK]
set PDK_LIB [bsg_get_env PDK_LIB]
set PDK_CORNER [bsg_get_env PDK_CORNER]

set VDEFINES [bsg_get_env VDEFINES]
set VINCLUDES [bsg_get_env VINCLUDES]
set VPKG [bsg_get_env VPKG]
set VSOURCES [bsg_get_env VSOURCES]
set HARD_VSOURCES [bsg_get_env HARD_VSOURCES]
set HARD_NSOURCES [bsg_get_env HARD_NSOURCES]

set DESIGN [bsg_get_env DESIGN]
set GPARAMS [bsg_get_env GPARAMS]

set design ${DESIGN}
bsg_design_init ${design}

#######################################################
#### STEP: library
#######################################################
set step library
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PRELIBRARY_SCRIPT}

set TECHMAP_ROOT ${PDK_ROOT}/${PDK}/libs.tech
set TECHLIB_ROOT ${PDK_ROOT}/${PDK}/libs.ref

bsg_pr_info "Reading PDK libs"
set all_libs [glob ${TECHLIB_ROOT}/${PDK_LIB}/lib/*${PDK_CORNER}.lib]
read_libs ${all_libs}

bsg_pr_info "Reading PDK tech lef and lef"
set all_lefs [glob ${TECHLIB_ROOT}/${PDK_LIB}/techlef/${PDK_LIB}*.tlef]
lappend all_lefs [glob ${TECHLIB_ROOT}/${PDK_LIB}/lef/*${PDK_LIB}.lef]
read_physical -lef ${all_lefs}

set final_nsources ${HARD_NSOURCES}
set rp_netlists {}
if {${final_nsources} != ""} {
    set num_netlists [llength ${final_nsources}]
    bsg_pr_info "Adding ${num_netlists} hardened netlists"
    bsg_pr_debug "${final_nsources}"
    read_netlist ${final_nsources}
    set rp_netlists [get_db [get_designs *] name]
    delete_obj [get_designs *]
}

bsg_source_if_exists ${BSG_DESIGN_POSTLIBRARY_SCRIPT}
###########################################################
######## STEP: elab
###########################################################
set step elab
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREELAB_SCRIPT}

set final_vincludes ${VINCLUDES}
bsg_pr_debug "Include Paths: ${final_vincludes}"
set_db init_hdl_search_path ${final_vincludes}

set final_vsources [bsg_source_swap ${VPKG} ${VSOURCES} ${HARD_VSOURCES} ${HARD_NSOURCES}]
bsg_pr_debug "Source Files: ${final_vsources}"

set design ${DESIGN}
set read_cmd "read_hdl -sv ${final_vsources} "

set final_vdefines [concat ${VDEFINES} SYNTHESIS ASIC SYNTHESIS_HARDWARE NO_DUMMY]
foreach def ${final_vdefines} {
    append read_cmd "-define ${def} "
}
bsg_pr_debug "Executing read command:\n${read_cmd}"
eval ${read_cmd}

set final_vparams {}
bsg_source_if_exists ${BSG_DESIGN_PARAMETERS_SCRIPT}
if {[llength [info procs design_extract_vparams]]} {
    foreach vparam [design_extract_vparams ${GPARAMS}] {
		set p [lindex [split ${vparam} "="] 0]
		set v [lindex [split ${vparam} "="] 1]
		lappend final_vparams [list $p $v]
	}
}

bsg_pr_info "Elaborating ${design}"
elaborate ${design} -parameters ${final_vparams}

bsg_pr_info "Setting BSG attributes"
foreach rp ${rp_netlists} {
    set_dont_touch [get_designs "${rp}"]
}

bsg_dont_touch_cells_regex   ".*BSG_DONT_TOUCH"
bsg_dont_gate_cells_regex    ".*BSG_NO_CLOCK_GATE"
bsg_set_ungroup_cells_regex  ".*BSG_UNGROUP"
bsg_set_disable_timing_regex ".*BSG_TIMING_DISABLE"
bsg_set_size_only_regex      ".*BSG_RESIZE_OK"

if {[llength [info procs bsg_design_constrain]]} {
	bsg_design_constrain ${design}
}
bsg_set_synchronizer_regex ".*BSG_SYNC1.*"
 
check_timing > ${design}.check_timing.rpt

error

bsg_pr_info "Sourcing constraints"
bsg_source_if_exists ${BSG_DESIGN_CONSTRAINTS_SCRIPT}

bsg_pr_info "Unwrapping design"
bsg_constraints_bleach
bsg_genus_save_step ${wrapper} ${design}

bsg_pr_info "Using toplevel constraints for design ${design}"
set inst {}
set root {}
bsg_design_constrain ${root} ${inst}
check_timing > ${design}.check_timing.rpt

### write elab design
bsg_source_if_exists ${BSG_DESIGN_POSTELAB_SCRIPT}
bsg_genus_save_step ${design} ${step}


####
####bsg_pr_info "Sourcing constraints"
####bsg_source_if_exists ${BSG_DESIGN_CONSTRAINTS_SCRIPT}
####
####bsg_pr_info "Testing instance constraints for design ${design}"
####set inst [get_cells * -filter "hdl_template=~${design}"]
####set name [get_attribute ${inst} full_name]
####set root "${name}/"
#####bsg_design_constrain ${root} ${inst}
#####check_timing
#####bsg_constraints_bleach
####
####bsg_pr_info "Unwrapping design"
####bsg_dc_unwrap_design ${wrapper} ${design}
####
####bsg_pr_info "Using toplevel constraints for design ${design}"
####set inst {}
####set root {}
####bsg_design_constrain ${root} ${inst}
####
####### write elab design
####bsg_source_if_exists ${BSG_DESIGN_POSTELAB_SCRIPT}
####bsg_dc_save_step ${design} ${step}
###########################################################
######## STEP: gen
###########################################################
####set step gen
####bsg_pr_info "Running step: ${step}"
####bsg_source_if_exists ${BSG_DESIGN_PREGEN_SCRIPT}
####
####bsg_pr_info "Linking design"
####link
####
####bsg_pr_info "Creating path_groups"
####set clock_ports [filter_collection [get_attribute [get_clocks] sources] object_class==port]
####group_path -name R2R -from [all_registers] -to [all_registers]
####group_path -name R2O -from [all_registers] -to [all_outputs]
####group_path -name I2R -from [remove_from_collection [all_inputs] ${clock_ports}] -to [all_registers]
####group_path -name I2O -from [remove_from_collection [all_inputs] ${clock_ports}] -to [all_outputs]
####
####bsg_pr_info "Checking design for elaboration problem"
####check_design -summary
####check_design > ${design}.check_design.rpt
####
####bsg_pr_info "Uniquifying design"
####uniquify -force
####
####### write gen design
####bsg_source_if_exists ${BSG_DESIGN_POSTGEN_SCRIPT}
####bsg_dc_save_step ${design} ${step}
###########################################################
######## STEP: opt
###########################################################
####set step opt
####bsg_pr_info "Running step: ${step}"
####bsg_source_if_exists ${BSG_DESIGN_PREOPT_SCRIPT}
####
####set compile_flags {}
####append compile_flags " -no_autoungroup"
####append compile_flags " -no_boundary_optimization"
####
####eval compile_ultra ${compile_flags}
####
####### write mapped design
####bsg_source_if_exists ${BSG_DESIGN_POSTOPT_SCRIPT}
####bsg_dc_save_step ${design} ${step}
###########################################################
######## STEP: tech
###########################################################
####set step tech
####bsg_pr_info "Running step: ${step}"
####bsg_source_if_exists ${BSG_DESIGN_PRETECH_SCRIPT}
####
####set compile_flags {}
####append compile_flags " -incremental"
####
####eval compile_ultra ${compile_flags}
####
####### write techmapped design
####bsg_source_if_exists ${BSG_DESIGN_POSTTECH_SCRIPT}
####bsg_dc_save_step ${design} ${step}
###########################################################
######## STEP: final
###########################################################
####set step final
####bsg_pr_info "Running step: ${step}"
####bsg_source_if_exists ${BSG_DESIGN_PREFINAL_SCRIPT}
####
##### Check and print statistics
####report_power -nosplit            > ${design}.mapped.power.rpt
####report_power -nosplit -hierarchy > ${design}.mapped.power_hier.rpt
####
####report_area -nosplit            > ${design}.mapped.area.rpt
####report_area -nosplit -hierarchy > ${design}.mapped.area_hier.rpt
####
####report_timing -delay_type max -path_type full_clock -max_paths 30 -transition_time -nets -attributes -nosplit > ${design}.mapped.timing.max.rpt
####report_timing -delay_type min -path_type full_clock -max_paths 30 -transition_time -nets -attributes -nosplit > ${design}.mapped.timing.min.rpt
####
####report_timing -delay_type max -path_type full_clock -max_paths 30 -transition_time -nets -attributes -nosplit > ${design}.mapped.timing.max.rpt
####report_timing -delay_type min -path_type full_clock -max_paths 30 -transition_time -nets -attributes -nosplit > ${design}.mapped.timing.min.rpt
####foreach_in_collection p [get_path_groups] {
####    set name [get_object_name $p]
####    set max_paths 30
####    report_timing -group ${name} -delay_type max -path_type full_clock -max_paths ${max_paths} -transition_time -nets -attributes -nosplit > ${design}.mapped.timing.max.${name}.rpt
####    report_timing -group ${name} -delay_type min -path_type full_clock -max_paths ${max_paths} -transition_time -nets -attributes -nosplit > ${design}.mapped.timing.min.${name}.rpt
####}
####
####report_app_var -verbose                 > ${design}.mapped.app_var.rpt
####report_cell -nosplit                    > ${design}.mapped.cell.rpt
####report_clock_gating -nosplit            > ${design}.mapped.clock_gating.rpt
####report_clock_timing -type summary       > ${design}.mapped.clock_timing.rpt
####report_constraint -verbose              > ${design}.mapped.constraint.rpt
####report_design -nosplit                  > ${design}.mapped.design.rpt
####report_hierarchy -nosplit               > ${design}.mapped.hierarchy.rpt
####report_path_group -expanded -nosplit    > ${design}.mapped.path_group.rpt
####report_qor                              > ${design}.mapped.qor.rpt
####report_reference -nosplit -hierarchy    > ${design}.mapped.reference.rpt
####report_resources -hierarchy             > ${design}.mapped.resources.rpt
####report_threshold_voltage_group -nosplit > ${design}.mapped.threshold_voltage_group.rpt
####report_units                            > ${design}.mapped.units.rpt
####
####bsg_source_if_exists ${BSG_DESIGN_POSTFINAL_SCRIPT}
####bsg_dc_save_step ${design} ${step}
####
####bsg_pr_info "Synthesis script finished!"

