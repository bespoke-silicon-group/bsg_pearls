#####################################################
## Yosys Basic Synthesis Flow
#####################################################

# Must set these environment variables, everything else is optional (hopefully)
set BSG_PEARLS_TCL_DIR   $::env(BSG_PEARLS_TCL_DIR)
set BSG_DESIGN_TCL_DIR   $::env(BSG_DESIGN_TCL_DIR)
set BSG_LOG_LEVEL        $::env(BSG_LOG_LEVEL)
source ${BSG_PEARLS_TCL_DIR}/bsg_utils.tcl
source ${BSG_PEARLS_TCL_DIR}/genus_utils.tcl

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
set WRAPPER [bsg_get_env WRAPPER]

set design ${DESIGN}
set wrapper ${WRAPPER}
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
bsg_source_if_exists ${BSG_DESIGN_CONSTRAINTS_SCRIPT}

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

bsg_pr_info "Elaborating ${wrapper}"
elaborate ${wrapper}

bsg_pr_info "Setting BSG attributes"
foreach rp ${rp_netlists} {
    set_dont_touch [get_designs "${rp}"]
}

bsg_dont_touch_cells_regex   ".*BSG_DONT_TOUCH"
bsg_dont_gate_cells_regex    ".*BSG_NO_CLOCK_GATE"
bsg_set_ungroup_cells_regex  ".*BSG_UNGROUP"
bsg_set_disable_timing_regex ".*BSG_TIMING_DISABLE"
bsg_set_size_only_regex      ".*BSG_RESIZE_OK"
bsg_set_synchronizer_regex   ".*BSG_SYNC"

if {[llength [info procs bsg_design_constrain]]} {
    set hier "chip"; # not generalized, but works for pearls
	bsg_design_constrain ${hier}
}

bsg_constrain_synchronizer_regex ".*BSG_SYNC1"

bsg_genus_unwrap_design ${wrapper} ${design}

# set default loads and drivers to satisfy warnings
# not generalized
set_load -min [load_of [get_lib_pin sky130_fd_sc_hd__buf_2/A]] [all_outputs]
set_load -max [load_of [get_lib_pin sky130_fd_sc_hd__buf_8/A]] [all_outputs]

set_driving_cell -no_design_rule -min -lib_cell sky130_fd_sc_hd__buf_2 [all_inputs]
set_driving_cell -no_design_rule -max -lib_cell sky130_fd_sc_hd__buf_8 [all_inputs]

check_timing > ${design}.check_timing.rpt

bsg_source_if_exists ${BSG_DESIGN_POSTELAB_SCRIPT}
bsg_genus_save_step ${design} ${step}

#######################################################
#### STEP: gen
#######################################################
set step gen
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREGEN_SCRIPT}

syn_generic

bsg_pr_info "Creating path_groups"
set clock_ports [filter_collection [get_db [get_db clocks] .sources] object_class==port]
group_path -name R2R -from [all_registers] -to [all_registers]
group_path -name R2O -from [all_registers] -to [all_outputs]
group_path -name I2R -from [remove_from_collection [all_inputs] ${clock_ports}] -to [all_registers]
group_path -name I2O -from [remove_from_collection [all_inputs] ${clock_ports}] -to [all_outputs]

syn_generic

check_design -all > ${design}.check_design.rpt
report_dp > ${design}.dp.rpt

bsg_pr_info "Uniquifying design"
uniquify -verbose [current_design]

### write gen design
bsg_source_if_exists ${BSG_DESIGN_POSTGEN_SCRIPT}
bsg_genus_save_step ${design} ${step}
#######################################################
#### STEP: opt
#######################################################
set step opt
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREOPT_SCRIPT}

syn_map

### write mapped design
bsg_source_if_exists ${BSG_DESIGN_POSTOPT_SCRIPT}
bsg_genus_save_step ${design} ${step}
###########################################################
######## STEP: tech
###########################################################
set step tech
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PRETECH_SCRIPT}

syn_opt

### write techmapped design
bsg_source_if_exists ${BSG_DESIGN_POSTTECH_SCRIPT}
bsg_genus_save_step ${design} ${step}
#######################################################
#### STEP: final
#######################################################
set step final
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREFINAL_SCRIPT}

report_messages
report_area -detail > ${design}.area.rpt
report_clocks > ${design}.clocks.rpt
report_timing > ${design}.timing.rpt

bsg_source_if_exists ${BSG_DESIGN_POSTFINAL_SCRIPT}
bsg_genus_save_step ${design} ${step}

bsg_pr_info "Synthesis script finished!"
exit

