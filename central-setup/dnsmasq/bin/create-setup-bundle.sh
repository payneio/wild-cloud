#!/bin/bash

# Set up 

# Initialize wildcloud environment.

if [ ! -d ".wildcloud" ]; then
    echo "Error: You must run this script from a wild-cloud directory"
    exit 1
fi

WILDCLOUD_CONFIG_FILE="./config.yaml"
if [ ! -f ${WILDCLOUD_CONFIG_FILE} ]; then
    echo "Error: ${WILDCLOUD_CONFIG_FILE} not found"
    exit 1
fi


WILDCLOUD_ROOT=$(yq eval '.wildcloud.root' ${WILDCLOUD_CONFIG_FILE})
if [ -z "${WILDCLOUD_ROOT}" ] || [ "${WILDCLOUD_ROOT}" = "null" ]; then
    echo "Error: wildcloud.root not found in ${WILDCLOUD_CONFIG_FILE}"
    exit 1
fi

# ---

DNSMASQ_SETUP_DIR="./cluster/dnsmasq"
BUNDLE_DIR="${DNSMASQ_SETUP_DIR}/setup-bundle"
mkdir -p "${BUNDLE_DIR}"


# Copy iPXE bootloader to ipxe-web.
echo "Copying Talos kernel and initramfs for PXE boot..."
PXE_WEB_ROOT="${BUNDLE_DIR}/ipxe-web"
mkdir -p "${PXE_WEB_ROOT}/amd64"
cp "${DNSMASQ_SETUP_DIR}/boot.ipxe" "${PXE_WEB_ROOT}/boot.ipxe"

# Create Talos bare metal boot assets.
# This uses the Talos factory API to create boot assets for bare metal nodes.
# These assets include the kernel and initramfs needed for PXE booting Talos on bare metal.
echo "Creating Talos bare metal boot assets..."
TALOS_ID=$(curl -X POST --data-binary @${DNSMASQ_SETUP_DIR}/bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')
if [ -z "${TALOS_ID}" ] || [ "${TALOS_ID}" = "null" ]; then
    echo "Error: Failed to create Talos bare metal boot assets"
    exit 1
fi
echo "Successfully created Talos bare metal boot assets with ID: ${TALOS_ID}"

# Download kernel to ipxe-web if it's not already there.
TALOS_VERSION=$(wild-config .cluster.nodes.talos.version) || exit 1
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
