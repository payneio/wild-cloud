#!/bin/bash
set -e

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Source environment variables
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up Traefik service and middleware for k3s..."

cat ${SCRIPT_DIR}/traefik/traefik-service.yaml | envsubst | kubectl apply -f -
cat ${SCRIPT_DIR}/traefik/internal-middleware.yaml | envsubst | kubectl apply -f -

echo "Traefik setup complete!"
