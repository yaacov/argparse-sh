#!/bin/bash

# Source the argparse script
source ./argparse.sh

# Define an argument
define_arg "username|u" "Benjamina" "Username for login" "string" "optional"
define_arg "quotes|q" "" "Print Quotes" "bool"
define_arg "newline|n" "-n" "Append newline" "bool"

# Parse the arguments
parse_args "$@"

set -euo pipefail
IFS=$'\n\t'

# Main script logic
[[ $newline == "true" ]] && newline=""
[[ $quotes == "true" ]] && quotes="'"
echo $newline "${quotes}Welcome, $username!${quotes}"

# Usage:
# ./simple_example.sh -nqu Alice
# ./simple_example.sh --quotes --newline --username Alice
