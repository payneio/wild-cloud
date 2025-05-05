#!/bin/bash
set -e

# Store the script directory path for later use
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Source environment variables
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up Kubernetes Dashboard..."

NAMESPACE="kubernetes-dashboard"

# Apply the official dashboard installation 
echo "Installing Kubernetes Dashboard core components..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Copying cert-manager secrets to the dashboard namespace
copy-secret cert-manager:wildcard-internal-sovereign-cloud-tls $NAMESPACE
copy-secret cert-manager:wildcard-sovereign-cloud-tls $NAMESPACE

# Create admin service account and token
echo "Creating dashboard admin service account and token..."
cat "${SCRIPT_DIR}/kubernetes-dashboard/dashboard-admin-rbac.yaml" | kubectl apply -f -

# Apply the dashboard configuration
echo "Applying dashboard configuration..."
cat "${SCRIPT_DIR}/kubernetes-dashboard/dashboard-kube-system.yaml" | envsubst | kubectl apply -f -

# Restart CoreDNS to pick up the changes
kubectl delete pods -n kube-system -l k8s-app=kube-dns
echo "Restarted CoreDNS to pick up DNS changes"

# Wait for dashboard to be ready
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl rollout status deployment/kubernetes-dashboard -n $NAMESPACE --timeout=60s

echo "Kubernetes Dashboard setup complete!"
echo "Access the dashboard at: https://dashboard.internal.${DOMAIN}"
echo ""
echo "To get the authentication token, run:"
echo "./bin/dashboard-token"
