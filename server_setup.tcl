#!/usr/bin/expect
#
# A TCL, Expect script for environment setup.
##############################################################################

namespace eval ::server_setup {
    #Where am I, who ami I, this is for directory independecy
    variable user [exec whoami]
    variable script_path [info script]
    variable script_name [file tail $script_path]
    variable script_location [file dirname $script_path]

    #Script parameters, environment variables
    variable server_name
    variable USER
    variable DOMAIN
    variable DOCKER_VER "18.06"

    #Linux Server Distribution.
    variable server_distro
}
# -----------------------------------------------------------------------------
# ::server_setup::usage
#   Prints the usage information of the script, and then exists
# -----------------------------------------------------------------------------
proc ::server_setup::usage {
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
        --setup-home-dirs
                        If you have a home_dirs repository, like:
                        git@github.com:hajnalmt/home-dirs.git
                        Then clone it out.
Parameters:
    ip|host -- The ip or the host name of the server to configure.
Example:~
    $script_path -e USER=hajnalmt --setup_home_dirs 51.15.239.79
    $script_path my_little_server\n"
    exit
}

proc ::server_setup::init {
    variable server_ip
    variable script_location
}

proc ::server_setup::spawn_ssh {

}

::server_setup::usage