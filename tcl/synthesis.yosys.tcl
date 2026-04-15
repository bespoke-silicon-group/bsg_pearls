#####################################################
## Yosys Basic Synthesis Flow
#####################################################

# Must set these environment variables, everything else is optional (hopefully)
set BSG_PEARLS_TCL_DIR   $::env(BSG_PEARLS_TCL_DIR)
set BSG_DESIGN_TCL_DIR   $::env(BSG_DESIGN_TCL_DIR)
set BSG_LOG_LEVEL        $::env(BSG_LOG_LEVEL)
source ${BSG_PEARLS_TCL_DIR}/bsg_utils.tcl
source ${BSG_PEARLS_TCL_DIR}/yosys_utils.tcl

#####################################################
## Tool setup
#####################################################
bsg_yosys_setup_init ${BSG_LOG_LEVEL}

#####################################################
## STEP: bsg
#####################################################
set step bsg
bsg_pr_info "Setting up design environment"
set BSG_DESIGN_SETUP_SCRIPT [bsg_get_env BSG_DESIGN_SETUP_SCRIPT design_setup.tcl]

bsg_pr_info "Reading hooks"
set BSG_DESIGN_PARAMETERS_SCRIPT [bsg_get_env BSG_DESIGN_PARAMETERS_SCRIPT ${BSG_DESIGN_TCL_DIR}/parameters.tcl]
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
set step design
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_SETUP_SCRIPT}

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
set GPARAMS [bsg_get_env GPARAMS]

set design ${DESIGN}
set wrapper ${WRAPPER}
bsg_design_init ${wrapper}

#####################################################
## STEP: library
#####################################################
set step library
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PRELIBRARY_SCRIPT}

set TECHMAP_ROOT ${PDK_ROOT}/${PDK}/libs.tech
set TECHLIB_ROOT ${PDK_ROOT}/${PDK}/libs.ref

set tiehi_cell       ${PDK_LIB}__conb_1
set tiehi_pin        HI
set tielo_cell       ${PDK_LIB}__conb_1
set tielo_pin        LO
set clkbuf_cell      ${PDK_LIB}__clkbuf_1
set clkbuf_pin       X
set buf_cell         ${PDK_LIB}__buf_1
set buf_ipin         A
set buf_opin         X

set all_libs [glob ${TECHLIB_ROOT}/*/lib/*${PDK_CORNER}.lib]
set all_techmaps [glob ${TECHMAP_ROOT}/openlane/${PDK_LIB}/*_map.v]

bsg_pr_info "Reading PDK libs ${all_libs}"
yosys read_liberty -lib -ignore_miss_dir ${all_libs}

# We handle yosys netlists a little differently, with whitebox attribute
set final_nsources ${HARD_NSOURCES}
foreach n ${final_nsources} {
    set n_tail [file tail $n]
    bsg_pr_info "Adding hardened netlist as whitebox: ${n_tail}"
    bsg_pr_debug "\t from $n"
    yosys read_verilog -setattr whitebox $n
}

bsg_source_if_exists ${BSG_DESIGN_POSTLIBRARY_SCRIPT}
#####################################################
## STEP: elab
#####################################################
set step elab
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREELAB_SCRIPT}

set final_design [string trim ${DESIGN}]
set final_wrapper [string trim ${WRAPPER}]
set final_vsources [bsg_source_swap ${VPKG} ${VSOURCES} ${HARD_VSOURCES} {}]
set final_vincludes ${VINCLUDES}
set final_vdefines [concat ${VDEFINES} BSG_NO_TIMESCALE SYNTHESIS]
set final_vparams {}
bsg_source_if_exists ${BSG_DESIGN_PARAMETERS_SCRIPT}
if {[llength [info procs design_extract_vparams]]} {
    append final_vparams [design_extract_vparams ${GPARAMS}]
}

bsg_yosys_read_design_slang \
    ${final_wrapper} \
    ${final_vsources} \
    ${final_vdefines} \
    ${final_vincludes} \
    ${final_vparams}

# elaborate design hierarchy
yosys hierarchy -check -top ${final_wrapper}

# set design as toplevel
bsg_yosys_unwrap_design ${final_wrapper} ${final_design}

# TODO: Implement each of these in genus and yosys
bsg_pr_info "ABCD"
bsg_dont_touch_cells_regex   "*BSG_DONT_TOUCH*"
bsg_dont_gate_cells_regex    "*BSG_NO_CLOCK_GATE*"
bsg_set_ungroup_cells_regex  "*BSG_UNGROUP*"
bsg_set_disable_timing_regex "*BSG_TIMING_DISABLE*"
bsg_set_size_only_regex      "*BSG_RESIZE_OK*"

# yosys is not constraint driven currently
if {[llength [info procs bsg_design_constrain]]} {
	bsg_design_constrain ${design}
}

parray ::G_BSG_INFO
exit

# write elab design
bsg_source_if_exists ${BSG_DESIGN_POSTELAB_SCRIPT}
bsg_yosys_save_step ${wrapper} ${step}
#####################################################
## STEP: gen
#####################################################
set step gen
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREGEN_SCRIPT}

# the high-level stuff
yosys proc;
yosys opt;
yosys fsm;
yosys opt;
yosys memory;
yosys opt

# write gen design
bsg_source_if_exists ${BSG_DESIGN_POSTGEN_SCRIPT}
bsg_yosys_save_step ${design} ${step}
#####################################################
## STEP: opt
#####################################################
set step opt
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREOPT_SCRIPT}

# mapping to internal cell library
yosys techmap; yosys opt
bsg_pr_debug "${all_techmaps}"
foreach tm ${all_techmaps} {
    yosys techmap -map ${tm}
}

# mapping to cell lib
yosys dfflibmap -liberty ${all_libs}

# write mapped design
bsg_source_if_exists ${BSG_DESIGN_POSTOPT_SCRIPT}
bsg_yosys_save_step ${design} ${step}
#####################################################
## STEP: tech
#####################################################
set step tech
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PRETECH_SCRIPT}

# mapping logic to cell lib
yosys abc -liberty ${all_libs}

# Set X to zero
yosys setundef -zero

# mapping constants and clock buffers to cell lib
yosys hilomap -hicell ${tiehi_cell} ${tiehi_pin} -locell ${tielo_cell} ${tielo_pin}
yosys clkbufmap -buf ${clkbuf_cell} ${clkbuf_pin}

# Split nets to single bits and map to buffers
yosys splitnets
yosys insbuf -buf ${buf_cell} ${buf_ipin} ${buf_opin}

# Clean up the design
yosys opt_clean -purge

# write techmapped design
bsg_source_if_exists ${BSG_DESIGN_POSTTECH_SCRIPT}
bsg_yosys_save_step ${design} ${step}
#####################################################
## STEP: final
#####################################################
set step final
bsg_pr_info "Running step: ${step}"
bsg_source_if_exists ${BSG_DESIGN_PREFINAL_SCRIPT}

# Check and print statistics
yosys tee -o ${design}.checks.txt check -mapped -noinit
yosys tee -o ${design}.stats.json stat -liberty ${all_libs} -tech cmos -width -json

bsg_source_if_exists ${BSG_DESIGN_POSTFINAL_SCRIPT}
bsg_yosys_save_step ${design} ${step}

bsg_pr_info "Synthesis script finished!"

