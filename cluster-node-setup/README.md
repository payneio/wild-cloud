# Cluster Node Setup

Cluster node setup is WIP. Any kubernetes setup will do. Currently, we have a working cluster using each of these methods and are moving towards Talos.

## k3s cluster node setup

K3s provides a fully-compliant Kubernetes distribution in a small footprint.

To set up control nodes:

```bash
# Install K3s without the default load balancer (we'll use MetalLB)
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644 --disable servicelb --disable metallb

# Set up kubectl configuration
mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config
```

Set up the infrastructure services after these are running, then you can add more worker nodes with:

```bash
# On your master node, get the node token
NODE_TOKEN=`sudo cat /var/lib/rancher/k3s/server/node-token`
MASTER_IP=192.168.8.222
# On each new node, join the cluster

curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$NODE_TOKEN sh -
```

## Talos cluster node setup

This is a new experimental method for setting up cluster nodes. We're currently working through the simplest bootstrapping experience.

Currently, though, all these steps are manual.

Copy this entire directory to your personal cloud folder and modify it as necessary as you install. We suggest putting it in `cluster/bootstrap`.

```bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install talosctl
curl -sL https://talos.dev/install | sh

# In your LAN Router (which is your DHCP server),

CLUSTER_NAME=test-cluster
VIP=192.168.8.20 # Non-DHCP

# Boot your nodes with the ISO and put their IP addresses here. Pin in DHCP.
# Nodes must all be on the same switch.
# TODO: How to set these static on boot?
CONTROL_NODE_1=192.168.8.21
CONTROL_NODE_2=192.168.8.22
CONTROL_NODE_3=192.168.8.23

# Generate cluster config files (including pki and tokens)
cd generated
talosctl gen secrets -o secrets.yaml
talosctl gen config --with-secrets secrets.yaml $CLUSTER_NAME https://$VIP:6443
talosctl config merge ./talosconfig
cd ..

# If the disk you want to install Talos on isn't /dev/sda, you should
# update to the disk you want in patch/controlplane.yml and patch/worker.yaml. If you have already attempted to install a node and received an error about not being able to find /dev/sda, you can see what disks are available on it with:
#
# talosctl -n $VIP get disks --insecure

# See https://www.talos.dev/v1.10/talos-guides/configuration/patching/
talosctl machineconfig patch generated/controlplane.yaml --patch @patch/controlplane.yaml -o final/controlplane.yaml
talosctl machineconfig patch generated/worker.yaml --patch @patch/worker.yaml -o final/worker.yaml
$

# Apply control plane config
talosctl apply-config --insecure -n $CONTROL_NODE_1,$CONTROL_NODE_2,$CONTROL_NODE_3 --file final/controlplane.yaml

# Bootstrap cluster on control plan
talosctl bootstrap -n $VIP

# Merge new cluster information into kubeconfig
talosctl kubeconfig

# You are now ready to use both `talosctl` and `kubectl` against your new cluster.
```
