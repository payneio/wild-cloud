#!/bin/bash
set -e
set -o pipefail

# Initialize Wild Cloud environment
if [ -z "${WC_ROOT}" ]; then
    print "WC_ROOT is not set."
    exit 1
else
    source "${WC_ROOT}/scripts/common.sh"
    init_wild_env
fi

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
