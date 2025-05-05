#!/bin/bash
set -e

# Navigate to script directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Source environment variables
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up cert-manager..."

# Create cert-manager namespace
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Install cert-manager using the official installation method 
# This installs CRDs, controllers, and webhook components
echo "Installing cert-manager components..."
# Using stable URL for cert-manager installation
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml || \
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n cert-manager --timeout=120s
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s

# Add delay to allow webhook to be fully ready
echo "Waiting additional time for cert-manager webhook to be fully operational..."
sleep 30

# Setup Cloudflare API token for DNS01 challenges
if [[ -n "${CLOUDFLARE_API_TOKEN}" ]]; then
  echo "Creating Cloudflare API token secret in cert-manager namespace..."
  kubectl create secret generic cloudflare-api-token \
    --namespace cert-manager \
    --from-literal=api-token="${CLOUDFLARE_API_TOKEN}" \
    --dry-run=client -o yaml | kubectl apply -f -  
else
  echo "Warning: CLOUDFLARE_API_TOKEN not set. DNS01 challenges will not work."
fi

echo "Creating Let's Encrypt issuers..."
cat ${SCRIPT_DIR}/cert-manager/letsencrypt-staging-dns01.yaml | envsubst | kubectl apply -f -
cat ${SCRIPT_DIR}/cert-manager/letsencrypt-prod-dns01.yaml | envsubst | kubectl apply -f -

# Wait for issuers to be ready
echo "Waiting for Let's Encrypt issuers to be ready..."
sleep 10

# Apply wildcard certificates
echo "Creating wildcard certificates..."
cat ${SCRIPT_DIR}/cert-manager/internal-wildcard-certificate.yaml | envsubst | kubectl apply -f -
cat ${SCRIPT_DIR}/cert-manager/wildcard-certificate.yaml | envsubst | kubectl apply -f -
echo "Wildcard certificate creation initiated. This may take some time to complete depending on DNS propagation."

# Wait for the certificates to be issued (with a timeout)
echo "Waiting for wildcard certificates to be ready (this may take several minutes)..."
kubectl wait --for=condition=Ready certificate wildcard-internal-sovereign-cloud -n cert-manager --timeout=300s || true
kubectl wait --for=condition=Ready certificate wildcard-sovereign-cloud -n cert-manager --timeout=300s || true

echo "cert-manager setup complete!"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n cert-manager"
echo "  kubectl get clusterissuers"
