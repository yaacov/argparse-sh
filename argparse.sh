#!/bin/bash

# argparse.sh contains bash functions that streamlines the management of
# command-line arguments in Bash scripts
#
# Compatible with Bash 3.2+ (macOS system Bash) and Bash 4+/5.x (Linux).

# Example:
#   define_arg "username" "" "Username for login" "string" "true"
#   parse_args "$@"
#
#   echo "Welcome, $username!"
#
#   # Usage:
#   # ./example.sh --username Alice

# Author: Yaacov Zamir <kobi.zamir@gmail.com>
# License: MIT License.
# https://github.com/yaacov/argparse-sh/

# Indexed property list (Bash 3 compatible; no associative arrays)
# Layout per argument: name, default, help, type, required, short
ARGS_PROPERTIES=()

_NULL_VALUE_="null"
_DEFAULT_=1
_HELP_=2
_TYPE_=3
_REQUIRED_=4
_SHORT_=5
_NUM_PROPERTIES_=6

# Variable for the script description
SCRIPT_DESCRIPTION=""

# Function to display an error message and exit
# Usage: display_error "Error message"
display_error() {
    echo -e "Error: $1\n"
    show_help
    exit 1
}

# Function to set the script description
# Usage: set_description "Description text"
set_description() {
    SCRIPT_DESCRIPTION="$1"
}

# Resolve a short option letter to the long argument name.
# Prints the long name and returns 0 on success.
_resolve_short_name() {
    local letter=$1
    local i
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=_NUM_PROPERTIES_)); do
        if [[ "${ARGS_PROPERTIES[i+_SHORT_]}" == "$letter" ]]; then
            echo "${ARGS_PROPERTIES[i]}"
            return 0
        fi
    done
    return 1
}

# Return 0 if an argument name is defined.
_arg_defined() {
    local name=$1
    local i
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=_NUM_PROPERTIES_)); do
        if [[ "${ARGS_PROPERTIES[i]}" == "$name" ]]; then
            return 0
        fi
    done
    return 1
}

# Get a property value for a named argument.
# Usage: _get_prop arg_name property_index
# Prints the property value; returns 0 if found.
_get_prop() {
    local name=$1
    local prop=$2
    local i
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=_NUM_PROPERTIES_)); do
        if [[ "${ARGS_PROPERTIES[i]}" == "$name" ]]; then
            echo "${ARGS_PROPERTIES[i+prop]}"
            return 0
        fi
    done
    return 1
}

# Function to define a command-line argument
# Usage: define_arg "arg_name[|short]" ["default"] ["help text"] ["type"] ["required"]
define_arg() {
    local arg_spec=$1
    local arg_name=${arg_spec%%|*}
    local short_name=""
    local default_value help_text arg_type arg_required

    if [[ "$arg_spec" == *"|"* ]]; then
        short_name=${arg_spec##*|}
        if [[ ${#short_name} -ne 1 ]]; then
            display_error "Short names must be single char: $short_name"
        fi
    fi

    default_value=${2:-""}
    if [[ "$2" == "$_NULL_VALUE_" ]]; then
        default_value=""
    fi
    # Store empty defaults as placeholder so indexed-array slots stay aligned
    local stored_default="$default_value"
    if [[ -z "$stored_default" ]]; then
        stored_default="$_NULL_VALUE_"
    fi

    help_text=${3:-""}
    arg_type=${4:-"string"}
    arg_required=${5:-"optional"}

    ARGS_PROPERTIES+=("$arg_name" "$stored_default" "$help_text" "$arg_type" "$arg_required" "$short_name")
    printf -v "$arg_name" '%s' "$default_value"
}

# Function to parse command-line arguments
# Usage: parse_args "$@"
parse_args() {
    local key
    local -a keys
    local i letter resolved prop_type prop_default prop_required
    local arg_name

    while [[ $# -gt 0 ]]; do
        key="$1"
        keys=()

        # Expand clustered short options (-abc) into long argument names
        if [[ $key == -* && $key != --* ]]; then
            key="${key#-}"
            for ((i=0; i<${#key}; i++)); do
                letter=${key:i:1}
                resolved=$(_resolve_short_name "$letter") || display_error "Unknown option: $letter"
                keys+=("$resolved")
            done
        else
            key="${key#--}"
            keys=("$key")
        fi

        for ((i=0; i<${#keys[@]}; i++)); do
            key=${keys[$i]}
            if _arg_defined "$key"; then
                prop_type=$(_get_prop "$key" "$_TYPE_")
                if [[ "$prop_type" == "bool" ]]; then
                    printf -v "$key" '%s' "true"
                else
                    [[ -z "$2" || "$2" == --* ]] && display_error "Missing value for argument --$key"
                    printf -v "$key" '%s' "$2"
                    shift # past value
                fi
            else
                display_error "Unknown option: $key"
            fi
        done
        shift # past argument / flag cluster
    done

    # Check for required arguments and apply defaults
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=_NUM_PROPERTIES_)); do
        arg_name="${ARGS_PROPERTIES[i]}"
        prop_required="${ARGS_PROPERTIES[i+_REQUIRED_]}"
        prop_default="${ARGS_PROPERTIES[i+_DEFAULT_]}"
        if [[ "$prop_default" == "$_NULL_VALUE_" ]]; then
            prop_default=""
        fi

        if [[ "$prop_required" == "required" && -z "${!arg_name}" ]]; then
            display_error "Missing required argument --$arg_name"
        fi
        if [[ -z "${!arg_name}" ]]; then
            printf -v "$arg_name" '%s' "$prop_default"
        fi
    done
}

# Function to display help
# Usage: show_help
show_help() {
    local i arg_name short prop_type prop_help
    [[ -n "$SCRIPT_DESCRIPTION" ]] && echo -e "$SCRIPT_DESCRIPTION\n"

    echo "usage: $0 [options...]"
    echo "options:"
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=_NUM_PROPERTIES_)); do
        arg_name="${ARGS_PROPERTIES[i]}"
        prop_type="${ARGS_PROPERTIES[i+_TYPE_]}"
        prop_help="${ARGS_PROPERTIES[i+_HELP_]}"
        short="${ARGS_PROPERTIES[i+_SHORT_]}"
        if [[ -n "$short" ]]; then
            short="-$short, "
        fi
        if [[ "$prop_type" != "bool" ]]; then
            echo "  $short--$arg_name [TXT]: $prop_help"
        else
            echo "  $short--$arg_name: $prop_help"
        fi
    done
}

# Function to check for help option
# Usage: check_for_help "$@"
check_for_help() {
    local arg
    for arg in "$@"; do
        [[ $arg == "-h" || $arg == "--help" ]] && { show_help; exit 0; }
    done
}
