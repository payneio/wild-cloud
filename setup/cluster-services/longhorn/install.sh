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

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster-services"
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
