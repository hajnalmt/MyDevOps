#!/usr/bin/expect
#
# A TCL, Expect script for the list-like return handling
##############################################################################

# -----------------------------------------------------------------------------
# Return
#   Handles list-like returns.
# -----------------------------------------------------------------------------
proc ::Return { args } {
    set return_code {*}$args
    #If nothing was returned then we handle it as everything went fine
    if { [llength $return_code] == 0 } {
        return 0
    }
    #If there is no error return the remaining elements of the list
    if { [lindex $return_code 0] eq 0 } {
        if { [llength $return_code] == 2 } {
            return [lindex $return_code 1]
        } else {
            return [lrange $return_code 1 end]
        }
    } else {
        #Jump out of the stack frame if needed."
        if { [info level] == 1 } {
            return 1
        } else {
            return -level 2 1
        }
    }
}
