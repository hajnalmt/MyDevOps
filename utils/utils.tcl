#!/usr/bin/expect
#
# A TCL, Expect script for the utilities
##############################################################################

# -----------------------------------------------------------------------------
# spawn_ssh
#   A funcion that just spawns an ssh connection to a host.
# -----------------------------------------------------------------------------
proc spawn_ssh { host } {
    set ssh_command "ssh -o StrictHostKeyChecking=no\
        -o UserKnownHostsFile=/dev/null $host"
    if { [catch "spawn $ssh_command" reason] } {
        Log "ERROR" "Failed to spawn ssh connection to $host, due to $reason"
        return 1
    }
    return [list 0 $spawn_id]
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
    set timeout -1
    expect {
        -i $session_id -- "password"  {
            if { [lindex [send_password "" $session_id] 0] } {
                send_user -- "\nWARNING: User entered Cntl+C,\
                    rsync not finished!"
                return 1
            }
            exp_continue
        } "total size" {
            send_user -- "DEBUG: rsync finished successfully!\n"
        } timeout {
            send_user -- "ERROR: rsync timed out!\n"
            return 1
        }
    }
    return 0
}

