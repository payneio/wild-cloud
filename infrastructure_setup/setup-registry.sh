#!/bin/bash
set -e

# Navigate to script directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

echo "Setting up Docker Registry..."

# Apply the docker registry manifests using kustomize
kubectl apply -k "${SCRIPT_DIR}/docker-registry"

echo "Waiting for Docker Registry to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/docker-registry -n docker-registry

echo "Docker Registry setup complete!"

# Show deployment status
kubectl get pods -n docker-registry
kubectl get services -n docker-registry