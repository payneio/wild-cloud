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
COREDNS_DIR="${CLUSTER_SETUP_DIR}/coredns"

print_header "Setting up CoreDNS for k3s"

# Collect required configuration variables
print_info "Collecting CoreDNS configuration..."

# Get current values
current_internal_domain=$(get_current_config "cloud.internalDomain")
current_lb_ip=$(get_current_config "cluster.loadBalancerIp")
current_external_resolver=$(get_current_config "cloud.dns.externalResolver")

# Prompt for internal domain
internal_domain=$(prompt_with_default "Enter internal domain name" "local.example.com" "${current_internal_domain}")
wild-config-set "cloud.internalDomain" "${internal_domain}"

# Prompt for load balancer IP
lb_ip=$(prompt_with_default "Enter load balancer IP address" "192.168.1.240" "${current_lb_ip}")
wild-config-set "cluster.loadBalancerIp" "${lb_ip}"

# Prompt for external DNS resolver
external_resolver=$(prompt_with_default "Enter external DNS resolver" "8.8.8.8" "${current_external_resolver}")
wild-config-set "cloud.dns.externalResolver" "${external_resolver}"

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled CoreDNS templates..."
if [ ! -d "${COREDNS_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

# Apply the k3s-compatible custom DNS override (k3s will preserve this)
echo "Applying CoreDNS custom override configuration..."
kubectl apply -f "${COREDNS_DIR}/kustomize/coredns-custom-config.yaml"

# Restart CoreDNS pods to apply the changes
echo "Restarting CoreDNS pods to apply changes..."
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system

echo "CoreDNS setup complete!"
echo
echo "To verify the installation:"
echo "  kubectl get pods -n kube-system"
echo "  kubectl get svc -n kube-system coredns"
echo "  kubectl describe svc -n kube-system coredns"
echo "  kubectl logs -n kube-system -l k8s-app=kube-dns -f"
