#!/bin/bash
set -e

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Source environment variables
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up MetalLB..."

echo "Deploying MetalLB..."
# cat ${SCRIPT_DIR}/metallb/metallb-helm-config.yaml | envsubst | kubectl apply -f -
kubectl apply -k metallb/installation

echo "Waiting for MetalLB to be deployed..."
kubectl wait --for=condition=Available deployment/controller -n metallb-system --timeout=60s
sleep 10 # Extra buffer for webhook initialization

echo "Customizing MetalLB..."
kubectl apply -k metallb/configuration

echo "✅ MetalLB installed and configured"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl get ipaddresspools.metallb.io -n metallb-system"
