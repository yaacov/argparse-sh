#!/bin/bash

# Source the argparse script
source ./argparse.sh

# Set script description
set_description "This script demonstrates using empty values for string arguments."

# Define a flag argument
define_arg "greeting" "null" "Greeting" "string"
define_arg "username" "" "Name of the user" "string"

# Check for -h and --help
check_for_help "$@"

# Parse the arguments
parse_args "$@"

# Main script logic
if [[ "$username" == "" ]]; then
   username="World"
fi

echo "Hello $username! $greeting"

# Usage:
# ./empty_value.sh # Output: Hello World! ('greeting'='' even if we define the default value for 'greeting' as 'null')
# ./empty_value.sh --username Xavi --greeting "What's up?"  # Output: Hello Xavi! What's up?
