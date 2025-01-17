#!/usr/bin/env bash

# Yusuf Bedelci (1051250)
# Written and tested on Debian 11.6.0

# Notes to self:
# (( $? != 0 )) && return $? # ends rest of function in one-line.


# Global variables
# TODO Define (only) the variables which require global scope
ENCRYPTED=0


# INSTALL

# TODO complete the implementation of this function
function install() {
    # Do NOT remove next line!    
    echo "function install"

    # TODO if something goes wrong then call function handle_error
    aqueue() { enqueue "$@"; }
    apqueue() { enqueue -p "$@"; }
    adequeue() { dequeue "$@"; }
    apdequeue() { dequeue -p "$@"; }
    assignment() {
        case "$1" in
            --uninstall)
                uninstall
                ;;
            --setup)
                setup "$2"
                ;;
            *)
                echo "Invalid option: $1"
                ;;
        esac
    }
}


# CONFIGURATION

# TODO complete the implementation of this function
function setup() {
    # Do NOT remove next line!
    echo "function setup"
    #############################################

    #
    # Checking provided arguments
    if [[ -z "$1" ]]; then
        handle_error "No setup directory was provided."
    fi
    (( $? != 0 )) && return $?

    # 
    # Validate provided directory:
    local dir="$1"
}



# ERROR HANDLING

# TODO complete the implementation of this function
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # TODO print a specific error message
    echo "ERROR: $1"

    # TODO exit this function with a proper integer value.
    return 1

}

# TODO complete the implementation of this function
function dequeue() {
    # Do NOT remove next line!
    echo "function pop dequeue"
    #############################################

    #
    # Checking provided arguments
    check_queue_arguments $@
    (( $? != 0 )) && return $?

    local entry="${@: -1}" # takes the last argument (which is always entry)

    #
    # Validating entry
    

}

# TODO complete the implementation of this function
function enqueue {
    # Do NOT remove next line!
    echo "function rollback_spigotserver enqueue"
    #############################################

    #
    # Checking provided arguments
    if [[ $# -eq 0 ]]; then
        handle_error "No arguments provided."
    elif [[ $# -gt 2 ]]; then
        handle_error "Too many arguments provided."
    elif [[ $# -eq 2 && $1 != "-p" ]]; then
        handle_error "Invalid argument: $1"
    elif [[ "${@: -1}" == "-p" ]]; then
        handle_error "Entry cannot be -p"
    fi
    (( $? != 0 )) && return $?

    [[ $# -eq 2 && $1 == "-p" ]] && ENCRYPTED=1 # if -p povided reset encryption setting
    

    #
    # Validating entry
    local entry="${@: -1}" # takes the last argument (which is always entry)

}


# UNINSTALL

# TODO complete the implementation of this function
function uninstall() {
    # Do NOT remove next line!
    echo "function uninstall"  

    # TODO if something goes wrong then call function handle_error
}



function main() {
    # I designed the main function to handle the commands users run.
    # If the user runs a proper command the respective functionality will be run.
    # If there is an mistake in the written command or there are missing arguments, the user is informed about it.
    # I do not consider these to be "errors" but rather improper syntax.
    # It is only evaluating whether the proper syntax is used, not validate the actual input.
    # Hence these mistakes are not handled through handle_error centrally yet.

    # Do NOT remove next line!
    echo "function main"


    # If there are no arguments/options then only run install method
    if [[ $# -eq 0 ]]; then
        install
    else
        # Parsing the commands and their options
        case "$1" in
            --uninstall)
                uninstall
                ;;
            --setup)
                setup "$2"
                ;;
            enqueue)
                enqueue "$2" "$3"
                ;;
            dequeue)
                dequeue "$2" "$3"
                ;;
            *)
                echo "Unknown command: $1"
                ;;
        esac
    fi
}

# Helper functions
#



# Do NOT remove next line!
main "$@"