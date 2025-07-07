#!/bin/bash
set -e
set -o pipefail

# Initialize Wild Cloud environment
if [ -z "${WC_ROOT}" ]; then
    print "WC_ROOT is not set."
    exit 1
else
    source "${WC_ROOT}/scripts/common.sh"
    init_wild_env
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster-services"
EXTERNALDNS_DIR="${CLUSTER_SETUP_DIR}/externaldns"

print_header "Setting up ExternalDNS"

# Collect required configuration variables
print_info "Collecting ExternalDNS configuration..."

# Prompt for configuration using helper functions
prompt_if_unset_config "cluster.externalDns.ownerId" "Enter ExternalDNS owner ID (unique identifier for this cluster)" "wild-cloud-$(hostname -s)"

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
