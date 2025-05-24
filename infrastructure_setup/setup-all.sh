#!/bin/bash
set -e

# Navigate to script directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

echo "Setting up infrastructure components for k3s..."

# Make all script files executable
chmod +x *.sh

# Utils
./setup-utils.sh

# Setup MetalLB (must be first for IP allocation)
./setup-metallb.sh

# Setup Longhorn
./setup-longhorn.sh

# Setup Traefik
./setup-traefik.sh

# Setup CoreDNS
./setup-coredns.sh

# Setup cert-manager
./setup-cert-manager.sh

# Setup ExternalDNS
./setup-externaldns.sh

# Setup Kubernetes Dashboard
./setup-dashboard.sh

# Setup Docker Registry
./setup-registry.sh
kubectl apply -k docker-registry

echo "Infrastructure setup complete!"
echo
echo "Next steps:"
echo "1. Install Helm charts for non-infrastructure components"
echo "2. Access the dashboard at: https://dashboard.internal.${DOMAIN}"
echo "3. Get the dashboard token with: ./bin/dashboard-token"
echo
echo "To verify components, run:"
echo "- kubectl get pods -n cert-manager"
echo "- kubectl get pods -n externaldns"
echo "- kubectl get pods -n kubernetes-dashboard"
echo "- kubectl get clusterissuers"