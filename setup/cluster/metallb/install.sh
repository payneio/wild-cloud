#!/bin/bash
set -e
set -o pipefail

# Initialize Wild-Cloud environment
if [ -z "${WC_ROOT}" ]; then
    print "WC_ROOT is not set."
    exit 1
else
    source "${WC_ROOT}/scripts/common.sh"
    init_wild_env
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
METALLB_DIR="${CLUSTER_SETUP_DIR}/metallb"

print_header "Setting up MetalLB"

# Collect required configuration variables
print_info "Collecting MetalLB configuration..."

# Prompt for configuration using helper functions
prompt_if_unset_config "cluster.ipAddressPool" "Enter IP address pool for MetalLB (CIDR format, e.g., 192.168.1.240-192.168.1.250)" "192.168.1.240-192.168.1.250"
prompt_if_unset_config "cluster.loadBalancerIp" "Enter load balancer IP address" "192.168.1.240"

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled MetalLB templates..."
if [ ! -d "${METALLB_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

echo "Deploying MetalLB..."
kubectl apply -k ${METALLB_DIR}/kustomize/installation

echo "Waiting for MetalLB to be deployed..."
kubectl wait --for=condition=Available deployment/controller -n metallb-system --timeout=60s
sleep 10 # Extra buffer for webhook initialization

echo "Customizing MetalLB..."
kubectl apply -k ${METALLB_DIR}/kustomize/configuration

echo "✅ MetalLB installed and configured"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl get ipaddresspools.metallb.io -n metallb-system"
