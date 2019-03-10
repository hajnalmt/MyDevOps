#!/usr/bin/expect
#
# A TCL, Expect script for environment setup.
##############################################################################

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

    #Script parameters, environment variables
    variable server_name
    variable USER $user
    variable DOMAIN
    variable DOCKER_VER "18.06"
    
    #Vim, bash related
    variable VIMRC "~/.vimrc"
    variable BASHRC "~/.bashrc"
    variable HOME_DIRS "git@github.com:hajnalmt/home-dirs.git"
    variable VIM_RUNTIME_DIR "~/.vim_runtime/"

    #Script flags
    variable vim_flag FALSE
    variable bash_flag FALSE

    
    #Linux Server Distribution.
    variable server_distro
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
                    set ::loglevel "LOG"
                    Log "ERROR" "No such option as [lindex $args 0]!"
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

    #TODO catch if hostname/ip name is valid.
    set server_name [lindex $args 0]
    puts $server_name
    return 0
}

proc ${ns_name}::setup { } {
    variable USER
    variable VIMRC
    variable BASHRC
    variable VIM_RUNTIME_DIR

    variable vim_flag
    variable bash_flag
    variable server_name
    puts "kaka"
    if { $vim_flag eq TRUE } {
        if { [catch\
            { spawn rsync -avPR $VIMRC $USER@$server_name:$VIMRC } msg] } {
            puts "ERROR: Not able to spawn rsync for vimrc due to $msg!"
        }
        #Wait for rsync to finish
        set session_id $spawn_id
        wait_rsync_to_finish $session_id
        
        if { [catch { spawn rsync -avPR\
            $VIM_RUNTIME_DIR $USER@$server_name:$VIM_RUNTIME_DIR } msg] } {
            puts "ERROR: Not able to spawn rsync for vim_runtime due to $msg!"
        }
        set session_id $spawn_id
        wait_rsync_to_finish $session_id
    }
    if { $bash_flag eq TRUE } {
        if { [catch { spawn rsync -avPR $BASHRC\
            $USER@$server_name:$BASHRC } msg] } {
            puts "ERROR: Not able to spawn rsync for bashrc due to $msg!"
        }   
    }
    return 0
}

proc ${ns_name}::wait_rsync_to_finish { {session_id $spawn_id} } {
    
}

###############################
# End of namespace definition #
###############################
    ${ns_name}::Init {*}$args
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
