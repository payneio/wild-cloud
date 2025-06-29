#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
LONGHORN_DIR="${CLUSTER_SETUP_DIR}/longhorn"

echo "Setting up Longhorn..."

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled Longhorn templates..."
if [ ! -d "${LONGHORN_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

# Apply Longhorn with kustomize to apply our customizations
kubectl apply -k ${LONGHORN_DIR}/kustomize/

echo "Longhorn setup complete!"
