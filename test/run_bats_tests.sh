#!/bin/bash

# run_bats_tests.sh
# Run all Bats tests in the test directory

set -e

# Get the directory where this script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if bats is available
if [ ! -f "$TEST_DIR/bats/bin/bats" ]; then
    echo "Error: Bats not found. Make sure git submodules are initialized:"
    echo "  git submodule update --init --recursive"
    exit 1
fi

echo "Running Wild Cloud Bats Test Suite..."
echo "======================================"

# Run all .bats files
"$TEST_DIR/bats/bin/bats" "$TEST_DIR"/*.bats

echo ""
echo "All tests completed!"