#/usr/bin/env bash
SCRIPT_DESCRIPTION="argsparse3.sh is a Bash 3 library for defining script arguments"
FLAG_BEHAVIOUR="Add the flag to set the argument to 'true' (don't use '--flag true')"

ARGS_PROPERTIES=()

_NULL_VALUE_="null"
_DEFAULT_=1
_HELP_=2
_TYPE_=3
_REQUIRED_=4

# Function to set the script description
# Usage: set_description "Description text"
set_description() {
    SCRIPT_DESCRIPTION="$1"
}

show_help() {
    local args=( "${ARGS_PROPERTIES[@]}" )
    local prefix="   "
    
    echo -e "\nusage: $0 [arguments...]"
    echo "$SCRIPT_DESCRIPTION"
    echo ""
    echo "arguments:"
    for ((i=0; i<${#args[@]}; i+=5)); do
        [[ ${args[i+_DEFAULT_]} == "$_NULL_VALUE_" ]] &&  args[i+_DEFAULT_]=''
        if [[ ${args[i+_TYPE_]} == "bool" ]]; then
            args[i+_TYPE_]=''
            args[i+_HELP_]="${args[i+_HELP_]} $FLAG_BEHAVIOUR"
        else
            args[i+_TYPE_]="<${args[i+_TYPE_]}>"
        fi
        printf "%s %-20s: (%8s) %s\n" "$prefix" "--${args[i]} ${args[i+_TYPE_]}" "${args[i+_REQUIRED_]}" "${args[i+_HELP_]} (defaults to '${args[i+_DEFAULT_]}')"
    done
    printf "\n%s %-20s: Display this help\n"  "$prefix" "-h | --help"
}

check_required() {
    for ((i=0; i<${#ARGS_PROPERTIES[@]}; i+=5)); do
        if [[ "${ARGS_PROPERTIES[i+_REQUIRED_]}" == "required" ]]; then
            if ! (echo "$@" | grep "${ARGS_PROPERTIES[i]}") >/dev/null ; then
                echo "'--${ARGS_PROPERTIES[i]}' is required"
                show_help
                exit 1
            fi
        fi
    done
}

define_arg() {
    arg_name=$1
    arg_value=${2:-"$_NULL_VALUE_"}
    arg_help=${3:-""}
    arg_type=${4:-"string"}
    arg_required=${5:-"optional"}
    if [[ "$arg_required" == "required" ]]; then
        arg_value="$_NULL_VALUE_"
    fi
    ARGS_PROPERTIES+=("$arg_name" "$arg_value" "$arg_help" "$arg_type" "$arg_required")
    if [[ "$arg_value" == "$_NULL_VALUE_" ]]; then
        arg_value=""
    fi
    export "$arg_name"="$arg_value"
}

parse_args() {
    # Check for 'help' flags
    if (echo "$@" | grep -- "-h" > /dev/null) || (echo "$@" | grep -- "--help" > /dev/null); then
        show_help
        exit 0
    fi
    # Check for missing required arguments
    check_required "$@"
    while [[ $# -gt 0 ]]; do
        for ((i=0; i<${#ARGS_PROPERTIES[*]}; i+=5)); do
            key="${1#--}" # remove '--' prefix
            if [[ "$key" == "${ARGS_PROPERTIES[i]}" ]]; then
                case ${ARGS_PROPERTIES[i+_TYPE_]} in
                'string')
                    if [[ -z "$2" || "$2" == --* ]]; then
                        echo "Missing value for argument --$key"
                        exit 1
                    else
                        export "$key"="$2"
                        shift 2
                    fi
                ;;
                'bool')
                    export "$key"='true'
                    shift
                ;;
                *)
                    echo "Unknown argument type '${ARGS_PROPERTIES[i+_TYPE_]}' for '$key'"
                    exit 1
                ;;
                esac
            fi
        done
        shift # Skip undefined argument
    done
}