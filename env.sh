#!/bin/bash

# Set the WC_HOME environment variable to this script's directory.
# This variable is used consistently across the Wild Config scripts.
export WC_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Add bin to path first so wild-config is available
export PATH="$WC_ROOT/bin:$PATH"

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Installing."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

# Install talosctl
if ! command -v talosctl &> /dev/null; then
    echo "Error: talosctl is not installed. Installing."
    curl -sL https://talos.dev/install | sh
fi


# Check if gomplate is installed
if ! command -v gomplate &> /dev/null; then
    echo "Error: gomplate is not installed. Please install gomplate first."
    echo "Visit: https://docs.gomplate.ca/installing/"
    exit 1
fi

echo "Wild Cloud root ready."
