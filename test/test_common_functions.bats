#!/usr/bin/env bats

# test_common_functions.bats
# Tests for the wild-common.sh library functions

load 'test_helper'

setup() {
    setup_test_project "common-test"
    cd "$TEST_PROJECT_DIR"
}

teardown() {
    teardown_test_project "common-test"
}

@test "find_wc_home from project root" {
    cd "$TEST_PROJECT_DIR"
    WC_HOME_RESULT=$(find_wc_home)
    assert_equal "$WC_HOME_RESULT" "$TEST_PROJECT_DIR"
}

@test "find_wc_home from nested subdirectory" {
    mkdir -p "$TEST_PROJECT_DIR/deep/nested/path"
    cd "$TEST_PROJECT_DIR/deep/nested/path"
    WC_HOME_RESULT=$(find_wc_home)
    assert_equal "$WC_HOME_RESULT" "$TEST_PROJECT_DIR"
}

@test "find_wc_home when no project found" {
    cd /tmp
    run find_wc_home
    assert_failure
}

@test "init_wild_env sets WC_HOME correctly" {
    mkdir -p "$TEST_PROJECT_DIR/deep/nested"
    cd "$TEST_PROJECT_DIR/deep/nested"
    unset WC_HOME WC_ROOT
    init_wild_env
    assert_equal "$WC_HOME" "$TEST_PROJECT_DIR"
}

@test "init_wild_env sets WC_ROOT correctly" {
    cd "$TEST_PROJECT_DIR"
    unset WC_HOME WC_ROOT
    init_wild_env
    # WC_ROOT is set (value depends on test execution context)
    assert [ -n "$WC_ROOT" ]
}

@test "check_wild_directory passes when in project" {
    cd "$TEST_PROJECT_DIR"
    run check_wild_directory
    assert_success
}

@test "print functions work correctly" {
    cd "$TEST_PROJECT_DIR"
    run bash -c '
        source "$PROJECT_ROOT/bin/wild-common.sh"
        print_header "Test Header"
        print_info "Test info message"
        print_warning "Test warning message"
        print_success "Test success message"
        print_error "Test error message"
    '
    assert_success
    assert_output --partial "Test Header"
    assert_output --partial "Test info message"
}

@test "command_exists works for existing command" {
    run command_exists "bash"
    assert_success
}

@test "command_exists fails for nonexistent command" {
    run command_exists "nonexistent-command-xyz"
    assert_failure
}

@test "generate_random_string produces correct length" {
    RANDOM_STR=$(generate_random_string 16)
    assert_equal "${#RANDOM_STR}" "16"
}