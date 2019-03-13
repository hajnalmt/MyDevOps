#!/usr/bin/expect
#
# A TCL, Expect script for an include functionality.
##############################################################################

#Check if this file has been sourced already or not
if { [namespace exists include] } {
    return 1
}

# -----------------------------------------------------------------------------
# namespace include
#   Include functionality for sourcing a file once if possible.
#   Refer to DGP http://wiki.tcl.tk/1113.
# -----------------------------------------------------------------------------
namespace eval include {
    namespace export include
    variable sources
    array set sources { }

    proc include file {
        # Remaining exercise for the next reader.  Adapt argument
        # processing to support the -rsrc and -encoding options
        # that [::source] provides
        variable sources

        if {![info exists sources([file normalize $file])]} then {
              # don't catch errors, since that may indicate we failed to load it...?
              # We don't know what command is [source] in the caller's context,
              # so fully qualify to get the [::source] we want.
              uplevel 1 [list ::source $file]
              # mark it as loaded since it was source'd with no error...
             set sources([file normalize $file]) 1
        }
    }
}
namespace import include::include

