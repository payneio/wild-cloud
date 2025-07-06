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

wild-setup-scaffold
```

## Download Cluster Node Boot Assets

We use Talos linux for node operating systems. Run this script to download the OS for use in the rest of the setup.

```bash
# Generate node boot assets (PXE, iPXE, ISO)
wild-cluster-node-boot-assets-download
```

## Dnsmasq

- Install a Linux machine on your LAN. Record it's IP address in your `config:cloud.dns.ip`.
- Ensure it is accessible with ssh.

```bash
# Install dnsmasq with PXE boot support
wild-dnsmasq-install --install
```

## Cluster Setup

### Cluster Infrastructure Setup

```bash
# Configure network, cluster settings, and register nodes
wild-setup-cluster
```

This interactive script will:
- Configure network settings (router IP, DNS, DHCP range)
- Configure cluster settings (Talos version, schematic ID, MetalLB pool)
- Help you register control plane and worker nodes by detecting their hardware
- Generate machine configurations for each node
- Apply machine configurations to nodes
- Bootstrap the cluster after the first node.

### Install Cluster Services

```bash
wild-setup-services
```

## Installing Wild Cloud Apps

```bash
# List available applications
wild-apps-list

# Deploy an application
wild-app-deploy <app-name>

# Check app status
wild-app-doctor <app-name>

# Remove an application
wild-app-delete <app-name>
```

## Individual Node Management

If you need to manage individual nodes:

```bash
# Generate patch for a specific node
wild-cluster-node-patch-generate <node-ip>

# Generate final machine config (uses existing patch)
wild-cluster-node-machine-config-generate <node-ip>

# Apply configuration with options
wild-cluster-node-up <node-ip> [--insecure] [--skip-patch] [--dry-run]
```

## Asset Management

```bash
# Download/cache boot assets (kernel, initramfs, ISO, iPXE)
wild-cluster-node-boot-assets-download

# Install dnsmasq with specific schematic
wild-dnsmasq-install --schematic-id <id> --install
```
