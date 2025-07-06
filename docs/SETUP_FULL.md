# Wild Cloud Setup

## Hardware prerequisites

Procure the following before setup:

- Any machine for running setup and managing your cloud.
- One small machine for dnsmasq (running Ubuntu linux)
- Three machines for control nodes (2GB memory, 100GB hard drive).
- Any number of worker node machines.
- A network switch connecting all these machines to your router.
- A network router (e.g. Fluke 2) connected to the Internet.
- A domain of your choice registerd (or managed) on Cloudflare.

## Setup

Clone this repo (you probably already did this).

```bash
source env.sh
```

Initialize a personal wild-cloud in any empty directory, for example:

```bash
cd ~
mkdir ~/my-wild-cloud
cd my-wild-cloud

wild-init
```

## Dnsmasq

- Install a Linux machine on your LAN. Record it's IP address in your `config:cloud.dns.ip`.
- Ensure it is accessible with ssh.

```bash
wild-dnsmasq-install
```

## Cluster Setup

```bash
# ONE-TIME CLUSTER INITIALIZATION (run once per cluster)
./init-cluster.sh
```

### Join control nodes

Boot each nodes with Talos ISO in maintenance mode.

```bash
./detect-node-hardware.sh <maintenance-ip> <node-number>
./generate-machine-configs.sh
talosctl apply-config --insecure -n 192.168.8.168 --file final/controlplane-node-1.yaml
```

### Cluster bootstrap

After all control plane nodes are configured.

```bash
# Bootstrap the cluster using any control node
talosctl bootstrap --nodes 192.168.8.31 --endpoint 192.168.8.31

# Get kubeconfig
talosctl kubeconfig

# Verify cluster is ready
kubectl get nodes
```

### Cluster services

```bash
./setup/cluster/setup-all.sh
./setup/cluster/validate-setup.sh
```

## Installing Wild Cloud apps

```bash
wild-apps-list
wild-app-fetch <app>
wild-app-config <app>
wild-app-deploy <app>
# Optional: Check in app templates.
```
