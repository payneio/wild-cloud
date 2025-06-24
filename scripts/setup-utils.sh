#!/bin/bash
set -e

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Install gomplate
if command -v gomplate &> /dev/null; then
    echo "gomplate is already installed."
else
    curl -sSL https://github.com/hairyhenderson/gomplate/releases/latest/download/gomplate_linux-amd64 -o $HOME/.local/bin/gomplate
    chmod +x $HOME/.local/bin/gomplate
    echo "gomplate installed successfully."
fi

# Install kustomize
if command -v kustomize &> /dev/null; then
    echo "kustomize is already installed."
else
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    mv kustomize $HOME/.local/bin/
    echo "kustomize installed successfully."
fi

## Install yq
if command -v yq &> /dev/null; then
    echo "yq is already installed."
else
    VERSION=v4.45.4
    BINARY=yq_linux_amd64
    wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - | tar xz
    mv ${BINARY} $HOME/.local/bin/yq
    chmod +x $HOME/.local/bin/yq
    rm yq.1
    echo "yq installed successfully."
fi
