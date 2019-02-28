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
    variable USER
    variable DOMAIN
    variable DOCKER_VER "18.06"
    variable HOME_DIRS "git@github.com:hajnalmt/home-dirs.git"

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
    -v                  Just do a vim setup from the local one.
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
    usage
}

proc ${ns_name}::spawn_ssh { } {

}
###############################
# End of namespace definition #
###############################
    ${ns_name}::Init {*}$args
    return ${ns_name}
}

# Check if, the script is sourced or executed~
if { [info exists ::argv0] == 0 ||\
    [file tail $::argv0] ne [file tail [info script]] } {
    return 0
}

# If not source then create a connection~
set Server_setup [eval_server_setup 1 {*}$argv]
namespace delete ${Server_setup}
