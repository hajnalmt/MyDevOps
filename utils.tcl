#!/usr/bin/expect
#
# A TCL, Expect script for the utilities
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

# -----------------------------------------------------------------------------
# send_password
#   Sends a password for the given session.
# -----------------------------------------------------------------------------
proc send_password { {prompt ""} {session_id $spawn_id} } {
    set password [Return [get_password $prompt]]
    send -i $session_id -- "$password\n"
    return [list 0 $password]
}

# -----------------------------------------------------------------------------
# get_password
#   Gets a password from a given  the given session.
# -----------------------------------------------------------------------------
proc get_password { {prompt ""} } {
    #By default stty returns the previous mode of the terminal. Now setting
    #it to raw no echo mode, because we need to process the characters one
    #by one. Also we shall wait for input as long as it take (infinitely), so
    #setting the timeout to -1 is also needed
    set old_mode [stty -echo raw]
    set password ""
    set timeout -1

    #Send prompt to user first
    send_user -- $prompt
    #Read input
    expect_user {
        "\003" {
            #Abort if Cntl+C entered
            return 1
        } -re "(\010|\177)"  {
            #Handling backspace/delete characters
            set last_char [string index $password end]
            set password [string range $password 0\
                [expr [string length $password] - 2]]
            send_user -- "\010 \010"
        } "\r" {
        } "\n" {
        } -re "." {
            #Character entered, append variable and a *
            append password $expect_out(buffer)
            send_user -- "*"
            exp_continue
        }
    }

    #Set back the old terminal mode and return
    eval stty $old_mode
    return [list 0 [string trimright $password "\r"]]
}

# -----------------------------------------------------------------------------
# wait_rsync
#   A function that just waits rsync to finish.
# -----------------------------------------------------------------------------
proc wait_rsync { {session_id $spawn_id} } {
    #Send password if needed, and wait for finish
    expect {
        -i $session_id -- "password"  {
            if { [lindex [send_password "" $session_id] 0] } {
                send_user -- "\nWARNING: User entered Cntl+C,\
                    rsync not finished!"
                return 1
            }
            exp_continue
        } "total size" {
            send_user -- "DEBUG: rsync finished successfully!"
        } timeout {
            send_user -- "ERROR: rsync timeo out!"
            return 1
        }
    }
    return 0
}
