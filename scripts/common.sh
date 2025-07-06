#!/bin/bash

# wild-common.sh
# Common utility functions for Wild Cloud shell scripts
# Source this file at the beginning of scripts to access shared functionality
#
# USAGE PATTERN:
# Replace the common function definitions in your script with:
#
#   #!/bin/bash
#   set -e
#   set -o pipefail
#   
#   # Source common utilities
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wild-common.sh"
#   
#   # Initialize Wild Cloud environment
#   init_wild_env
#
# AVAILABLE FUNCTIONS:
# - Print functions: print_header, print_info, print_warning, print_success, print_error
# - Config functions: get_current_config, get_current_secret, prompt_with_default  
# - Config helpers: prompt_if_unset_config, prompt_if_unset_secret
# - Validation: check_wild_directory, check_basic_config
# - Utilities: command_exists, file_readable, dir_writable, generate_random_string

# =============================================================================
# COLOR VARIABLES
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# PRINT FUNCTIONS
# =============================================================================

# Print functions for consistent output formatting
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# =============================================================================
# CONFIGURATION UTILITIES
# =============================================================================

# Function to get current config value safely
get_current_config() {
    local key="$1"
    if [ -f "${WC_HOME}/config.yaml" ]; then
        set +e
        result=$(wild-config "${key}" 2>/dev/null)
        set -e
        echo "${result}"
    else
        echo ""
    fi
}

# Function to get current secret value safely
get_current_secret() {
    local key="$1"
    if [ -f "${WC_HOME}/secrets.yaml" ]; then
        set +e
        result=$(wild-secret "${key}" 2>/dev/null)
        set -e
        echo "${result}"
    else
        echo ""
    fi
}

# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local current_value="$3"
    local result
    
    if [ -n "${current_value}" ] && [ "${current_value}" != "null" ]; then
        printf "%s [current: %s]: " "${prompt}" "${current_value}" >&2
        read -r result
        if [ -z "${result}" ]; then
            result="${current_value}"
        fi
    elif [ -n "${default}" ]; then
        printf "%s [default: %s]: " "${prompt}" "${default}" >&2
        read -r result
        if [ -z "${result}" ]; then
            result="${default}"
        fi
    else
        printf "%s: " "${prompt}" >&2
        read -r result
        while [ -z "${result}" ]; do
            printf "This value is required. Please enter a value: " >&2
            read -r result
        done
    fi
    
    echo "${result}"
}

# Prompt for config value only if it's not already set
prompt_if_unset_config() {
    local config_path="$1"
    local prompt="$2"
    local default="$3"
    
    local current_value
    current_value=$(get_current_config "${config_path}")
    
    if [ -z "${current_value}" ] || [ "${current_value}" = "null" ]; then
        local new_value
        new_value=$(prompt_with_default "${prompt}" "${default}" "")
        wild-config-set "${config_path}" "${new_value}"
        print_info "Set ${config_path} = ${new_value}"
    else
        print_info "Using existing ${config_path} = ${current_value}"
    fi
}

# Prompt for secret value only if it's not already set
prompt_if_unset_secret() {
    local secret_path="$1"
    local prompt="$2"
    local default="$3"
    
    local current_value
    current_value=$(get_current_secret "${secret_path}")
    
    if [ -z "${current_value}" ] || [ "${current_value}" = "null" ]; then
        local new_value
        new_value=$(prompt_with_default "${prompt}" "${default}" "")
        wild-secret-set "${secret_path}" "${new_value}"
        print_info "Set secret ${secret_path}"
    else
        print_info "Using existing secret ${secret_path}"
    fi
}

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# Find the wild-cloud project home directory by searching for .wildcloud
# Returns the path to the project root, or empty string if not found
find_wc_home() {
    local current_dir="$(pwd)"
    
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.wildcloud" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Not found
    return 1
}

# Initialize common Wild Cloud environment variables
# Call this function at the beginning of scripts
init_wild_env() {
    if [ -z "${WC_ROOT}" ]; then
        print "Fail"
        exit 1
    else
    
    # Check if WC_ROOT is a valid directory
    if [ ! -d "${WC_ROOT}" ]; then
        echo "ERROR: WC_ROOT directory does not exist! Did you install the wild-cloud root?"
        exit 1
    fi

    # Check if WC_ROOT/bin is in path
    if [[ ":$PATH:" != *":$WC_ROOT/bin:"* ]]; then
        echo "ERROR: Your wildcloud seed bin path should be in your PATH environment."
        exit 1
    fi

    WC_HOME="$(find_wc_home)"
    if [ -z "${WC_HOME}" ]; then
        echo "ERROR: This command must be run from within a wildcloud home directory."
        exit 1
    fi
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if we're in a wild-cloud directory
check_wild_directory() {
    local found_home
    if found_home="$(find_wc_home)"; then
        # Update WC_HOME if it's not set correctly
        if [ -z "${WC_HOME}" ] || [ "${WC_HOME}" != "$found_home" ]; then
            WC_HOME="$found_home"
            export WC_HOME
        fi
    else
        print_error "No wild-cloud project found in current directory or ancestors"
        print_info "Run 'wild-setup-scaffold' first to initialize a wild-cloud project"
        print_info "Current working directory: $(pwd)"
        local search_path="$(pwd)"
        while [ "$search_path" != "/" ]; do
            print_info "  Searched: $search_path"
            search_path="$(dirname "$search_path")"
        done
        exit 1
    fi
}

# Check if basic configuration exists
check_basic_config() {
    if [ -z "$(get_current_config "operator.email")" ]; then
        print_error "Basic configuration is missing"
        print_info "Run 'wild-setup-scaffold' first to configure basic settings"
        exit 1
    fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a file exists and is readable
file_readable() {
    [ -f "$1" ] && [ -r "$1" ]
}

# Check if a directory exists and is writable
dir_writable() {
    [ -d "$1" ] && [ -w "$1" ]
}

# Generate a random string of specified length
generate_random_string() {
    local length="${1:-32}"
    openssl rand -hex "$((length / 2))" 2>/dev/null || \
    head -c "$length" /dev/urandom | base64 | tr -d '=+/' | cut -c1-"$length"
}