#!/usr/bin/env bash

# Yusuf Bedelci (1051250)
# Written and tested on Debian 11.6.0

# Notes to self:
# echo -e -> the -e option enables non printable characters like \n
# "${@:2}" # slices off first argument


# Global variables
TMP_VAULT="/tmp/vault_temp"
CONFIG_FILE="$HOME/vault.conf"
VAULT_PATH="" # default = "$HOME/vault"
ENCRYPTED="" # default = "false"

#######################
# INSTALL / UNINSTALL #
#######################
function install() {
    # Do NOT remove next line!    
    echo "function install"
    #############################################

    #
    # Skip installation if already installed
    is_valid_file "$CONFIG_FILE" && is_valid_config "$CONFIG_FILE" && read_configuration
    is_valid_file "$CONFIG_FILE" && is_valid_directory "$VAULT_PATH" && return 0

    #############################################

    #
    # Set default configuration values
    VAULT_PATH="$HOME/vault"
    ENCRYPTED="false"

    #
    # Set custom vault path if specified
    if [[ "$#" -eq 1 ]]; then
        VAULT_PATH=$(get_absolute_path "$1")
    fi

    #
    # Validate new vault path
    local parent_dir=$(dirname "$VAULT_PATH")
    if ! is_valid_directory $parent_dir; then
        handle_error "Installation failed: parent directory doesn't exist or no permissions to read/write."
    elif [[ -e $VAULT_PATH ]]; then
        handle_error "Installation failed: vault already exists or chosen directory already in use."
    fi

    #
    # Create vault and contents
    mkdir -p "$VAULT_PATH"
    echo "almost nothing" > "$VAULT_PATH/nothing.txt"

    tar -cf "$VAULT_PATH/archive.vault" -C "$VAULT_PATH" "nothing.txt"
    rm "$VAULT_PATH/nothing.txt"
    touch "$VAULT_PATH/queue.vault"

    #
    # Create or overwrite the configuration file in $HOME.
    echo -e "ENCRYPTED=false\nVAULT_PATH=$VAULT_PATH/" > $CONFIG_FILE

    #
    # Finish installation.
    success_message "Installation successful: new vault created at $VAULT_PATH"
    return 0
}

function uninstall() {
    # Do NOT remove next line!
    echo "function uninstall"  
    ###########################

    #
    # Read configs if it exists, to load custom vault path
    is_valid_file "$CONFIG_FILE" && is_valid_config "$CONFIG_FILE" && read_configuration

    #
    # Delete vault (and contents) and config file
    rm -rf "$VAULT_PATH"
    rm -f "$CONFIG_FILE"
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

    #
    # Run checks and read configs
    check_all
    read_configuration

    # 
    # Validate provided directory location
    local new_vault=$(get_absolute_path "$1")
    local parent_dir=$(dirname "$new_vault")
    if ! is_valid_directory $parent_dir; then
        handle_error "Setup failed: parent directory doesn't exist or no permissions to read/write."
    elif [[ -e $new_vault ]]; then
        handle_error "Setup failed: can't move vault to an existing directory."
    fi

    #
    # Move vault to new location and update config file
    mv "$VAULT_PATH" "$new_vault"
    echo -e "ENCRYPTED=$ENCRYPTED\nVAULT_PATH=$new_vault/" > $CONFIG_FILE
    
    #
    # Finish setup.
    success_message "Setup successful: vault moved from $VAULT_PATH to $new_vault"
    return 0
}

function read_configuration() {
    ENCRYPTED=$(grep "^ENCRYPTED=" "$CONFIG_FILE" | cut -d '=' -f2)
    VAULT_PATH=$(grep "^VAULT_PATH=" "$CONFIG_FILE" | cut -d '=' -f2)
}


##################
# ERROR HANDLING #
##################
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    #
    # Echoing error message to standard output
    error_message "$1"

    #
    # Running rollback
    rollback

    #
    # Echoing error code to standard error then interrupting process
    echo 1 >&2
    kill -INT $$
    # exit 1 # -> Avoiding `exit` on purpose because it exits the shell in its entirety.
}

function rollback() { delete_temps; }

######################
# TEMP FILE HANDLING #
######################
function create_temps() {
    mkdir -p "$TMP_VAULT"
    cp -r "$VAULT_PATH" "$TMP_VAULT/vault"
    cp "$CONFIG_FILE" "$TMP_VAULT/vault.conf"
}

function save_temps() {
    mv "$TMP_VAULT/vault" "$VAULT_PATH"
    mv "$TMP_VAULT/vault.conf" "$CONFIG_FILE"
    delete_temps
}

function delete_temps() { rm -rf "$TMP_VAULT"; }




