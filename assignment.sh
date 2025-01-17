#!/usr/bin/env bash

# Yusuf Bedelci (1051250)
# Written and tested on Debian 11.6.0

# Notes to self:
# (( $? != 0 )) && return $? # ends rest of function in one-line.
# echo -e -> the -e option enables non printable characters like \n
# "${@:2}" # slices off first argument


# Global variables
# TODO Define (only) the variables which require global scope
CONFIG_FILE="$HOME/vault.conf"
VAULT_PATH="$HOME/vault"
ENCRYPTED="false"

###########
# INSTALL #
###########
function install() {
    # Do NOT remove next line!    
    echo "function install"
    #############################################

    #
    # Determine new vault path
    if [[ "$#" -eq 1 ]]; then
        VAULT_PATH=$(get_absolute_path "$1")
    fi
    (( $? != 0 )) && return $?

    #
    # Validate new vault path
    local parent_dir=$(dirname "$VAULT_PATH")
    if ! is_valid_directory $parent_dir; then
        handle_error "Installation failed: parent directory doesn't exist or no permissions."
    elif [[ -e $VAULT_PATH ]]; then
        handle_error "Installation failed: vault already exists or chosen directory already in use."
    fi
    (( $? != 0 )) && return $?

    #
    # Create vault and contents
    mkdir "$VAULT_PATH"
    echo "almost nothing" > "$VAULT_PATH/nothing.txt"
    tar -czf "$VAULT_PATH/archive.vault" "$VAULT_PATH/nothing.txt"
    echo "" > "$VAULT_PATH/queue.vault"

    #
    # Create or overwrite the configuration file in $HOME.
    echo -e "ENCRYPTED=false\nVAULT_PATH=$VAULT_PATH/" > $CONFIG_FILE

    #
    # Finish installation.
    echo "Installation successful: new vault created at $VAULT_PATH"
    return 0
}

#################
# CONFIGURATION #
#################
function setup() {
    # Do NOT remove next line!
    echo "function setup"
    #############################################

    #
    # Read configs
    read_configs

    #
    # Checking provided arguments
    if [[ -z "$1" ]]; then
        handle_error "No setup directory was provided."
    fi
    (( $? != 0 )) && return $?

    # 
    # Validate provided directory location
    local new_vault=$(get_absolute_path "$1")
    if [[ -e $new_vault ]]; then
        handle_error "Setup failed: can't move vault to an existing directory."
    fi
    (( $? != 0 )) && return $?

    local parent_dir=$(dirname "$new_vault")
    if ! is_valid_directory $parent_dir; then
        handle_error "Setup failed: parent directory doesn't exist or no permissions."
    fi
    (( $? != 0 )) && return $?

    #
    # Move vault to new location and update config file
    mv "$VAULT_PATH" "$new_vault"
    echo -e "ENCRYPTED=$ENCRYPTED\nVAULT_PATH=$new_vault/" > $CONFIG_FILE
    
    #
    # Finish setup.
    echo "Setup successful: vault moved from $VAULT_PATH to $new_vault"
    return 0
}

function read_configs() {
    ENCRYPTED=$(grep "^ENCRYPTED=" "$CONFIG_FILE" | cut -d '=' -f2)
    VAULT_PATH=$(grep "^VAULT_PATH=" "$CONFIG_FILE" | cut -d '=' -f2)
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

    #
    # Checking provided arguments
    (( $# > 1 )) && handle_error "Too many arguments provided."
    (( $# == 1)) && [[ $1 != "-p" ]] && handle_error "Invalid option: $1"
    (( $? != 0 )) && return $?

    [[ $# == 1 && $1 == "p" ]] && ENCRYPTED="true"

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

    [[ $# -eq 2 && $1 == "-p" ]] && ENCRYPTED="true" # if -p povided reset encryption setting
    

    #
    # Validating entry
    local entry="${@: -1}" # takes the last argument (which is always entry)

}


#############
# UNINSTALL #
#############
function uninstall() {
    # Do NOT remove next line!
    echo "function uninstall"  

    #
    # Read configs if it exists to load custom vault path
    if is_valid_file $CONFIG_FILE && is_valid_config $CONFIG_FILE; then
        read_configs
    fi

    #
    # Delete vault and config file
    rm -rf "$VAULT_PATH"
    rm -f "$CONFIG_FILE"
}



function main() {
    # Do NOT remove next line!
    echo "function main"
    ################################

    #
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

    #
    # Run checks
    # check_configuration $CONFIG_FILE

    #
    # Menu
    # If there are no arguments/options then only run install method
    if [[ $# -eq 0 ]]; then
        install
    else
        case "$1" in
            --uninstall)
                uninstall
                ;;
            --setup)
                setup "$2"
                ;;
            enqueue)
                enqueue "${@:2}"
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
        handle_error "Configuration file does not exist or no permissions."
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