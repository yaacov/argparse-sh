#!/usr/bin/env bash
# Version-agnostic argparse test suite. Invoked as:
#   BASH_BIN=/path/to/bash ./tests/suite.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASH_BIN="${BASH_BIN:-/bin/bash}"

pass=0
fail=0

assert_ok() {
    local name=$1
    shift
    local out
    if out=$("$BASH_BIN" "$@" 2>&1); then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name (expected success)"
        echo "$out"
        fail=$((fail + 1))
    fi
}

assert_output_contains() {
    local name=$1
    local needle=$2
    shift 2
    local out rc=0
    out=$("$BASH_BIN" "$@" 2>&1) || rc=$?
    if [[ $rc -eq 0 && "$out" == *"$needle"* ]]; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name (expected output containing '$needle', rc=$rc)"
        echo "$out"
        fail=$((fail + 1))
    fi
}

assert_fails() {
    local name=$1
    shift
    local out rc=0
    out=$("$BASH_BIN" "$@" 2>&1) || rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name (expected non-zero exit)"
        echo "$out"
        fail=$((fail + 1))
    fi
}

assert_fails_with() {
    local name=$1
    local needle=$2
    shift 2
    local out rc=0
    out=$("$BASH_BIN" "$@" 2>&1) || rc=$?
    if [[ $rc -ne 0 && "$out" == *"$needle"* ]]; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name (expected non-zero and '$needle', rc=$rc)"
        echo "$out"
        fail=$((fail + 1))
    fi
}

echo "=== argparse suite ==="
echo "BASH_BIN=$BASH_BIN"
"$BASH_BIN" --version | head -1
echo

# Happy paths
assert_output_contains "optional+required" "Operating in mode: test" \
    ./examples/optional_required_example.sh --mode test

assert_output_contains "optional+required verbose" "Verbose mode enabled." \
    ./examples/optional_required_example.sh --mode test --verbose

assert_output_contains "bool flag on" "Debug mode is ON." \
    ./examples/flags_example.sh --debug

assert_output_contains "bool flag off" "Debug mode is OFF." \
    ./examples/flags_example.sh

assert_output_contains "empty/null defaults" "Hello World!" \
    ./examples/compatible_empty_value.sh

assert_output_contains "simple required" "Welcome, Alice!" \
    ./examples/simple_example.sh --username Alice

assert_output_contains "short names" "Welcome, Alice!" \
    ./examples/short_names_example.sh -u Alice

# Failure cases
assert_fails_with "missing required" "Missing required argument" \
    ./examples/optional_required_example.sh

assert_fails_with "unknown option" "Unknown option" \
    ./examples/optional_required_example.sh --mode test --nope

assert_fails "simple missing required" \
    ./examples/simple_example.sh

echo
echo "=== results: $pass passed, $fail failed ==="
[[ $fail -eq 0 ]]
