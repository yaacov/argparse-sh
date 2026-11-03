#!/bin/bash

# argparse.sh contains bash functions that streamlines the management of
# command-line arguments in Bash scripts 

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

# Declare associative arrays for argument properties and short name mapping
declare -A ARG_PROPERTIES SHORT_NAMES SEMAN_TROHS

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

# Function to define a command-line argument
# Usage: define_arg "arg_name" ["default"] ["help text"] ["type"] ["required"]
_NULL_VALUE_="null"
define_arg() {
    local arg_name=${1%%|*}
    if [[ ${1} =~ \| ]]; then
        local short_name=${1##*|}
        if [[ ${#short_name} -ne 1 ]]; then
            display_error "Short names must be single char: $short_name"
        else
            SHORT_NAMES[$short_name]=$arg_name
            SEMAN_TROHS[$arg_name]=$short_name
        fi
    fi

    ARG_PROPERTIES["$arg_name,default"]=${2:-""} # Default value
    if [[ "$2" == "$_NULL_VALUE_" ]]; then
        ARG_PROPERTIES["$arg_name,default"]="" # Default value (for compatibility with 'argparse3.sh')
    fi
    ARG_PROPERTIES["$arg_name,help"]=${3:-""}    # Help text
    ARG_PROPERTIES["$arg_name,type"]=${4:-"string"} # Type [ "string" | "bool" ], default is "string".
    ARG_PROPERTIES["$arg_name,required"]=${5:-"optional"} # Required flag ["required" | "optional"], default is "optional"
}

# Function to parse command-line arguments
# Usage: parse_args "$@"
parse_args() {
    local -a keys
    while [[ $# -gt 0 ]]; do
        key="$1"
        keys=()

        # expand single letter arguments into a list of argument names
        if [[ $key == -* && $key != --* ]]; then
            key="${key#-}" # Remove the '-' prefix
            for (( i=0; i<${#key}; i++ )); do
                local letter=${key:i:1}
                if [[ -z ${SHORT_NAMES[$letter]} ]]; then
                    display_error "Unknown option: $letter"
                else
                    keys+=( ${SHORT_NAMES[$letter]} )
                fi
            done
        else
            key="${key#--}" # Remove the '--' prefix
            keys=( $key )
        fi

        for ((i=0; $i<${#keys[@]}; i=$i+1)); do
            key=${keys[$i]}
            if [[ -n "${ARG_PROPERTIES[$key,help]}" ]]; then
                if [[ "${ARG_PROPERTIES[$key,type]}" == "bool" ]]; then
                    declare -g "$key"="true"
                elif [[ $i -eq "${#keys[@]}" ]]; then
                    display_error "Missing value for argument --$key" #only the last key can take an argument
                else
                    [[ -z "$2" || "$2" == --* ]] && display_error "Missing value for argument --$key"
                    declare -g "$key"="$2"
                    shift # past value
                fi
            else
                display_error "Unknown option: $key"
            fi
        done
        shift # past argument
    done

    # Check for required arguments
    for arg in "${!ARG_PROPERTIES[@]}"; do
        arg_name="${arg%%,*}" # Extract argument name
        [[ "${ARG_PROPERTIES[$arg_name,required]}" == "required" && -z "${!arg_name}" ]] && display_error "Missing required argument --$arg_name"
    done

    # Set defaults for any unset arguments
    for arg in "${!ARG_PROPERTIES[@]}"; do
        arg_name="${arg%%,*}" # Extract argument name
        [[ -z "${!arg_name}" ]] && declare -g "$arg_name"="${ARG_PROPERTIES[$arg_name,default]}"
    done
}

# Function to display help
# Usage: show_help
show_help() {
    local short
    [[ -n "$SCRIPT_DESCRIPTION" ]] && echo -e "$SCRIPT_DESCRIPTION\n"

    echo "usage: $0 [options...]"
    echo "options:"
    for arg in "${!ARG_PROPERTIES[@]}"; do
        arg_name="${arg%%,*}" # Extract argument name
        [[ -z ${SEMAN_TROHS[$arg_name]} ]] && short='' || short="-${SEMAN_TROHS[$arg_name]}, "
        [[ "${arg##*,}" == "help" ]] && {
            [[ "${ARG_PROPERTIES[$arg_name,type]}" != "bool" ]] && echo "  $short--$arg_name [TXT]: ${ARG_PROPERTIES[$arg]}" || echo "  $short--$arg_name: ${ARG_PROPERTIES[$arg]}"
        }
    done
}

# Function to check for help option
# Usage: check_for_help "$@"
check_for_help() {
    for arg in "$@"; do
        [[ $arg == "-h" || $arg == "--help" ]] && { show_help; exit 0; }
    done
}
