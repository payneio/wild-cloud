# Test Directory

This directory is used for testing wild-cloud functionality using the Bats testing framework.

## Contents
- `test_helper.bash` - Shared Bats test setup and utilities
- `test_helper/` - Bats framework extensions (bats-support, bats-assert)
- `bats/` - Bats core framework (git submodule)
- `fixtures/` - Test data and sample configuration files
- `*.bats` - Bats test files for different components
- `run_bats_tests.sh` - Runs the complete Bats test suite
- `tmp/` - Temporary test projects (auto-created/cleaned)

## Test Files

### `test_common_functions.bats`
Tests the core functions in `wild-common.sh`:
- `find_wc_home()` - Project root detection
- `init_wild_env()` - Environment setup
- `check_wild_directory()` - Project validation
- Print functions and utilities

### `test_project_detection.bats`
Tests project detection and script execution:
- Script execution from various directory levels
- Environment variable setup from different paths
- Proper failure outside project directories

### `test_config_functions.bats`
Tests configuration and secret access:
- `get_current_config()` function
- `get_current_secret()` function
- Configuration access from subdirectories
- Fixture data usage

## Running Tests

```bash
# Initialize git submodules (first time only)
git submodule update --init --recursive

# Run all Bats tests
./run_bats_tests.sh

# Run individual test files
./bats/bin/bats test_common_functions.bats
./bats/bin/bats test_project_detection.bats
./bats/bin/bats test_config_functions.bats

# Test from subdirectory (should work)
cd deep/nested/path
../../../bin/wild-cluster-node-up --help
```

## Fixtures

The `fixtures/` directory contains:
- `sample-config.yaml` - Complete test configuration
- `sample-secrets.yaml` - Test secrets file

## Adding New Tests

1. Create `test_<feature>.bats` following the Bats pattern:
   ```bash
   #!/usr/bin/env bats
   
   load 'test_helper'
   
   setup() {
       setup_test_project "feature-test"
   }
   
   teardown() {
       teardown_test_project "feature-test"
   }
   
   @test "feature description" {
       # Your test here using Bats assertions
       run some_command
       assert_success
       assert_output "expected output"
   }
   ```

2. Add test data to `fixtures/` if needed

3. The Bats runner will automatically discover and run new tests

## Common Test Functions

From `test_helper.bash`:
- `setup_test_project "name"` - Creates test project in `tmp/`
- `teardown_test_project "name"` - Removes test project
- `create_test_project "name" [with-config]` - Creates additional test projects
- `remove_test_project "name"` - Removes additional test projects

## Bats Assertions

Available through bats-assert:
- `assert_success` / `assert_failure` - Check command exit status
- `assert_output "text"` - Check exact output
- `assert_output --partial "text"` - Check output contains text
- `assert_equal "$actual" "$expected"` - Check equality
- `assert [ condition ]` - General assertions