#!/bin/bash
set -e
set -o pipefail

# Source common utilities
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../bin/wild-common.sh"

# Initialize Wild-Cloud environment
init_wild_env

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
DOCKER_REGISTRY_DIR="${CLUSTER_SETUP_DIR}/docker-registry"

print_header "Setting up Docker Registry"

# Collect required configuration variables
print_info "Collecting Docker Registry configuration..."

# Get current values
current_registry_host=$(get_current_config "cloud.dockerRegistryHost")
current_storage=$(get_current_config "cluster.dockerRegistry.storage")

# Prompt for Docker Registry host
registry_host=$(prompt_with_default "Enter Docker Registry hostname" "registry.local.example.com" "${current_registry_host}")
wild-config-set "cloud.dockerRegistryHost" "${registry_host}"

# Prompt for storage size
storage=$(prompt_with_default "Enter Docker Registry storage size" "100Gi" "${current_storage}")
wild-config-set "cluster.dockerRegistry.storage" "${storage}"

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled Docker Registry templates..."
if [ ! -d "${DOCKER_REGISTRY_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

# Apply the docker registry manifests using kustomize
kubectl apply -k "${DOCKER_REGISTRY_DIR}/kustomize"

echo "Waiting for Docker Registry to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/docker-registry -n docker-registry

echo "Docker Registry setup complete!"

# Show deployment status
kubectl get pods -n docker-registry
kubectl get services -n docker-registry