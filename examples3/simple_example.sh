#!/bin/bash

# Source the argparse script
source ./argparse3.sh

# Define an argument
define_arg "username" "" "Username for login" "string" "true"

# Parse the arguments
parse_args "$@"

# Main script logic
echo "Welcome, $username!"

# Usage:
# ./simple_example.sh --username Alice
