#!/bin/bash

# Talos custom installer image creation script
# This script generates installer image URLs using the centralized schematic ID

set -euo pipefail

# Check if WC_HOME is set
if [ -z "${WC_HOME:-}" ]; then
    echo "Error: WC_HOME environment variable not set. Run \`source ./env.sh\`."
    exit 1
fi

# Get Talos version and schematic ID from config
TALOS_VERSION=$(wild-config cluster.nodes.talos.version)
SCHEMATIC_ID=$(wild-config cluster.nodes.talos.schematicId)

echo "Creating custom Talos installer image..."
echo "Talos version: $TALOS_VERSION"

# Check if schematic ID exists
if [ -z "$SCHEMATIC_ID" ] || [ "$SCHEMATIC_ID" = "null" ]; then
    echo "Error: No schematic ID found in config.yaml"
    echo "Run 'wild-talos-schema' first to upload schematic and get ID"
    exit 1
fi

echo "Schematic ID: $SCHEMATIC_ID"
echo ""
echo "Schematic includes:"
yq eval '.cluster.nodes.talos.schematic.customization.systemExtensions.officialExtensions[]' "${WC_HOME}/config.yaml" | sed 's/^/  - /'
echo ""

# Generate installer image URL
INSTALLER_URL="factory.talos.dev/metal-installer/$SCHEMATIC_ID:$TALOS_VERSION"

echo ""
echo "🎉 Custom installer image URL generated!"
echo ""
echo "Installer URL: $INSTALLER_URL"
echo ""
echo "Usage in machine configuration:"
echo "machine:"
echo "  install:"
echo "    image: $INSTALLER_URL"
echo ""
echo "Next steps:"
echo "1. Update machine config templates with this installer URL"
echo "2. Regenerate machine configurations"
echo "3. Apply to existing nodes to trigger installation with extensions"
echo ""
echo "To update templates automatically, run:"
echo "  sed -i 's|image:.*|image: $INSTALLER_URL|' patch.templates/controlplane-node-*.yaml"