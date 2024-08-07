
source $::env(BSG_DESIGNS_TARGET_DIR)/testing/tcl/bsg_config_utils.tcl

# chip source (rtl) files and include paths list
source $::env(BSG_DESIGNS_TARGET_DIR)/tcl/filelist.tcl

bsg_create_filelist $::env(BSG_CHIP_FILELIST) \
                    $SVERILOG_SOURCE_FILES

bsg_create_library $::env(BSG_CHIP_LIBRARY_NAME) \
                   $::env(BSG_CHIP_LIBRARY)      \
                   $SVERILOG_SOURCE_FILES        \
                   $SVERILOG_INCLUDE_PATHS

# testing source (rtl) files and include paths list
source $::env(BSG_DESIGNS_TARGET_DIR)/testing/tcl/filelist.tcl

bsg_create_filelist $::env(BSG_DESIGNS_TESTING_FILELIST) \
                   [bsg_list_diff $TESTING_SOURCE_FILES $SVERILOG_SOURCE_FILES] \

bsg_create_library $::env(BSG_DESIGNS_TESTING_LIBRARY_NAME) \
                   $::env(BSG_DESIGNS_TESTING_LIBRARY)      \
                   [bsg_list_diff $TESTING_SOURCE_FILES $SVERILOG_SOURCE_FILES] \
                   $TESTING_INCLUDE_PATHS
