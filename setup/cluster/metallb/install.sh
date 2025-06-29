#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
METALLB_DIR="${CLUSTER_SETUP_DIR}/metallb"

echo "Setting up MetalLB..."

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled MetalLB templates..."
if [ ! -d "${METALLB_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

echo "Deploying MetalLB..."
kubectl apply -k ${METALLB_DIR}/kustomize/installation

echo "Waiting for MetalLB to be deployed..."
kubectl wait --for=condition=Available deployment/controller -n metallb-system --timeout=60s
sleep 10 # Extra buffer for webhook initialization

echo "Customizing MetalLB..."
kubectl apply -k ${METALLB_DIR}/kustomize/configuration

echo "✅ MetalLB installed and configured"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl get ipaddresspools.metallb.io -n metallb-system"
