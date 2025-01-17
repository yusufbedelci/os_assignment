#!/usr/bin/env bash

# Yusuf Bedelci (1051250)
# Written and tested on Debian 11.6.0

# Notes to self:
# (( $? != 0 )) && return $? # ends rest of function in one-line.


# Global variables
# TODO Define (only) the variables which require global scope
CONFIG_FILE="$HOME/vault.conf"
ENCRYPTED=0

###########
# INSTALL #
###########
function install() {
    # Do NOT remove next line!    
    echo "function install"
    #############################################

    # Load bash functions
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

#################
# CONFIGURATION #
#################
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
    # Validate provided directory
    local dir=$(get_absolute_path "$1")
    if ! is_valid_directory $dir; then
        handle_error "Provided directory is not valid."
    fi
    (( $? != 0 )) && return $?
    
}


##################
# ERROR HANDLING #
##################
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # TODO print a specific error message
    echo "ERROR: $1"

    # TODO exit this function with a proper integer value.
    return 1

}


############
# QUEUEING #
############
function dequeue() {
    # Do NOT remove next line!
    echo "function pop dequeue"
    #############################################
    echo $ENCRYPTED

    #
    # Checking provided arguments
    (( $# > 1 )) && handle_error "Too many arguments provided."
    (( $# == 1)) && [[ $1 != "-p" ]] && handle_error "Invalid option: $1"
    (( $? != 0 )) && return $?

    [[ $# == 1 && $1 == "p" ]] && ENCRYPTED=1 

    #
    # Dequeue item

}

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
        handle_error "Invalid option: $1"
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

    check_configuration $CONFIG_FILE


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
                enqueue "${@:2}" # removes "enqueue" argument
                ;;
            dequeue)
                dequeue "${@:2}"
                ;;
            *)
                echo "Unknown command: $1"
                ;;
        esac
    fi
}


####################
# Helper functions #
####################
function get_absolute_path() {
    local path="$1"
    # If path doesn't start with / treat as relative path
    [[ "$path" != /* ]] && path="$(pwd)/$path"

    # remove trailing slash if present
    echo "${path%/}"
}

###################
# Check functions #
###################

# Check all -> Ensures commands can run without issues.
function check_all() {
    check_configuration
}

# Checks whether configuration file exists and has proper values.
function check_configuration() {
    if ! is_valid_file $CONFIG_FILE; then
        handle_error "Configuration file does not exist, or lacks proper permissions."
    elif ! is_valid_config $CONFIG_FILE; then
        handle_error "Configuration file has been corrupted."
    fi
}

# Checks whether vault exists (directory and the queue)
# function check_vault() {

# }

# Checks whether any program dependencies are missing.
# function check_program_dependencies() {

# }



########################
# Validation functions #
########################
is_valid_entry() { [[ -e "$1" && -r "$1" && -w "$1" && ( -f "$1" || -d "$1" ) ]]; } # Checks whether entry exists and read/write permissions, AND whether entry is a file or directory.
is_valid_file() { is_valid_entry "$1" && [[ -f "$1" ]]; } # Checks whether entry is a file
is_valid_directory() { is_valid_entry "$1" && [[ -d "$1" ]]; } # Checks whether entry is a directory

function is_valid_config()
{
    local encrypted=$(grep "^ENCRYPTED=" "$1" | cut -d '=' -f2)
    local vault_path=$(grep "^VAULT_PATH=" "$1" | cut -d '=' -f2)
    
    # Validate ENCRYPTED value
    if [[ "$encrypted" != "true" && "$encrypted" != "false" ]]; then
        return 1
    fi

    # Validate VAULT_PATH
    if ! is_valid_directory "$vault_path"; then
        return 1
    fi

    return 0
}


###
###
###
###
###

# Do NOT remove next line!
main "$@"