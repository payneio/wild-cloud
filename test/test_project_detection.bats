#!/usr/bin/env bats

# test_project_detection.bats
# Tests for wild-cloud project detection from various directory structures

load 'test_helper'

setup() {
    setup_test_project "detection-test"
}

teardown() {
    teardown_test_project "detection-test"
}

@test "script execution from project root" {
    cd "$TEST_PROJECT_DIR"
    run "$PROJECT_ROOT/bin/wild-cluster-node-up" --help
    assert_success
}

@test "script execution from nested subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/deep/very/nested/path"
    cd "$TEST_PROJECT_DIR/deep/very/nested/path"
    run "$PROJECT_ROOT/bin/wild-cluster-node-up" --help
    assert_success
}

@test "wild-cluster-node-up works from subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/subdir"
    cd "$TEST_PROJECT_DIR/subdir"
    run "$PROJECT_ROOT/bin/wild-cluster-node-up" --help
    assert_success
}

@test "wild-setup works from subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/subdir"
    cd "$TEST_PROJECT_DIR/subdir"
    run "$PROJECT_ROOT/bin/wild-setup" --help
    assert_success
}

@test "wild-setup-cluster works from subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/subdir"
    cd "$TEST_PROJECT_DIR/subdir"
    run "$PROJECT_ROOT/bin/wild-setup-cluster" --help
    assert_success
}

@test "wild-cluster-config-generate works from subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/subdir"
    cd "$TEST_PROJECT_DIR/subdir"
    run "$PROJECT_ROOT/bin/wild-cluster-config-generate" --help
    assert_success
}

@test "config access from subdirectories" {
    mkdir -p "$TEST_PROJECT_DIR/config-test"
    cd "$TEST_PROJECT_DIR/config-test"
    
    # Set up environment like the scripts do
    unset WC_HOME WC_ROOT
    init_wild_env
    
    CLUSTER_NAME=$("$PROJECT_ROOT/bin/wild-config" cluster.name 2>/dev/null)
    assert_equal "$CLUSTER_NAME" "test-cluster"
}

@test "environment variables from project root" {
    cd "$TEST_PROJECT_DIR"
    unset WC_HOME WC_ROOT
    source "$PROJECT_ROOT/bin/wild-common.sh"
    init_wild_env
    
    assert_equal "$WC_HOME" "$TEST_PROJECT_DIR"
    assert [ -n "$WC_ROOT" ]
}

@test "environment variables from nested directory" {
    mkdir -p "$TEST_PROJECT_DIR/deep/very"
    cd "$TEST_PROJECT_DIR/deep/very"
    unset WC_HOME WC_ROOT
    source "$PROJECT_ROOT/bin/wild-common.sh"
    init_wild_env
    
    assert_equal "$WC_HOME" "$TEST_PROJECT_DIR"
    assert [ -n "$WC_ROOT" ]
}

@test "scripts fail gracefully outside project" {
    # Create a temporary directory without .wildcloud
    TEMP_NO_PROJECT=$(create_test_project "no-wildcloud")
    rm -rf "$TEMP_NO_PROJECT/.wildcloud"
    cd "$TEMP_NO_PROJECT"
    
    # The script should fail because check_wild_directory won't find .wildcloud
    run "$PROJECT_ROOT/bin/wild-cluster-node-up" 192.168.1.1 --dry-run
    assert_failure
    
    remove_test_project "no-wildcloud"
}