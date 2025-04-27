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

# TODO: Remove the helm config in preference to a native config.

echo "Deploying MetalLB..."
cat ${SCRIPT_DIR}/metallb/metallb-helm-config.yaml | envsubst | kubectl apply -f -

echo "Waiting for MetalLB to be deployed..."
kubectl wait --for=condition=complete job -l helm.sh/chart=metallb -n kube-system --timeout=120s || echo "Warning: Timeout waiting for MetalLB Helm job"

echo "Waiting for MetalLB controller to be ready..."
kubectl get namespace metallb-system &>/dev/null || (echo "Waiting for metallb-system namespace to be created..." && sleep 30)
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/instance=metallb -n metallb-system --timeout=60s || echo "Warning: Timeout waiting for controller deployment"

echo "Configuring MetalLB IP address pool..."
kubectl get namespace metallb-system &>/dev/null && \
kubectl apply -f "${SCRIPT_DIR}/metallb/metallb-pool.yaml" || \
echo "Warning: metallb-system namespace not ready yet. Pool configuration will be skipped. Run this script again in a few minutes."

echo "✅ MetalLB installed and configured"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl get ipaddresspools.metallb.io -n metallb-system"
