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
COREDNS_DIR="${CLUSTER_SETUP_DIR}/coredns"

print_header "Setting up CoreDNS for k3s"

# Collect required configuration variables
print_info "Collecting CoreDNS configuration..."

# Prompt for configuration using helper functions
prompt_if_unset_config "cloud.internalDomain" "Enter internal domain name" "local.example.com"
prompt_if_unset_config "cluster.loadBalancerIp" "Enter load balancer IP address" "192.168.1.240"
prompt_if_unset_config "cloud.dns.externalResolver" "Enter external DNS resolver" "8.8.8.8"

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
