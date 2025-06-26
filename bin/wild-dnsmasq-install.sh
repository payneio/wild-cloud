#!/bin/bash

# Check if WC_HOME is set
if [ -z "${WC_HOME:-}" ]; then
    echo "Error: WC_HOME environment variable not set. Run \`source ./env.sh\`."
    exit 1
fi

WILDCLOUD_ROOT=$(wild-config wildcloud.root) || exit 1

# ---

SOURCE_DIR="${WILDCLOUD_ROOT}/setup/dnsmasq"
DNSMASQ_SETUP_DIR="${WC_HOME}/setup/dnsmasq"
BUNDLE_DIR="${DNSMASQ_SETUP_DIR}/setup-bundle"
mkdir -p "${BUNDLE_DIR}"


# Create local templates.

if [ -d "${DNSMASQ_SETUP_DIR}" ]; then
    echo "Warning: ${DNSMASQ_SETUP_DIR}/dnsmasq already exists"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping dnsmasq setup"
    else
        rm -rf "${DNSMASQ_SETUP_DIR}"
        cp -r "${SOURCE_DIR}" "${DNSMASQ_SETUP_DIR}"
        find "${DNSMASQ_SETUP_DIR}" -type f \( -name "*.yaml" -o -name "*.ipxe" -o -name "*.conf" \) | while read -r file; do
            echo "Processing: ${file}"
            wild-compile-template < "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
        done
        echo "Successfully created dnsmasq setup files from templates."
    fi
else
    cp -r "${SOURCE_DIR}" "${DNSMASQ_SETUP_DIR}"
    find "${DNSMASQ_SETUP_DIR}" -type f \( -name "*.yaml" -o -name "*.ipxe" -o -name "*.conf" \) | while read -r file; do
        echo "Processing: ${file}"
        wild-compile-template < "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
    done
    echo "Successfully created dnsmasq setup files from templates."
fi

# Create setup bundle.

# Copy iPXE bootloader to ipxe-web.
echo "Copying Talos kernel and initramfs for PXE boot..."
PXE_WEB_ROOT="${BUNDLE_DIR}/ipxe-web"
mkdir -p "${PXE_WEB_ROOT}/amd64"
cp "${DNSMASQ_SETUP_DIR}/boot.ipxe" "${PXE_WEB_ROOT}/boot.ipxe"

# Get Talos schematic ID from centralized config.
# The schematic should be uploaded via wild-talos-schema first.
echo "Getting Talos schematic ID from config..."
TALOS_ID=$(wild-config cluster.nodes.talos.schematicId)
if [ -z "${TALOS_ID}" ] || [ "${TALOS_ID}" = "null" ]; then
    echo "Error: No schematic ID found in config.yaml"
    echo "Run 'wild-talos-schema' first to upload schematic and get ID"
    exit 1
fi
echo "Using Talos schematic ID: ${TALOS_ID}"

# Verify schematic includes expected extensions
echo "Schematic includes:"
yq eval '.cluster.nodes.talos.schematic.customization.systemExtensions.officialExtensions[]' ./config.yaml | sed 's/^/  - /'

# Download kernel to ipxe-web if it's not already there.
TALOS_VERSION=$(wild-config cluster.nodes.talos.version) || exit 1
if [ ! -f "${PXE_WEB_ROOT}/amd64/vmlinuz" ]; then
    echo "Downloading Talos kernel..."
    wget -O "${PXE_WEB_ROOT}/amd64/vmlinuz" "https://pxe.factory.talos.dev/image/${TALOS_ID}/${TALOS_VERSION}/kernel-amd64"
else
    echo "Talos kernel already exists, skipping download"
fi

# Download initramfs to ipxe-web if it's not already there.
if [ ! -f "${PXE_WEB_ROOT}/amd64/initramfs.xz" ]; then
    echo "Downloading Talos initramfs..."
    wget -O "${PXE_WEB_ROOT}/amd64/initramfs.xz" "https://pxe.factory.talos.dev/image/${TALOS_ID}/${TALOS_VERSION}/initramfs-amd64.xz"
else
    echo "Talos initramfs already exists, skipping download"
fi

# Update PXE's iPXE bootloader files.
# TODO: Put download to cache first.
echo "Updating iPXE ftpd bootloader files."
FTPD_DIR="${BUNDLE_DIR}/pxe-ftpd"
mkdir -p $FTPD_DIR
wget http://boot.ipxe.org/ipxe.efi -O ${FTPD_DIR}/ipxe.efi
wget http://boot.ipxe.org/undionly.kpxe -O ${FTPD_DIR}/undionly.kpxe
wget http://boot.ipxe.org/arm64-efi/ipxe.efi -O ${FTPD_DIR}/ipxe-arm64.efi


cp "${DNSMASQ_SETUP_DIR}/nginx.conf" "${BUNDLE_DIR}/nginx.conf"
cp "${DNSMASQ_SETUP_DIR}/dnsmasq.conf" "${BUNDLE_DIR}/dnsmasq.conf"
cp "${DNSMASQ_SETUP_DIR}/bin/setup.sh" "${BUNDLE_DIR}/setup.sh"

# Copy setup bundle to DNSMasq server.
# This is the server that will run DNSMasq and serve PXE boot files.

SERVER_HOST=$(wild-config cloud.dns.ip) || exit 1
SETUP_DIR="${WC_HOME}/setup/dnsmasq/setup-bundle"
DESTINATION_DIR="~/dnsmasq-setup"

echo "Copying DNSMasq setup files to ${SERVER_HOST}:${DESTINATION_DIR}..."
scp -r ${SETUP_DIR}/* root@${SERVER_HOST}:${DESTINATION_DIR}

# Run setup script on the DNSMasq server.
echo "Running setup script on ${SERVER_HOST}..."
ssh root@${SERVER_HOST} "bash -s" < "${SETUP_DIR}/setup.sh" || {
    echo "Error: Failed to run setup script on ${SERVER_HOST}"
    exit 1
}