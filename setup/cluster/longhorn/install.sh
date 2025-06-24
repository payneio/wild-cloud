#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
LONGHORN_DIR="${CLUSTER_SETUP_DIR}/longhorn"

echo "Setting up Longhorn..."

# Process templates with wild-compile-template-dir
echo "Processing Longhorn templates..."
wild-compile-template-dir --clean ${LONGHORN_DIR}/kustomize.template ${LONGHORN_DIR}/kustomize

# Apply Longhorn with kustomize to apply our customizations
kubectl apply -k ${LONGHORN_DIR}/kustomize/

echo "Longhorn setup complete!"
