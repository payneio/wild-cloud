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

# Apply the custom config for the k3s-provided CoreDNS
echo "Applying CoreDNS configuration..."
echo "Looking for file: ${SCRIPT_DIR}/coredns/coredns-config.yaml"
# Simply use envsubst for variable expansion and apply
cat "${SCRIPT_DIR}/coredns/coredns-config.yaml" | envsubst | kubectl apply -f -

# Apply the split-horizon configuration
echo "Applying split-horizon DNS configuration..."
cat "${SCRIPT_DIR}/coredns/split-horizon.yaml" | envsubst | kubectl apply -f -

# Apply the LoadBalancer service for external access to CoreDNS
echo "Applying CoreDNS service configuration..."
cat "${SCRIPT_DIR}/coredns/coredns-service.yaml" | envsubst | kubectl apply -f -

# Restart CoreDNS pods to apply the changes
echo "Restarting CoreDNS pods to apply changes..."
kubectl delete pod -n kube-system -l k8s-app=kube-dns

echo "CoreDNS setup complete!"