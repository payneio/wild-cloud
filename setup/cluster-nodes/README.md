# Cluster Node Setup

This directory contains automation for setting up Talos Kubernetes cluster nodes with static IP configuration.

## Hardware Detection and Setup (Recommended)

The automated setup discovers hardware configuration from nodes in maintenance mode and generates machine configurations with the correct interface names and disk paths.

### Prerequisites

1. `source .env`
2. Boot nodes with Talos ISO in maintenance mode
3. Nodes must be accessible on the network

### Hardware Discovery Workflow

```bash
# ONE-TIME CLUSTER INITIALIZATION (run once per cluster)
./init-cluster.sh

# FOR EACH CONTROL PLANE NODE:

# 1. Boot node with Talos ISO (it will get a DHCP IP in maintenance mode)
# 2. Detect hardware and update config.yaml
./detect-node-hardware.sh <maintenance-ip> <node-number>

# Example: Node boots at 192.168.8.168, register as node 1
./detect-node-hardware.sh 192.168.8.168 1

# 3. Generate machine config for registered nodes
./generate-machine-configs.sh

# 4. Apply configuration - node will reboot with static IP
talosctl apply-config --insecure -n 192.168.8.168 --file final/controlplane-node-1.yaml

# 5. Wait for reboot, node should come up at its target static IP (192.168.8.31)

# Repeat steps 1-5 for additional control plane nodes
```

The `detect-node-hardware.sh` script will:

- Connect to nodes in maintenance mode via talosctl
- Discover active ethernet interfaces (e.g., `enp4s0` instead of hardcoded `eth0`)
- Discover available installation disks (>10GB)
- Update `config.yaml` with per-node hardware configuration
- Provide next steps for machine config generation

The `init-cluster.sh` script will:

- Generate Talos cluster secrets and base configurations (once per cluster)
- Set up talosctl context with cluster certificates
- Configure VIP endpoint for cluster communication

The `generate-machine-configs.sh` script will:

- Check which nodes have been hardware-detected
- Compile network configuration templates with discovered hardware settings
- Create final machine configurations for registered nodes only
- Include system extensions for Longhorn (iscsi-tools, util-linux-tools)
- Update talosctl context with registered node IPs

### Cluster Bootstrap

After all control plane nodes are configured with static IPs:

```bash
# Bootstrap the cluster using any control node
talosctl bootstrap --nodes 192.168.8.31 --endpoint 192.168.8.31


# Get kubeconfig
talosctl kubeconfig

# Verify cluster is ready
kubectl get nodes
```

## Complete Example

Here's a complete example of setting up a 3-node control plane:

```bash
# CLUSTER INITIALIZATION (once per cluster)
./init-cluster.sh

# NODE 1
# Boot node with Talos ISO, it gets DHCP IP 192.168.8.168
./detect-node-hardware.sh 192.168.8.168 1
./generate-machine-configs.sh
talosctl apply-config --insecure -n 192.168.8.168 --file final/controlplane-node-1.yaml
# Node reboots and comes up at 192.168.8.31

# NODE 2
# Boot second node with Talos ISO, it gets DHCP IP 192.168.8.169
./detect-node-hardware.sh 192.168.8.169 2
./generate-machine-configs.sh
talosctl apply-config --insecure -n 192.168.8.169 --file final/controlplane-node-2.yaml
# Node reboots and comes up at 192.168.8.32

# NODE 3
# Boot third node with Talos ISO, it gets DHCP IP 192.168.8.170
./detect-node-hardware.sh 192.168.8.170 3
./generate-machine-configs.sh
talosctl apply-config --insecure -n 192.168.8.170 --file final/controlplane-node-3.yaml
# Node reboots and comes up at 192.168.8.33

# CLUSTER BOOTSTRAP
talosctl bootstrap -n 192.168.8.30
talosctl kubeconfig
kubectl get nodes
```

## Configuration Details

