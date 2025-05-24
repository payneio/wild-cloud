#!/bin/bash
set -e

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up Longhorn..."

# Apply Longhorn with kustomize to apply our customizations
kubectl apply -k ${SCRIPT_DIR}/longhorn/

echo "Longhorn setup complete!"
