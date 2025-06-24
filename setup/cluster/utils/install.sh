#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
UTILS_DIR="${CLUSTER_SETUP_DIR}/utils"

echo "Setting up cluster utilities..."

# Process templates with wild-compile-template-dir
echo "Processing utils templates..."
wild-compile-template-dir --clean ${UTILS_DIR}/kustomize.template ${UTILS_DIR}/kustomize

echo "Applying utility manifests..."
kubectl apply -f ${UTILS_DIR}/kustomize/

echo "✅ Cluster utilities setup complete!"