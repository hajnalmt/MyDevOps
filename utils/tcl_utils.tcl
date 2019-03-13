#!/usr/bin/expect
#
# Description: The tcl_utils.tcl file contains expect and tcl
#   helper functions. Especially for namespaces.
#   Refer to: http://wiki.tcl.tk/1489
#
# Usage: Just source this file in your tcl script
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# listns
#   List all child namepsaces, recursively.
#
#   Parameters:
#       parentns - optional parameter, the parent namespace
#   Returns:
#       ret - child namespaces
# -----------------------------------------------------------------------------
proc listns {{parentns ::}} {
    set result [list]
    foreach ns [namespace children $parentns] {
        lappend result {*}[listns $ns] $ns
    }
    return $result
}

# -----------------------------------------------------------------------------
# listnsvars
#   List the variables in a namespace.
#
#   Parameters:
#       ns - optional parameter, namespace to search (default ::)
#   Returns:
#       ret - variables in a namespace
# -----------------------------------------------------------------------------
proc listnsvars {{ns ::}} {
    return [info vars ${ns}::*]
}

# -----------------------------------------------------------------------------
# listnsprocs
#   List the procs in a namespace.
#
#   Parameters:
#       ns - optional parameter, namespace to search (default ::)
#       specifier - optional parameter TRUE/FALSE, removes namespace specifier
#           from the output if needed (default TRUE)
#   Returns:
#       ret - variables in a namespace
# -----------------------------------------------------------------------------
proc listnsprocs {{ns ::} {specifier TRUE}} {
    set procedures [info procs ${ns}::*]
    if { $specifier } {
        return $procedures
    } else {
        set baselength [string length "${ns}::"]
        set procs ""
        foreach proc $procedures {
            lappend procs [string range $proc $baselength end]
        }
        return $procs
    }
}

# -----------------------------------------------------------------------------
# listnscommands
#   List the commands in a namespace.
#
#   Parameters:
#       ns - optional parameter, namespace to search (default ::)
#   Returns:
#       ret  - variables in a namespace
# -----------------------------------------------------------------------------
proc listnscommands {{ns ::}} {
    return [info commands ${ns}::*]
}

# -----------------------------------------------------------------------------
# valid
#   Procedure to check parameter values.
#
#   Parameters:
#       variable - variable to check
#       min - min value
#       max - max value
#   Returns:
#       0 - not valid
#       1 - valid
# -----------------------------------------------------------------------------
proc valid { var min max } {
    upvar $var my_var
    if { $my_var < $min || $my_var > $max }  {
        return 0
    }
    return 1
}

# -----------------------------------------------------------------------------
# pdict
#   Procedure to do pretty print on a dictionary.
#   Refer to: http://wiki.tcl.tk/23526.
#       - RS 2014-08-05 Here is my version, working similar to parray.
#
#   Parameters:
#       dict - dict to print
#       pattern - optional parameter, glob pattern to match the keys (default *)
# -----------------------------------------------------------------------------
proc pdict {dict {pattern *}} {
   set longest 0
   set keys [dict keys $dict $pattern]
   foreach key $keys {
      set l [string length $key]
      if {$l > $longest} {set longest $l}
   }
   foreach key $keys {
      puts [format "%-${longest}s = %s" $key [dict get $dict $key]]
   }
}

# -----------------------------------------------------------------------------
# verbose_eval
#   This procedure is evaling a given script line by line
#   Parameters:
#       script - the given script to eval.
# -----------------------------------------------------------------------------
proc verbose_eval {script} {
    set cmd {}
    puts "verbose_evaling.."
    foreach line [split $script \n] {
        puts "line: $line"
        if {$line eq {}} {continue}
        append cmd $line\n
        if {[info complete $cmd]} {
            puts -nonewline $cmd
            puts -nonewline [uplevel 1 $cmd]
            set cmd ""
        }
    }
}
