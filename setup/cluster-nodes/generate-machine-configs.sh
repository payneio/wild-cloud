#!/bin/bash

# Talos machine configuration generation script
# This script generates machine configs for registered nodes using existing cluster secrets

set -euo pipefail

# Check if WC_HOME is set
if [ -z "${WC_HOME:-}" ]; then
    echo "Error: WC_HOME environment variable not set. Run \`source ./env.sh\`."
    exit 1
fi

NODE_SETUP_DIR="${WC_HOME}/setup/cluster-nodes"

# Check if cluster has been initialized
if [ ! -f "${NODE_SETUP_DIR}/generated/secrets.yaml" ]; then
    echo "Error: Cluster not initialized. Run ./init-cluster.sh first."
    exit 1
fi

# Get cluster configuration from config.yaml
CLUSTER_NAME=$(wild-config cluster.name)
VIP=$(wild-config cluster.nodes.control.vip)

echo "Generating machine configurations for cluster: $CLUSTER_NAME"

# Check which nodes have been registered (have hardware config)
REGISTERED_NODES=()
for i in 1 2 3; do
    if yq eval ".cluster.nodes.control.node${i}.interface" "${WC_HOME}/config.yaml" | grep -v "null" >/dev/null 2>&1; then
        NODE_IP=$(wild-config cluster.nodes.control.node${i}.ip)
        REGISTERED_NODES+=("$NODE_IP")
        echo "✅ Node $i registered: $NODE_IP"
    else
        echo "⏸️  Node $i not registered yet"
    fi
done

if [ ${#REGISTERED_NODES[@]} -eq 0 ]; then
    echo ""
    echo "No nodes have been registered yet."
    echo "Run ./detect-node-hardware.sh <maintenance-ip> <node-number> first."
    exit 1
fi

# Create directories
mkdir -p "${NODE_SETUP_DIR}/final" "${NODE_SETUP_DIR}/patch"

# Compile patch templates for registered nodes only
echo "Compiling patch templates..."

for i in 1 2 3; do
    if yq eval ".cluster.nodes.control.node${i}.interface" "${WC_HOME}/config.yaml" | grep -v "null" >/dev/null 2>&1; then
        echo "Compiling template for control plane node $i..."
        cat "${NODE_SETUP_DIR}/patch.templates/controlplane-node-${i}.yaml" | wild-compile-template > "${NODE_SETUP_DIR}/patch/controlplane-node-${i}.yaml"
    fi
done

# Always compile worker template (doesn't require hardware detection)
if [ -f "${NODE_SETUP_DIR}/patch.templates/worker.yaml" ]; then
    cat "${NODE_SETUP_DIR}/patch.templates/worker.yaml" | wild-compile-template > "${NODE_SETUP_DIR}/patch/worker.yaml"
fi

# Generate final machine configs for registered nodes only
echo "Generating final machine configurations..."
for i in 1 2 3; do
    if yq eval ".cluster.nodes.control.node${i}.interface" "${WC_HOME}/config.yaml" | grep -v "null" >/dev/null 2>&1; then
        echo "Generating config for control plane node $i..."
        talosctl machineconfig patch "${NODE_SETUP_DIR}/generated/controlplane.yaml" --patch @"${NODE_SETUP_DIR}/patch/controlplane-node-${i}.yaml" -o "${NODE_SETUP_DIR}/final/controlplane-node-${i}.yaml"
    fi
done

# Always generate worker config (doesn't require hardware detection)
if [ -f "${NODE_SETUP_DIR}/patch/worker.yaml" ]; then
    echo "Generating worker config..."
    talosctl machineconfig patch "${NODE_SETUP_DIR}/generated/worker.yaml" --patch @"${NODE_SETUP_DIR}/patch/worker.yaml" -o "${NODE_SETUP_DIR}/final/worker.yaml"
fi

# Update talosctl context with registered nodes
echo "Updating talosctl context..."
if [ ${#REGISTERED_NODES[@]} -gt 0 ]; then
    talosctl config node "${REGISTERED_NODES[@]}"
fi

echo ""
echo "✅ Machine configurations generated successfully!"
echo ""
echo "Generated configs:"
for i in 1 2 3; do
    if [ -f "${NODE_SETUP_DIR}/final/controlplane-node-${i}.yaml" ]; then
        NODE_IP=$(wild-config cluster.nodes.control.node${i}.ip)
        echo "  - ${NODE_SETUP_DIR}/final/controlplane-node-${i}.yaml (target IP: $NODE_IP)"
    fi
done
if [ -f "${NODE_SETUP_DIR}/final/worker.yaml" ]; then
    echo "  - ${NODE_SETUP_DIR}/final/worker.yaml"
fi
echo ""
echo "Current talosctl configuration:"
talosctl config info
echo ""
echo "Next steps:"
echo "1. Apply configurations to nodes in maintenance mode:"
for i in 1 2 3; do
    if [ -f "${NODE_SETUP_DIR}/final/controlplane-node-${i}.yaml" ]; then
        echo "   talosctl apply-config --insecure -n <maintenance-ip> --file ${NODE_SETUP_DIR}/final/controlplane-node-${i}.yaml"
    fi
done
echo ""
echo "2. Wait for nodes to reboot with static IPs, then bootstrap cluster with ANY control node:"
echo "   talosctl bootstrap --nodes 192.168.8.31 --endpoint 192.168.8.31"
echo ""
echo "3. Get kubeconfig:"
echo "   talosctl kubeconfig"
