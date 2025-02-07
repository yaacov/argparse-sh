#!/bin/bash

# Source the argparse script
source ./argparse.sh

# Set script description
set_description "This script demonstrates handling flags."

# Define a flag argument
define_arg "debug" "false" "Enable debug mode" "bool"

# Check for -h and --help
check_for_help "$@"

# Parse the arguments
parse_args "$@"

# Main script logic
if [[ $debug == "true" ]]; then
    echo "Debug mode is ON."
else
    echo "Debug mode is OFF."
fi

# Usage:
# ./flags_example.sh --debug
