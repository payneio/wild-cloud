# Wild-cloud Setup

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

## Cloud configuration

```bash
cp config.example.yaml config.yaml
cp secrets.example.yaml secrets.yaml
```

```md
Core Variables:

- wildcloud.root - Used by wild-config wildcloud.root command
- cluster.name - Cluster name

DNS/Network Variables:

- cloud.dns.ip - DNS server IP for dnsmasq
- cloud.domain - Main public domain
- cloud.internalDomain - Internal/private domain
- cloud.dhcpRange - DHCP range for dnsmasq
- cloud.router.ip - Gateway/router IP
- cloud.dnsmasq.interface - Network interface for dnsmasq
- cloud.dns.externalResolver - External DNS resolver

Cluster Variables:

- cluster.loadBalancerIp - Load balancer IP for services
- cluster.ipAddressPool - MetalLB IP address pool
- cluster.nodes.control.vip - Virtual IP for control plane
- cluster.nodes.control.node1/2/3.ip - Control plane node IPs
- cluster.nodes.control.node1/2/3.interface - Network interfaces
- cluster.nodes.control.node1/2/3.disk - Installation disks
- cluster.nodes.talos.version - Talos version
- cluster.nodes.talos.schematicId - Talos schematic ID

Certificate/DNS Variables:

- operator.email - Email for Let's Encrypt certificates
- cluster.certManager.cloudflare.domain - Domain for Cloudflare DNS challenge
- cluster.externalDns.ownerId - Unique identifier for ExternalDNS

Storage Variables:

- cloud.nfs.host - NFS server host
- cloud.nfs.mediaPath - NFS media path
- cloud.nfs.storageCapacity - Storage capacity for NFS PV

Registry Variables:

- cloud.dockerRegistryHost - Docker registry hostname
```

Copy setup files.

```bash
wild-setup
```

## Dnsmasq

- Install a Linux machine on your LAN. Record it's IP address in your `config:cloud.dns.ip`.
- Ensure it is accessible with ssh.
- From your wild-cloud directory, run `wild-central-generate-setup`.
- Run `cluster/dnsmasq/bin/create-setup-bundle.sh`
- Run `cluster/dnsmasq/bin/transfer-setup-bundle.sh`

Now ssh into your dnsmasq machine and do the following:

```bash
sudo -i
cd /root/dnsmasq-setup
./setup.sh
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

## Installing Wild-Cloud apps

```bash
wild-apps-list
wild-app-fetch <app>
wild-app-config <app>
wild-app-deploy <app>
# Optional: Check in app templates.
```
