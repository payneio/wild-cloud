#!/bin/bash

# Node registration script for Talos cluster setup
# This script discovers hardware configuration from a node in maintenance mode
# and updates config.yaml with per-node hardware settings

set -euo pipefail

# Check if WC_HOME is set
if [ -z "${WC_HOME:-}" ]; then
    echo "Error: WC_HOME environment variable not set. Run \`source ./env.sh\`."
    exit 1
fi

# Usage function
usage() {
    echo "Usage: register-node.sh <node-ip> <node-number>"
    echo ""
    echo "Register a Talos node by discovering its hardware configuration."
    echo "The node must be booted in maintenance mode and accessible via IP."
    echo ""
    echo "Arguments:"
    echo "  node-ip       Current IP of the node in maintenance mode"
    echo "  node-number   Node number (1, 2, or 3) for control plane nodes"
    echo ""
    echo "Examples:"
    echo "  ./register-node.sh 192.168.8.168 1"
    echo "  ./register-node.sh 192.168.8.169 2"
    echo ""
    echo "This script will:"
    echo "  - Query the node for available network interfaces"
    echo "  - Query the node for available disks"
    echo "  - Update config.yaml with the per-node hardware settings"
    echo "  - Update patch templates to use per-node hardware"
}

# Parse arguments
if [ $# -ne 2 ]; then
    usage
    exit 1
fi

NODE_IP="$1"
NODE_NUMBER="$2"

# Validate node number
if [[ ! "$NODE_NUMBER" =~ ^[1-3]$ ]]; then
    echo "Error: Node number must be 1, 2, or 3"
    exit 1
fi

echo "Registering Talos control plane node $NODE_NUMBER at $NODE_IP..."

# Test connectivity
echo "Testing connectivity to node..."
if ! talosctl -n "$NODE_IP" get links --insecure >/dev/null 2>&1; then
    echo "Error: Cannot connect to node at $NODE_IP"
    echo "Make sure the node is booted in maintenance mode and accessible."
    exit 1
fi

echo "✅ Node is accessible"

# Discover network interfaces
echo "Discovering network interfaces..."

# First, try to find the interface that's actually carrying traffic (has the default route)
CONNECTED_INTERFACE=$(talosctl -n "$NODE_IP" get routes --insecure -o json 2>/dev/null | \
    jq -s -r '.[] | select(.spec.destination == "0.0.0.0/0" and .spec.gateway != null) | .spec.outLinkName' | \
    head -1)

if [ -n "$CONNECTED_INTERFACE" ]; then
    ACTIVE_INTERFACE="$CONNECTED_INTERFACE"
    echo "✅ Discovered connected interface (with default route): $ACTIVE_INTERFACE"
else
    # Fallback: find any active ethernet interface
    echo "No default route found, checking for active ethernet interfaces..."
    ACTIVE_INTERFACE=$(talosctl -n "$NODE_IP" get links --insecure -o json 2>/dev/null | \
        jq -s -r '.[] | select(.spec.operationalState == "up" and .spec.type == "ether" and .metadata.id != "lo") | .metadata.id' | \
        head -1)
    
    if [ -z "$ACTIVE_INTERFACE" ]; then
        echo "Error: No active ethernet interface found"
        echo "Available interfaces:"
        talosctl -n "$NODE_IP" get links --insecure
        echo ""
        echo "Available routes:"
        talosctl -n "$NODE_IP" get routes --insecure
        exit 1
    fi
    
    echo "✅ Discovered active interface: $ACTIVE_INTERFACE"
fi

# Discover available disks
echo "Discovering available disks..."
AVAILABLE_DISKS=$(talosctl -n "$NODE_IP" get disks --insecure -o json 2>/dev/null | \
    jq -s -r '.[] | select(.spec.size > 10000000000) | .metadata.id' | \
    head -5)

if [ -z "$AVAILABLE_DISKS" ]; then
    echo "Error: No suitable disks found (must be >10GB)"
    echo "Available disks:"
    talosctl -n "$NODE_IP" get disks --insecure
    exit 1
fi

echo "Available disks (>10GB):"
echo "$AVAILABLE_DISKS"
echo ""

# Let user choose disk
echo "Select installation disk for node $NODE_NUMBER:"
select INSTALL_DISK in $AVAILABLE_DISKS; do
    if [ -n "${INSTALL_DISK:-}" ]; then
        break
    fi
    echo "Invalid selection. Please try again."
done

# Add /dev/ prefix if not present
if [[ "$INSTALL_DISK" != /dev/* ]]; then
    INSTALL_DISK="/dev/$INSTALL_DISK"
fi

echo "✅ Selected disk: $INSTALL_DISK"

# Update config.yaml with per-node configuration
echo "Updating config.yaml with node $NODE_NUMBER configuration..."

CONFIG_FILE="${WC_HOME}/config.yaml"

# Get the target IP for this node from the existing config
TARGET_IP=$(yq eval ".cluster.nodes.control.node${NODE_NUMBER}.ip" "$CONFIG_FILE")

# Use yq to update the per-node configuration
yq eval ".cluster.nodes.control.node${NODE_NUMBER}.ip = \"$TARGET_IP\"" -i "$CONFIG_FILE"
yq eval ".cluster.nodes.control.node${NODE_NUMBER}.interface = \"$ACTIVE_INTERFACE\"" -i "$CONFIG_FILE"
yq eval ".cluster.nodes.control.node${NODE_NUMBER}.disk = \"$INSTALL_DISK\"" -i "$CONFIG_FILE"

echo "✅ Updated config.yaml for node $NODE_NUMBER:"
echo "  - Target IP: $TARGET_IP"
echo "  - Network interface: $ACTIVE_INTERFACE"  
echo "  - Installation disk: $INSTALL_DISK"


echo ""
echo "🎉 Node $NODE_NUMBER registration complete!"
echo ""
echo "Node configuration saved:"
echo "  - Target IP: $TARGET_IP"
echo "  - Interface: $ACTIVE_INTERFACE"
echo "  - Disk: $INSTALL_DISK"
echo ""
echo "Next steps:"
echo "1. Regenerate machine configurations:"
echo "   ./generate-machine-configs.sh"
echo ""
echo "2. Apply configuration to this node:"
echo "   talosctl apply-config --insecure -n $NODE_IP --file final/controlplane-node-${NODE_NUMBER}.yaml"
echo ""
echo "3. Wait for reboot and verify static IP connectivity"
echo "4. Repeat registration for additional control plane nodes"