#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
EXTERNALDNS_DIR="${CLUSTER_SETUP_DIR}/externaldns"

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
