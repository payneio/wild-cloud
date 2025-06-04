# Talos

This is an alternate setup to using ks that uses talos and bare kubernetes. IN PROGRESS.

From https://www.talos.dev/v1.10/introduction/getting-started/

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install talosctl
curl -sL https://talos.dev/install | sh

# Generate cluster config files (and pki and tokens)
talosctl gen config test-cluster https://192.168.8.238:6443

talosctl -n 192.168.8.238 get disks --insecure
# Update disk in controlplane.yml

# Apply control plane config
talosctl apply-config --insecure --nodes 192.168.8.238 --file controlplane.yaml

# Bootstrap cluster on control plan
talosctl bootstrap --nodes 192.168.8.238 --endpoints 192.168.8.238 --talosconfig=./talosconfig

# Merge into kubeconfig
talosctl kubeconfig --nodes 192.168.8.238 --endpoints 192.168.8.238 --talosconfig=./talosconfig

```
