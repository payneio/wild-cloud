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
EXTERNALDNS_DIR="${CLUSTER_SETUP_DIR}/externaldns"

print_header "Setting up ExternalDNS"

# Collect required configuration variables
print_info "Collecting ExternalDNS configuration..."

# Get current value
current_owner_id=$(get_current_config "cluster.externalDns.ownerId")

# Prompt for ExternalDNS owner ID
owner_id=$(prompt_with_default "Enter ExternalDNS owner ID (unique identifier for this cluster)" "wild-cloud-$(hostname -s)" "${current_owner_id}")
wild-config-set "cluster.externalDns.ownerId" "${owner_id}"

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled ExternalDNS templates..."
if [ ! -d "${EXTERNALDNS_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

echo "Setting up ExternalDNS..."

# Apply ExternalDNS manifests using kustomize
echo "Deploying ExternalDNS..."
kubectl apply -k ${EXTERNALDNS_DIR}/kustomize

# Setup Cloudflare API token secret
echo "Creating Cloudflare API token secret..."
CLOUDFLARE_API_TOKEN=$(wild-secret cloudflare.token) || exit 1
kubectl create secret generic cloudflare-api-token \
  --namespace externaldns \
  --from-literal=api-token="${CLOUDFLARE_API_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Wait for ExternalDNS to be ready
echo "Waiting for Cloudflare ExternalDNS to be ready..."
kubectl rollout status deployment/external-dns -n externaldns --timeout=60s

# echo "Waiting for CoreDNS ExternalDNS to be ready..."
# kubectl rollout status deployment/external-dns-coredns -n externaldns --timeout=60s

echo "ExternalDNS setup complete!"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n externaldns"
echo "  kubectl logs -n externaldns -l app=external-dns -f"
echo "  kubectl logs -n externaldns -l app=external-dns-coredns -f"
