#!/bin/bash
set -e

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Install gomplate
if command -v gomplate &> /dev/null; then
    echo "gomplate is already installed."
    exit 0
fi
curl -sSL https://github.com/hairyhenderson/gomplate/releases/latest/download/gomplate_linux-amd64 -o $HOME/.local/bin/gomplate
chmod +x $HOME/.local/bin/gomplate
echo "gomplate installed successfully."
