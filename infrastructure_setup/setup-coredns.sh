#!/bin/bash
set -e

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Source environment variables
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up CoreDNS for k3s..."
echo "Script directory: ${SCRIPT_DIR}"
echo "Current directory: $(pwd)"

# Apply the k3s-compatible custom DNS override (k3s will preserve this)
echo "Applying CoreDNS custom override configuration..."
cat "${SCRIPT_DIR}/coredns/coredns-custom-config.yaml" | envsubst | kubectl apply -f -

# Apply the LoadBalancer service for external access to CoreDNS
echo "Applying CoreDNS service configuration..."
cat "${SCRIPT_DIR}/coredns/coredns-lb-service.yaml" | envsubst | kubectl apply -f -

# Restart CoreDNS pods to apply the changes
echo "Restarting CoreDNS pods to apply changes..."
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system

echo "CoreDNS setup complete!"