### Per-Node Configuration

Each control plane node has its own configuration block in `config.yaml`:

```yaml
cluster:
  nodes:
    control:
      vip: 192.168.8.30
      node1:
        ip: 192.168.8.31
        interface: enp4s0 # Discovered automatically
        disk: /dev/sdb # Selected during hardware detection
      node2:
        ip: 192.168.8.32
        # interface and disk added after hardware detection
      node3:
        ip: 192.168.8.33
        # interface and disk added after hardware detection
```

Worker nodes use DHCP by default. You can use the same hardware detection process for worker nodes if static IPs are needed.

## Talosconfig Management

### Context Naming and Conflicts

When running `talosctl config merge ./generated/talosconfig`, if a context with the same name already exists, talosctl will create an enumerated version (e.g., `demo-cluster-2`).

**For a clean setup:**

- Delete existing contexts before merging: `talosctl config contexts` then `talosctl config context <name> --remove`
- Or use `--force` to overwrite: `talosctl config merge ./generated/talosconfig --force`

**Recommended approach for new clusters:**

```bash
# Remove old context if rebuilding cluster
talosctl config context demo-cluster --remove || true

# Merge new configuration
talosctl config merge ./generated/talosconfig
talosctl config endpoint 192.168.8.30
talosctl config node 192.168.8.31  # Add nodes as they are registered
```

### Context Configuration Timeline

1. **After first node hardware detection**: Merge talosconfig and set endpoint/first node
2. **After additional nodes**: Add them to the existing context with `talosctl config node <ip1> <ip2> <ip3>`
3. **Before cluster bootstrap**: Ensure all control plane nodes are in the node list

### System Extensions

All nodes include:

- `siderolabs/iscsi-tools`: Required for Longhorn storage
- `siderolabs/util-linux-tools`: Utility tools for storage operations

### Hardware Detection

The `detect-node-hardware.sh` script automatically discovers:

- **Network interfaces**: Finds active ethernet interfaces (no more hardcoded `eth0`)
- **Installation disks**: Lists available disks >10GB for interactive selection
- **Per-node settings**: Updates `config.yaml` with hardware-specific configuration

This eliminates the need to manually configure hardware settings and handles different hardware configurations across nodes.

### Template Structure

Configuration templates are stored in `patch.templates/` and use gomplate syntax:

- `controlplane-node-1.yaml`: Template for first control plane node
- `controlplane-node-2.yaml`: Template for second control plane node
- `controlplane-node-3.yaml`: Template for third control plane node
- `worker.yaml`: Template for worker nodes

Templates use per-node variables from `config.yaml`:

- `{{ .cluster.nodes.control.node1.ip }}`
- `{{ .cluster.nodes.control.node1.interface }}`
- `{{ .cluster.nodes.control.node1.disk }}`
- `{{ .cluster.nodes.control.vip }}`

The `wild-compile-template-dir` command processes all templates and outputs compiled configurations to the `patch/` directory.

## Troubleshooting

### Hardware Detection Issues

```bash
# Check if node is accessible in maintenance mode
talosctl -n <NODE_IP> version --insecure

# View available network interfaces
talosctl -n <NODE_IP> get links --insecure

# View available disks
talosctl -n <NODE_IP> get disks --insecure
```

### Manual Hardware Discovery

If the automatic detection fails, you can manually inspect hardware:

```bash
# Find active ethernet interfaces
talosctl -n <NODE_IP> get links --insecure -o json | jq -s '.[] | select(.spec.operationalState == "up" and .spec.type == "ether" and .metadata.id != "lo") | .metadata.id'

# Find suitable installation disks
talosctl -n <NODE_IP> get disks --insecure -o json | jq -s '.[] | select(.spec.size > 10000000000) | .metadata.id'
```

### Node Status

```bash
# View machine configuration (only works after config is applied)
talosctl -n <NODE_IP> get machineconfig
```
