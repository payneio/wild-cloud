#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
DOCKER_REGISTRY_DIR="${CLUSTER_SETUP_DIR}/docker-registry"

echo "Setting up Docker Registry..."

# Process templates with wild-compile-template-dir
echo "Processing Docker Registry templates..."
wild-compile-template-dir --clean ${DOCKER_REGISTRY_DIR}/kustomize.template ${DOCKER_REGISTRY_DIR}/kustomize

# Apply the docker registry manifests using kustomize
kubectl apply -k "${DOCKER_REGISTRY_DIR}/kustomize"

echo "Waiting for Docker Registry to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/docker-registry -n docker-registry

echo "Docker Registry setup complete!"

# Show deployment status
kubectl get pods -n docker-registry
kubectl get services -n docker-registry