#!/usr/bin/env bash
# This script sources environment variables from:
# 1. The root .env file
# 2. App-specific .env files from enabled apps (with install=true in manifest.yaml)
# Dependencies are respected - if app A requires app B, app B's .env is sourced first
# set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
BIN_DIR="$PROJECT_DIR/bin"
APPS_DIR="$PROJECT_DIR/apps"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please install it first."
  echo "You can install it with: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq"
  exit 1
fi

# Source the main .env file
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file not found: $ENV_FILE"
  exit 1
fi

# Turn on allexport to automatically export all variables
set -a
source "$ENV_FILE"
set +a

# Function to parse YAML using yq
parse_yaml() {
  local yaml_file=$1
  
  # Extract the values we need using yq
  local name=$(yq eval '.name' "$yaml_file")
  local install=$(yq eval '.install' "$yaml_file")
  
  # Convert boolean to 1/0 for consistency
  if [ "$install" = "true" ]; then
    install="1"
  elif [ "$install" = "false" ]; then
    install="0"
  fi
  
  # Get dependencies as space-separated string
  local requires=""
  if yq eval 'has("requires")' "$yaml_file" | grep -q "true"; then
    requires=$(yq eval '.requires[].name' "$yaml_file" | tr '\n' ' ' | sed 's/ $//')
  fi
  
  # Return the parsed data as a single line
  echo "$name|$install|$requires"
}

# Resolve dependencies and create a list of apps to source in the right order
resolve_dependencies() {
  local apps=()
  local apps_to_install=()
  local deps_map=()
  
  # Parse all manifest files
  for manifest in "$APPS_DIR"/*/manifest.yaml; do
    local app_dir=$(dirname "$manifest")
    local app_name=$(basename "$app_dir")
    
    local parsed_data=$(parse_yaml "$manifest")
    IFS='|' read -r name install requires <<< "$parsed_data"
    
    # Add to our arrays
    apps+=("$name")
    if [ "$install" = "1" ] || [ "$install" = "true" ]; then
      apps_to_install+=("$name")
      deps_map+=("$name:$requires")
    fi
  done
  
  # Create an ordered list with dependencies first
  local ordered=()
  
  # First add apps with no dependencies
  for app in "${apps_to_install[@]}"; do
    local has_deps=false
    for dep_entry in "${deps_map[@]}"; do
      local app_name=$(echo "$dep_entry" | cut -d':' -f1)
      local deps=$(echo "$dep_entry" | cut -d':' -f2)
      
      if [ "$app_name" = "$app" ] && [ -n "$deps" ]; then
        has_deps=true
        break
      fi
    done
    
    if [ "$has_deps" = false ]; then
      ordered+=("$app")
    fi
  done
  
  # Now add apps with resolved dependencies
  local remaining=()
  for app in "${apps_to_install[@]}"; do
    if ! echo " ${ordered[*]} " | grep -q " $app "; then
      remaining+=("$app")
    fi
  done
  
  while [ ${#remaining[@]} -gt 0 ]; do
    local progress=false
    
    for app in "${remaining[@]}"; do
      local all_deps_resolved=true
      
      # Find the dependencies for this app
      local app_deps=""
      for dep_entry in "${deps_map[@]}"; do
        local app_name=$(echo "$dep_entry" | cut -d':' -f1)
        local deps=$(echo "$dep_entry" | cut -d':' -f2)
        
        if [ "$app_name" = "$app" ]; then
          app_deps="$deps"
          break
        fi
      done
      
      # Check if all dependencies are in the ordered list
      if [ -n "$app_deps" ]; then
        for dep in $app_deps; do
          if ! echo " ${ordered[*]} " | grep -q " $dep "; then
            all_deps_resolved=false
            break
          fi
        done
      fi
      
      if [ "$all_deps_resolved" = true ]; then
        ordered+=("$app")
        progress=true
      fi
    done
    
    # If no progress was made, we have a circular dependency
    if [ "$progress" = false ]; then
      echo "Warning: Circular dependency detected in app manifests"
      # Add remaining apps to avoid getting stuck
      ordered+=("${remaining[@]}")
      break
    fi
    
    # Update remaining list
    local new_remaining=()
    for app in "${remaining[@]}"; do
      if ! echo " ${ordered[*]} " | grep -q " $app "; then
        new_remaining+=("$app")
      fi
    done
    remaining=("${new_remaining[@]}")
  done
  
  echo "${ordered[@]}"
}

# Get ordered list of apps to source
ordered_apps=($(resolve_dependencies))

# Source app .env files in dependency order
# echo "Sourcing app environment files..."
for app in "${ordered_apps[@]}"; do
  app_env_file="$APPS_DIR/$app/config/.env"
  if [ -f "$app_env_file" ]; then
    # echo "  - $app"
    set -a
    source "$app_env_file"
    set +a
  fi
done

# Add bin directory to PATH
export PATH="$BIN_DIR:$PATH"