#!/usr/bin/env bash

# test_helper.bash
# Common setup and utilities for bats tests

# Load bats helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test environment variables
export TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
export PROJECT_ROOT="$(dirname "$TEST_DIR")"
export TMP_DIR="$TEST_DIR/tmp"

# Set up test environment
setup_test_project() {
    local project_name="${1:-test-project}"
    
    # Create tmp directory
    mkdir -p "$TMP_DIR"
    
    # Create test project
    export TEST_PROJECT_DIR="$TMP_DIR/$project_name"
    mkdir -p "$TEST_PROJECT_DIR/.wildcloud"
    
    # Copy fixture config if it exists
    if [ -f "$TEST_DIR/fixtures/sample-config.yaml" ]; then
        cp "$TEST_DIR/fixtures/sample-config.yaml" "$TEST_PROJECT_DIR/config.yaml"
    fi
    
    # Source wild-common.sh
    source "$PROJECT_ROOT/bin/wild-common.sh"
}

# Clean up test environment  
teardown_test_project() {
    local project_name="${1:-test-project}"
    
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR/$project_name"
    fi
}

# Create additional test project
create_test_project() {
    local project_name="$1"
    local project_dir="$TMP_DIR/$project_name"
    
    mkdir -p "$project_dir/.wildcloud"
    
    # Copy fixture config if requested
    if [ $# -gt 1 ] && [ "$2" = "with-config" ]; then
        cp "$TEST_DIR/fixtures/sample-config.yaml" "$project_dir/config.yaml"
    fi
    
    echo "$project_dir"
}

# Remove additional test project
remove_test_project() {
    local project_name="$1"
    rm -rf "$TMP_DIR/$project_name"
}