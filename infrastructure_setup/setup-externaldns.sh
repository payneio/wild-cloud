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

echo "Setting up ExternalDNS..."

# Create externaldns namespace
kubectl create namespace externaldns --dry-run=client -o yaml | kubectl apply -f -

# Setup Cloudflare API token secret for ExternalDNS
if [[ -n "${CLOUDFLARE_API_TOKEN}" ]]; then
  echo "Creating Cloudflare API token secret..."
  kubectl create secret generic cloudflare-api-token \
    --namespace externaldns \
    --from-literal=api-token="${CLOUDFLARE_API_TOKEN}" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "Error: CLOUDFLARE_API_TOKEN not set. ExternalDNS will not work correctly."
  exit 1
fi

# Apply ExternalDNS manifests with environment variables
echo "Deploying ExternalDNS..."
cat ${SCRIPT_DIR}/externaldns/externaldns.yaml | envsubst | kubectl apply -f -

# Wait for ExternalDNS to be ready
echo "Waiting for ExternalDNS to be ready..."
kubectl rollout status deployment/external-dns -n externaldns --timeout=60s

# Deploy test services if --test flag is provided
if [[ "$1" == "--test" ]]; then
  echo "Deploying test services to verify ExternalDNS..."
  cat ${SCRIPT_DIR}/externaldns/test-service.yaml | envsubst | kubectl apply -f -
  cat ${SCRIPT_DIR}/externaldns/test-cname-service.yaml | envsubst | kubectl apply -f -
  
  echo "Test services deployed at:"
  echo "- test.${DOMAIN}"
  echo "- test-cname.${DOMAIN} (CNAME record)"
  echo "DNS records should be automatically created in Cloudflare within a few minutes."
fi

echo "ExternalDNS setup complete!"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n externaldns"
echo "  kubectl logs -n externaldns -l app=external-dns -f"