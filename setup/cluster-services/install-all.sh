#!/bin/bash
set -e

# Navigate to script directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

echo "Setting up your wild-cloud cluster services..."
echo

./metallb/install.sh
./longhorn/install.sh
./traefik/install.sh
./coredns/install.sh
./cert-manager/install.sh
./externaldns/install.sh
./kubernetes-dashboard/install.sh
./nfs/install.sh
./docker-registry/install.sh

echo "Infrastructure setup complete!"
echo
echo "To verify components, run:"
echo "- kubectl get pods -n cert-manager"
echo "- kubectl get pods -n externaldns"
echo "- kubectl get pods -n kubernetes-dashboard"
echo "- kubectl get clusterissuers"
