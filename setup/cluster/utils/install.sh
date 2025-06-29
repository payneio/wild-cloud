#!/bin/bash
set -e
set -o pipefail

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

source "${WC_ROOT}/bin/wild-common.sh"

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
UTILS_DIR="${CLUSTER_SETUP_DIR}/utils"

echo "Setting up cluster utilities..."

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled utils templates..."
if [ ! -d "${UTILS_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

echo "Applying utility manifests..."
kubectl apply -f ${UTILS_DIR}/kustomize/

echo "✅ Cluster utilities setup complete!"
