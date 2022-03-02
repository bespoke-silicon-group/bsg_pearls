
# bsg_write_file
proc bsg_write_file {floc flist} {
  set f $floc
  set fid [open $f "w"]
  foreach item $flist {
    puts $fid $item
  }
  close $fid
}

# bsg_get_length
proc bsg_get_length {flist} {
  if {[info exists flist]} {
    return [llength $flist]
  }
}

# bsg_create_filelist
proc bsg_create_filelist {filelist source_files} {
  bsg_write_file $filelist $source_files
}

# bsg_create_library, include_paths arg is optional
proc bsg_create_library {library_name library_file source_files {include_paths ""}} {

  # header
  lappend library_list "library $library_name"

  # source files
  set len [bsg_get_length $source_files]
  set i 0
  foreach f $source_files {
    if {$i == [expr $len - 1]} {
      lappend library_list "$f"
    } else {
      lappend library_list "$f,"
    }
    incr i
  }

  # include paths
  set len [bsg_get_length $include_paths]
  if {$len > 0} {
    lappend library_list "-incdir"
  }
  set i 0
  foreach f $include_paths {
    if {$i == [expr $len - 1]} {
      lappend library_list "$f"
    } else {
      lappend library_list "$f,"
    }
    incr i
  }

  # footer
  lappend library_list ";"

  # write library
  bsg_write_file $library_file $library_list
}

proc bsg_list_diff {full_list base_list} {
  foreach elem $full_list {dict set x $elem 1}
  foreach elem $base_list {dict unset x $elem}
  return [dict keys $x]
}

