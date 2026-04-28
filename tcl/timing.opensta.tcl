#####################################################
## OpenSTA Basic Timing Flow
#####################################################

source bsg_chip_pkg.tcl
source bsg_pearls_setup.tcl
source bsg_design_setup.tcl

# Must set these environment variables, everything else is optional (hopefully)
set BSG_PEARLS_TCL_DIR   $::env(BSG_PEARLS_TCL_DIR)
set BSG_DESIGN_TCL_DIR   $::env(BSG_DESIGN_TCL_DIR)
set BSG_LOG_LEVEL        $::env(BSG_LOG_LEVEL)
source ${BSG_PEARLS_TCL_DIR}/bsg_utils.tcl
source ${BSG_PEARLS_TCL_DIR}/opensta_utils.tcl

#####################################################
## opensta
#####################################################
bsg_opensta_setup_init ${BSG_LOG_LEVEL}

#####################################################
## STEP: design
#####################################################
set step design

set PDK_ROOT [bsg_get_env PDK_ROOT]
set PDK [bsg_get_env PDK]
set PDK_LIB [bsg_get_env PDK_LIB]
set PDK_CORNER [bsg_get_env PDK_CORNER]

set HARD_NSOURCES [bsg_get_env HARD_NSOURCES]

set DESIGN [bsg_get_env DESIGN]
set NETLIST [bsg_get_env NETLIST]

set design ${DESIGN}
set netlist ${NETLIST}
bsg_design_init ${design}

#####################################################
## STEP: library
#####################################################
set step library
bsg_pr_info "Running step: ${step}"

set TECHMAP_ROOT ${PDK_ROOT}/${PDK}/libs.tech
set TECHLIB_ROOT ${PDK_ROOT}/${PDK}/libs.ref

bsg_pr_info "Reading PDK libs"
set all_libs [glob ${TECHLIB_ROOT}/${PDK_LIB}/lib/*${PDK_CORNER}.lib]

bsg_pr_info "Reading liberty files"
foreach l ${all_libs} {
    bsg_pr_debug "Reading liberty file: $l"
    read_liberty $l
}

bsg_pr_info "Reading hard nsources"
foreach n ${HARD_NSOURCES} {
    read_verilog $n
}

bsg_pr_info "Reading netlist"
read_verilog $netlist


