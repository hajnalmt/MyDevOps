#!/usr/bin/expect
#
# A TCL, Expect script for environment setup.
##############################################################################

source "utils/source_utils.tcl"
set server_setup_script_path [info script]

# -----------------------------------------------------------------------------
# ::eval_server_setup { id args }
#
#   This procedure creates an instance of server_setup namespace
#   (::server_setup_$id)
#
#   What it does:
#   - Creates an instance of server_setup
#   - Returns namespace name
# -----------------------------------------------------------------------------
proc eval_server_setup { id args  } {
    if { [uplevel 1 namespace current] eq "::"  } {
        set ns_name "::server_setup_$id"
    } else {
        set ns_name "[uplevel 1 namespace current]::server_setup_$id"
    }
########################
# Namespace definition #
########################
namespace eval ${ns_name} {
    #Where am I, who ami I, this is for directory independecy
    variable user [exec whoami]
    variable script_path ${server_setup_script_path}
    variable script_name [file tail $script_path]
    variable script_location [file dirname $script_path]

    #The working directory will be the home one.
    cd ${::env(HOME)}

    #Script parameters, environment variables
    variable USER $user
    variable DOMAIN
    variable DOCKER_VER "18.06"

    #Vim, bash related
    variable VIMRC ".vimrc"
    variable BASHRC ".bashrc"
    variable HOME_DIRS "git@github.com:hajnalmt/home-dirs.git"
    variable VIM_RUNTIME_DIR ".vim_runtime/"

    #Script flags
    variable vim_flag FALSE
    variable bash_flag FALSE

    #Linux Server Distribution.
    variable server_name
    variable server_prompt
    variable server_release
    variable server_distributor
}

# -----------------------------------------------------------------------------
# usage
#   Prints the usage information of the script, and then exists
# -----------------------------------------------------------------------------
proc ${ns_name}::usage { } {
    variable script_path
    send_user --\
"This script is used to setup an Ubuntu server. It downloads and upgrades
some packages, installs docker etc... And also will setup a new root account
on the remote server, added to the docker group.

Usage: $script_path \[OPTIONS] <ip|host> \[ARG...]

Options:
    -h, --help          Show this help (-h is --help only if used alone)
    -e, --env list      Set environment variables for the script.
                        Possible variables:
                            USER - user name to configure on the remote
                                (default is the script user)
                            DOCKER_VER - docker version to install
                                (default is 18.06)
                            HOME_DIRS - If you have a home_dirs repository
                                here you can provide an access to it.
                                (default is
                                     git@github.com:hajnalmt/home-dirs.git)
                            HOME_DIRS_BRANCH - The branch specified.
                                (defautl: \$server_dist)
    -v                  Do a vim setup from the local one.
    -b                  Do a bash setup from the local one.
    -s, --user-setup    Just setup the user.
                        It will try to clone out the HOME_DIRS repo you
                        have given as an environment variable.
        --setup-home-dirs
                        If you have a home_dirs repository, like:
                        git@github.com:hajnalmt/home-dirs.git
                        Then clone it out.
Parameters:
    ip|host     The ip or the host name of the server to configure.
                For a local run, provide . as a server ip.
Example:
    $script_path -e USER=hajnalmt --setup_home_dirs 51.15.239.79
    $script_path my_little_server\n"
    exit
}

# -----------------------------------------------------------------------------
# Init
#   Flags initialized.
# -----------------------------------------------------------------------------
proc ${ns_name}::Init { args } {
    variable server_name
    variable script_location

    #Flags
    variable vim_flag
    variable bash_flag

    #Check if right number of arguments provided
    if { [lindex $args 0] eq "" } {
        send_user -- "ERROR No arguments provided!\n"
        usage
    }

    #See flags
    for { set i 0} { [regexp {^(-).*} [lindex $args 0]] } { incr i } {
        if { [regexp {^(--).*} [lindex $args 0]] } {
            switch -exact [lindex $args 0] {
                "--help" {
                    usage
                }
                default {
                    send_user "ERROR: No such option as [lindex $args 0]!\n"
                    usage
                }
            }
        } else {
            if { [regexp {^(-).*h.*} [lindex $args 0]] } {
                usage
            }
            if { [regexp {^(-).*v.*} [lindex $args 0]] } {
                set vim_flag TRUE
            }
            if { [regexp {^(-).*b.*} [lindex $args 0]] } {
                set bash_flag TRUE
            }
            #Delete first argument, easier to deal with the remaining
            set args [lrange $args 1 end]
        }
    }

    if { [lindex $args 0] eq "" } {
        send_user -- "ERROR: No host or ip provided!\n"
        usage
    }
    set server_name [lindex $args 0]
    return 0
}

# -----------------------------------------------------------------------------
# Connection_check
#   Check SSH connection to server.
# -----------------------------------------------------------------------------
proc ${ns_name}::Connection_check { } {
    variable server_name
    variable server_prompt

    #A flag for public key copy
    set ssh_copy_id_flag FALSE

    set session_id [Return [spawn_ssh $server_name]]
    set timeout 5
    expect {
        -i $session_id -timeout 15 -- "Welcome" {
            send_user -i $session_id -- "\nDEBUG: Connected!\n"
        } "Permission denied" {
            exp_continue
        } -re "password|Password" {
            Return [send_password "" ${session_id}]
            set ssh_copy_id_flag TRUE
            exp_continue
        } "continue connecting (yes/no)" {
            send -i $session_id -- "yes\r"
            exp_continue
        } "remove with:" {
            set timeout 20
            expect -i $session_id "ECDSA" {
                set removecmd [string trim [string trim [string trim \
                    [string trimright $expect_out(buffer) "ECSDA"]] "ERROR:" ]]
                send -i $session_id -- "$removecmd\r"
            } "RSA" {
                set removecmd [string trim [string trim [string trim\
                    [string trimright $expect_out(buffer) "RSA"]] "ERROR:" ]]
                send -i $session_id -- "$removecmd\r"
            } timeout {
                send_user -i $session_id -- "\nERROR: Not found RSA/ECDSA key,\
                    something nasty is happening!\n"
                return 1
            }
            set timeout 5
            exp_continue
        } "No route to host" {
            send_user -i $session_id -- "\nERROR: No route to $sesver_name!\n"
            return 1
        } timeout {
            send_user -i $session_id --\
                "\nERROR: Timeout while connecting via ssh!\n"
            return 1
        }
    }

    #set server related variables
    set timeout 5
    send -i $session_id -- "lsb_release -a\r"
    expect {
        -i $session_id -- "lsb_release -a\r" {
            exp_continue
        } "Distributor ID:" {
            exp_continue
        } "Release:" {
            set server_distributor\
                [lindex [split $expect_out(buffer) "\t\n\r"] 1]
            exp_continue
        } "Codename" {
            set server_release\
                [lindex [split $expect_out(buffer) "\t\n\r"] 1]
            expect {
                -i $session_id -- "\r\n" {
                    send -i $session_id "\r"
                }
            }
            expect -i $session_id -- "\r"
            set server_prompt\
                [lindex [split $expect_out(buffer) "\r"] 0]
            send -i $session_id -- "\r"
        } timeout {
            send_user -i $session_id -- "WARNING: Timeout in lsb_release!"
        }
    }

    # If needed try to copy the public id
    if { ${ssh_copy_id_flag} } {
        send_user -- "\nDEBUG: Try to copy the ssh public-id to the remote location!\n"
        if { [catch { spawn ssh-copy-id \
            ${server_name} } reason] } {
            send_user -- "\nERROR: Couldn't spawn ssh-copy-id!\n"
            return 1
        }

        set session_id $spawn_id
        expect {
            -i $session_id -re "password|Password" {
                Return [send_password  "" $session_id]
            } timeout {
                send_user -- "\n[lindex [info level 0] 0]\
                    ERROR: ssh-copy-id timed out!\n"
                return 1
            }
        }
    }
    return 0
}

# -----------------------------------------------------------------------------
# setup
#   Do the work itself.
# -----------------------------------------------------------------------------
proc ${ns_name}::setup { } {
    variable USER
    variable VIMRC
    variable BASHRC
    variable VIM_RUNTIME_DIR

    variable vim_flag
    variable bash_flag
    variable server_name

    set timeout -1

    #Do vim setup if needed
    if { $vim_flag eq TRUE } {
        #First the .vimrc
        if { [catch\
            { spawn rsync -avPR $VIMRC $server_name:$VIMRC } msg] } {
            send_user -- "\nERROR: Not able to spawn rsync\
                for vimrc due to $msg!"
            return 1
        }
        #Wait for rsync to finish
        set session_id $spawn_id
        Return [wait_rsync $session_id]

        #vim_runtime is the second
        if { [catch { spawn rsync -avPR $VIM_RUNTIME_DIR $server_name: }\
            msg] } {
            send_user -- "\nERROR: Not able to spawn rsync\
                for vim_runtime due to $msg!\n"
        }
        #Wait for rsync to finish
        set session_id $spawn_id
        Return [wait_rsync $session_id]
    }

    #Do bash setup if needed
    if { $bash_flag eq TRUE } {
        if { [catch { spawn rsync -avPR $BASHRC\
            $server_name:$BASHRC } msg] } {
            send_user -- "\nERROR: Not able to spawn rsync\
                for bashrc due to $msg!\n"
        }
        #Wait for rsync to finish
        set session_id $spawn_id
        Return [wait_rsync $session_id]
    }
    return 0
}


###############################
# End of namespace definition #
###############################
    ${ns_name}::Init {*}$args
    Return [${ns_name}::Connection_check]
    return ${ns_name}
}

# Check if, the script is sourced or executed
if { [info exists ::argv0] == 0 ||\
    [file tail $::argv0] ne [file tail [info script]] } {
    return 0
}

# If not source then create a connection
set Server_setup [eval_server_setup 1 {*}$argv]
${Server_setup}::setup
namespace delete ${Server_setup}
