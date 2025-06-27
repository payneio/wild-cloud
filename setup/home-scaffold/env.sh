#!/bin/bash

# Set the WC_HOME environment variable to this script's directory.
# This variable is used consistently across the Wild Config scripts.
export WC_HOME="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Add bin to path first so wild-config is available
export PATH="$WC_HOME/bin:$PATH"

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

KUBECONFIG=~/.kube/config
export KUBECONFIG

# Use cluster name as both talos and kubectl context name
CLUSTER_NAME=$(wild-config cluster.name)
if [ -z "${CLUSTER_NAME}" ] || [ "${CLUSTER_NAME}" = "null" ]; then
    echo "Error: cluster.name not set in config.yaml"
    exit 1
fi

# Only try to use the kubectl context if it exists
if kubectl config get-contexts "${CLUSTER_NAME}" >/dev/null 2>&1; then
    kubectl config use-context "${CLUSTER_NAME}"
    echo "Using Kubernetes context: ${CLUSTER_NAME}"
# else
#     echo "Kubernetes context '${CLUSTER_NAME}' not found, skipping context switch"
fi
