#!/usr/bin/env bats

# test_config_functions.bats
# Tests for config and secret access functions

load 'test_helper'

setup() {
    setup_test_project "config-test"
    cd "$TEST_PROJECT_DIR"
    init_wild_env
}

teardown() {
    teardown_test_project "config-test"
}

@test "get_current_config with existing config" {
    CLUSTER_NAME=$(get_current_config "cluster.name")
    assert_equal "$CLUSTER_NAME" "test-cluster"
}

@test "get_current_config with nested path" {
    VIP=$(get_current_config "cluster.nodes.control.vip")
    assert_equal "$VIP" "192.168.100.200"
}

@test "get_current_config with non-existent key" {
    NONEXISTENT=$(get_current_config "nonexistent.key")
    assert_equal "$NONEXISTENT" ""
}

@test "active nodes configuration access - interface" {
    CONTROL_NODE_INTERFACE=$(get_current_config "cluster.nodes.active.\"192.168.100.201\".interface")
    assert_equal "$CONTROL_NODE_INTERFACE" "eth0"
}

@test "active nodes configuration access - maintenance IP" {
    MAINTENANCE_IP=$(get_current_config "cluster.nodes.active.\"192.168.100.201\".maintenanceIp")
    assert_equal "$MAINTENANCE_IP" "192.168.100.131"
}

@test "get_current_secret function" {
    # Create temporary secrets file for testing
    cp "$TEST_DIR/fixtures/sample-secrets.yaml" "$TEST_PROJECT_DIR/secrets.yaml"
    
    SECRET_VAL=$(get_current_secret "operator.cloudflareApiToken")
    assert_equal "$SECRET_VAL" "test_api_token_123456789"
}

@test "config access from subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/config-subdir"
    cd "$TEST_PROJECT_DIR/config-subdir"
    unset WC_HOME WC_ROOT
    init_wild_env
    
    SUBDIR_CLUSTER=$(get_current_config "cluster.name")
    assert_equal "$SUBDIR_CLUSTER" "test-cluster"
}