#####################################################
## OpenROAD Basic Floorplan Flow
#####################################################

source bsg_chip_pkg.tcl
source bsg_pearls_setup.tcl
source bsg_design_setup.tcl

# Must set these environment variables, everything else is optional (hopefully)
set BSG_PEARLS_TCL_DIR   $::env(BSG_PEARLS_TCL_DIR)
set BSG_DESIGN_TCL_DIR   $::env(BSG_DESIGN_TCL_DIR)
set BSG_LOG_LEVEL        $::env(BSG_LOG_LEVEL)
source ${BSG_PEARLS_TCL_DIR}/bsg_utils.tcl
source ${BSG_PEARLS_TCL_DIR}/openroad_utils.tcl

#####################################################
## BSG
#####################################################
set BSG_DESIGN_FLOORPLAN_SCRIPT ${BSG_DESIGN_TCL_DIR}/floorplan.tcl

#####################################################
## openroad
#####################################################
bsg_openroad_setup_init ${BSG_LOG_LEVEL}

set PDK_ROOT [bsg_get_env PDK_ROOT]
set PDK [bsg_get_env PDK]
set PDK_LIB [bsg_get_env PDK_LIB]
set PDK_CORNER [bsg_get_env PDK_CORNER]

set TECHMAP_ROOT ${PDK_ROOT}/${PDK}/libs.tech
set TECHLIB_ROOT ${PDK_ROOT}/${PDK}/libs.ref

set HARD_NSOURCES [bsg_get_env HARD_NSOURCES]

set DESIGN [bsg_get_env DESIGN]
set NETLIST [bsg_get_env NETLIST]
set SDC [bsg_get_env SDC]

set design ${DESIGN}
set netlist ${NETLIST}
set sdc ${SDC}
bsg_design_init ${design}

#####################################################
## STEP: library
#####################################################
set step library
bsg_pr_info "Running step: ${step}"

bsg_pr_info "Reading PDK libs"
set all_libs [glob ${TECHLIB_ROOT}/${PDK_LIB}/lib/*${PDK_CORNER}.lib]
bsg_pr_debug "LIBS: ${all_libs}"
read_liberty ${all_libs}

bsg_pr_info "Reading PDK tech lef and lef"
set all_lefs [glob ${TECHLIB_ROOT}/${PDK_LIB}/techlef/${PDK_LIB}*.tlef]
lappend all_lefs [glob ${TECHLIB_ROOT}/${PDK_LIB}/lef/*${PDK_LIB}.lef]
bsg_pr_debug "LEFS: ${all_lefs}"
foreach l ${all_lefs} {
    read_lef $l
}

bsg_pr_info "Reading hard nsources"
foreach n ${HARD_NSOURCES} {
    read_verilog [file tail $n]
}

bsg_pr_info "Reading netlist"
read_verilog $netlist

bsg_pr_info "Linking design"
link_design $design

bsg_pr_info "Reading SDC"
read_sdc ${SDC}

#####################################################
## STEP: floorplan
#####################################################
set step floorplan
bsg_pr_info "Running step: ${step}"

bsg_source_if_exists ${BSG_DESIGN_FLOORPLAN_SCRIPT}
exit
