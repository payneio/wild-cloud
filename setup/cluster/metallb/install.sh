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
METALLB_DIR="${CLUSTER_SETUP_DIR}/metallb"

print_header "Setting up MetalLB"

# Collect required configuration variables
print_info "Collecting MetalLB configuration..."

# Get current values
current_ip_pool=$(get_current_config "cluster.ipAddressPool")
current_lb_ip=$(get_current_config "cluster.loadBalancerIp")

# Prompt for IP address pool
ip_pool=$(prompt_with_default "Enter IP address pool for MetalLB (CIDR format, e.g., 192.168.1.240-192.168.1.250)" "192.168.1.240-192.168.1.250" "${current_ip_pool}")
wild-config-set "cluster.ipAddressPool" "${ip_pool}"

# Prompt for load balancer IP
lb_ip=$(prompt_with_default "Enter load balancer IP address" "192.168.1.240" "${current_lb_ip}")
wild-config-set "cluster.loadBalancerIp" "${lb_ip}"

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