############
# QUEUEING #
############
function dequeue() {
    # Do NOT remove next line!
    echo "function pop dequeue"
    #############################################

    #
    # Checking provided arguments
    if [[ $# -gt 1 ]]; then
        handle_error "Too many arguments provided."
    elif [[ $# -eq 1 && "$1" != "-p" ]]; then
        handle_error "Invalid option: $1"
    fi

    #
    # Run checks, read configs and create temporary files
    check_all
    read_configuration
    create_temps

    #
    # Check whether encrypted archive is being accessed without -p
    if [[ $# -eq 0 ]] && is_encrypted "$TMP_VAULT/archive.vault"; then
        handle_error "An encrypted archive cannot be accessed with this command!"
    fi

    #
    # Check if there is anything left to dequeue
    if [[ ! -s "$TMP_VAULT/queue.vault" ]]; then
        handle_error "No entry left to dequeue"
    fi

    #
    # Decrypt archive (if encrypted)
    is_encrypted "$TMP_VAULT/archive.vault" && decrypt_archive

    #
    # Dequeue item
    local entry=$(head -n 1 "$TMP_VAULT/queue.vault") || handle_error "Dequeue failed: could not read an entry from queue."
    sed -i '1d' "$TMP_VAULT/queue.vault" || handle_error "Dequeue failed: could not update queue."
    tar -xf "$TMP_VAULT/archive.vault" "$entry" || handle_error "Dequeue failed: could not extract entry from archive."
    tar --delete -f "$TMP_VAULT/archive.vault" "$entry" || handle_error "Dequeue failed: could not delete entry from archive."

    #
    # Add back nothing.txt in case archive is empty.
    if [[ -z $(tar -tf "$TMP_VAULT/archive.vault") ]]; then
        echo "almost nothing" > "$TMP_VAULT/nothing.txt"
        tar -cf "$TMP_VAULT/archive.vault" -C "$TMP_VAULT" "nothing.txt" || handle_error "Dequeue failed: could not add nothing.txt file."
        rm "$TMP_VAULT/nothing.txt"
    fi

    #
    # Encrypt archive (if encryption enabled)
    [[ "$ENCRYPTED" == "true" ]] && encrypt_archive

    #
    # Finish dequeue
    save_temps
    success_message "Successfully dequeued: $entry"
    return 0
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

    #
    # Run checks, read configs and create temporary files
    check_all
    read_configuration
    create_temps

    #
    # If -p is provided set newly_encrypted var for reseting encryption settings
    local newly_encrypted="false"
    [[ $# -eq 2 && $1 == "-p" ]] && newly_encrypted="true"
    
    #
    # Validating entry
    local entry=$(get_absolute_path "${@: -1}") # takes the last argument (which is always entry)
    if ! is_valid_entry "$entry"; then
        handle_error "$entry does not exist or no permissions to read/write."
    fi
    
    #
    # Check if entry with the same name already exists
    local entry_basename=$(basename "$entry")
    if grep -q "^$entry_basename$" "$TMP_VAULT/queue.vault" || tar -tf "$TMP_VAULT/archive.vault" | grep -q "^$entry_basename$"; then
        handle_error "Enqueue failed: An entry with the same name is already archived."
    fi

    #
    # Decrypt archive (if encryptyed)
    is_encrypted "$TMP_VAULT/archive.vault" && decrypt_archive

    #
    # Enqueueing entry
    echo $(basename "$entry") >> "$TMP_VAULT/queue.vault"
    tar -rf "$TMP_VAULT/archive.vault" -C "$(dirname "$entry")" "$entry_basename" || handle_error "Enqueue failed: could not add item to archive."

    #
    # Remove nothing.txt if it still exists and remove any empty lines from the queue.vault
    if tar -tf "$TMP_VAULT/archive.vault" | grep -q "nothing.txt"; then
        tar --delete -f "$TMP_VAULT/archive.vault" "nothing.txt" || handle_error "Enqueue failed: could not remove nothing.txt from archive."
    fi
    sed -i '/^$/d' "$TMP_VAULT/queue.vault"

    #
    # Encrypt archive (if encryption enabled)
    [[ "$ENCRYPTED" == "true" || "$newly_encrypted" == "true" ]] && encrypt_archive

    #
    # Finish enqueue
    save_temps
    success_message "Successfully enqueued: $entry"
    return 0
}

##############
# ENCRYPTION #
##############
function encrypt_archive() {
    gpg --symmetric --cipher-algo AES256 --output "$TMP_VAULT/archive.temp" "$TMP_VAULT/archive.vault" || handle_error "Failed to encrypt the archive."
    mv "$TMP_VAULT/archive.temp" "$TMP_VAULT/archive.vault"
    echo -e "ENCRYPTED=true\nVAULT_PATH=$VAULT_PATH/" > $TMP_VAULT/vault.conf
}

function decrypt_archive() {
    gpg --decrypt --output "$TMP_VAULT/archive.temp" "$TMP_VAULT/archive.vault" || handle_error "Failed to decrypt the archive."
    mv "$TMP_VAULT/archive.temp" "$TMP_VAULT/archive.vault"
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

error_message() { echo -e "\e[1;31mERROR|\e[0m " "$1"; }
success_message() { echo -e "\e[1;32mSUCCESS|\e[0m " "$1"; }


###################
# Check functions #
###################
function check_all() {
    check_configuration
    check_vault
}

# Checks whether configuration file exists and has proper values.
function check_configuration() {
    if ! is_valid_file "$CONFIG_FILE"; then
        handle_error "Configuration file does not exist or no permissions to read/write."
    elif ! is_valid_config "$CONFIG_FILE"; then
        handle_error "Configuration file has been corrupted."
    fi
}

# Checks whether vault exists (with its contents)
function check_vault() {
    if ! is_valid_directory "$VAULT_PATH"; then
        handle_error "Vault (at $VAULT_PATH) does not exist or no permissions to read/write."
    elif ! is_valid_file "$VAULT_PATH/queue.vault"; then
        handle_error "queue.vault does not exist or no permissions to read/write."
    elif ! is_valid_file "$VAULT_PATH/archive.vault"; then
        handle_error "archive.vault does not exist or no permissions to read/write."
    fi
}



########################
# Validation functions #
########################
is_valid_entry() { [[ -e "$1" && -r "$1" && -w "$1" && ( -f "$1" || -d "$1" ) ]]; } # Checks whether entry exists and read/write permissions, AND whether entry is a file or directory.
is_valid_file() { is_valid_entry "$1" && [[ -f "$1" ]]; } # Checks whether entry is a file
is_valid_directory() { is_valid_entry "$1" && [[ -d "$1" ]]; } # Checks whether entry is a directory
is_encrypted() { "$(file --mime-type -b "$1")" == "application/pgp-encrypted" ;}

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

# Do NOT remove next line!
main "$@"