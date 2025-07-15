#!/bin/bash

# Set the WC_HOME environment variable to this script's directory.
# This variable is used consistently across the Wild Config scripts.
export WC_HOME="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Add bin to path first so wild-config is available
export PATH="$WC_HOME/bin:$PATH"

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl kubectl.sha256
    echo "kubectl installed successfully."
fi

# Install talosctl
if ! command -v talosctl &> /dev/null; then
    echo "Installing talosctl"
    curl -sL https://talos.dev/install | sh
    if [ $? -ne 0 ]; then
        echo "Error installing talosctl. Please check the installation script."
        exit 1
    fi
    echo "talosctl installed successfully."
fi

# Check if gomplate is installed
if ! command -v gomplate &> /dev/null; then
    echo "Installing gomplate"
    curl -sSL https://github.com/hairyhenderson/gomplate/releases/latest/download/gomplate_linux-amd64 -o $HOME/.local/bin/gomplate
    chmod +x $HOME/.local/bin/gomplate
    echo "gomplate installed successfully."
fi

# Install kustomize
if ! command -v kustomize &> /dev/null; then
    echo "Installing kustomize"
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    mv kustomize $HOME/.local/bin/
    echo "kustomize installed successfully."
fi

## Install yq
if ! command -v yq &> /dev/null; then
    echo "Installing yq"
    VERSION=v4.45.4
    BINARY=yq_linux_amd64
    wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - | tar xz
    mv ${BINARY} $HOME/.local/bin/yq
    chmod +x $HOME/.local/bin/yq
    rm yq.1
    echo "yq installed successfully."
fi

KUBECONFIG=~/.kube/config
export KUBECONFIG

# Use cluster name as both talos and kubectl context name
CLUSTER_NAME=$(wild-config cluster.name)
if [ -z "${CLUSTER_NAME}" ] || [ "${CLUSTER_NAME}" = "null" ]; then
    echo "Error: cluster.name not set in config.yaml"
else
    KUBE_CONTEXT="admin@${CLUSTER_NAME}"
    CURRENT_KUBE_CONTEXT=$(kubectl config current-context)
    if [ "${CURRENT_KUBE_CONTEXT}" != "${KUBE_CONTEXT}" ]; then
        if kubectl config get-contexts | grep -q "${KUBE_CONTEXT}"; then
            echo "Switching to kubernetes context ${KUBE_CONTEXT}"
        else
            echo "WARNING: Context ${KUBE_CONTEXT} does not exist."
            # kubectl config set-context "${KUBE_CONTEXT}" --cluster="${CLUSTER_NAME}" --user=admin
        fi
    fi
fi
