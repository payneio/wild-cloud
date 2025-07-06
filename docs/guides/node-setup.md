# Node Setup Guide

This guide covers setting up Talos Linux nodes for your Kubernetes cluster using USB boot.

## Overview

There are two main approaches for booting Talos nodes:

1. **USB Boot** (covered here) - Boot from a custom USB drive with system extensions
2. **PXE Boot** - Network boot using dnsmasq setup (see `setup/dnsmasq/README.md`)

## USB Boot Setup

### Prerequisites

- Target hardware for Kubernetes nodes
- USB drive (8GB+ recommended)
- Admin access to create bootable USB drives

### Step 1: Upload Schematic and Download Custom Talos ISO

First, upload the system extensions schematic to Talos Image Factory, then download the custom ISO.

```bash
# Upload schematic configuration to get schematic ID
wild-talos-schema

# Download custom ISO with system extensions
wild-talos-iso
```

The custom ISO includes system extensions (iscsi-tools, util-linux-tools, intel-ucode, gvisor) needed for the cluster and is saved to `.wildcloud/iso/talos-v1.10.3-metal-amd64.iso`.

### Step 2: Create Bootable USB Drive

#### Linux (Recommended)

```bash
# Find your USB device (be careful to select the right device!)
lsblk
sudo dmesg | tail  # Check for recently connected USB devices

# Create bootable USB (replace /dev/sdX with your USB device)
sudo dd if=.wildcloud/iso/talos-v1.10.3-metal-amd64.iso of=/dev/sdX bs=4M status=progress sync

# Verify the write completed
sync
```

**⚠️ Warning**: Double-check the device path (`/dev/sdX`). Writing to the wrong device will destroy data!

#### macOS

```bash
# Find your USB device
diskutil list

# Unmount the USB drive (replace diskX with your USB device)
diskutil unmountDisk /dev/diskX

# Create bootable USB
sudo dd if=.wildcloud/iso/talos-v1.10.3-metal-amd64.iso of=/dev/rdiskX bs=4m

# Eject when complete
diskutil eject /dev/diskX
```

#### Windows

Use one of these tools:

1. **Rufus** (Recommended)

   - Download from https://rufus.ie/
   - Select the Talos ISO file
   - Choose your USB drive
   - Use "DD Image" mode
   - Click "START"

2. **Balena Etcher**

   - Download from https://www.balena.io/etcher/
   - Flash from file → Select Talos ISO
   - Select target USB drive
   - Flash!

3. **Command Line** (Windows 10/11)

   ```cmd
   # List disks to find USB drive number
   diskpart
   list disk
   exit

   # Write ISO (replace X with your USB disk number)
   dd if=.wildcloud\iso\talos-v1.10.3-metal-amd64.iso of=\\.\PhysicalDriveX bs=4M --progress
   ```

### Step 3: Boot Target Machine

1. **Insert USB** into target machine
2. **Boot from USB**:
   - Restart machine and enter BIOS/UEFI (usually F2, F12, DEL, or ESC during startup)
   - Change boot order to prioritize USB drive
   - Or use one-time boot menu (usually F12)
3. **Talos will boot** in maintenance mode with a DHCP IP

### Step 4: Hardware Detection and Configuration

Once the machine boots, it will be in maintenance mode with a DHCP IP address.

```bash
# Find the node's maintenance IP (check your router/DHCP server)
# Then detect hardware and register the node
cd setup/cluster-nodes
./detect-node-hardware.sh <maintenance-ip> <node-number>

# Example: Node got DHCP IP 192.168.8.150, registering as node 1
./detect-node-hardware.sh 192.168.8.150 1
```

This script will:

- Discover network interface names (e.g., `enp4s0`)
- List available disks for installation
- Update `config.yaml` with node-specific hardware settings

### Step 5: Generate and Apply Configuration

```bash
# Generate machine configurations with detected hardware
./generate-machine-configs.sh

# Apply configuration (node will reboot with static IP)
talosctl apply-config --insecure -n <maintenance-ip> --file final/controlplane-node-<number>.yaml

# Example:
talosctl apply-config --insecure -n 192.168.8.150 --file final/controlplane-node-1.yaml
```

### Step 6: Verify Installation

After reboot, the node should come up with its assigned static IP:

```bash
# Check connectivity (node 1 should be at 192.168.8.31)
ping 192.168.8.31

# Verify system extensions are installed
talosctl -e 192.168.8.31 -n 192.168.8.31 get extensions

# Check for iscsi tools
talosctl -e 192.168.8.31 -n 192.168.8.31 list /usr/local/bin/ | grep iscsi
```

## Repeat for Additional Nodes

For each additional control plane node:

1. Boot with the same USB drive
2. Run hardware detection with the new maintenance IP and node number
3. Generate and apply configurations
4. Verify the node comes up at its static IP

Example for node 2:

```bash
./detect-node-hardware.sh 192.168.8.151 2
./generate-machine-configs.sh
talosctl apply-config --insecure -n 192.168.8.151 --file final/controlplane-node-2.yaml
```

## Cluster Bootstrap

Once all control plane nodes are configured:

```bash
# Bootstrap the cluster using the VIP
talosctl bootstrap -n 192.168.8.30

# Get kubeconfig
talosctl kubeconfig

# Verify cluster
kubectl get nodes
```

## Troubleshooting

### USB Boot Issues

- **Machine won't boot from USB**: Check BIOS boot order, disable Secure Boot if needed
- **Talos doesn't start**: Verify ISO was written correctly, try re-creating USB
- **Network issues**: Ensure DHCP is available on your network

### Hardware Detection Issues

- **Node not accessible**: Check IP assignment, firewall settings
- **Wrong interface detected**: Manual override in `config.yaml` if needed
- **Disk not found**: Verify disk size (must be >10GB), check disk health

### Installation Issues

- **Static IP not assigned**: Check network configuration in machine config
- **Extensions not installed**: Verify ISO includes extensions, check upgrade logs
- **Node won't join cluster**: Check certificates, network connectivity to VIP

### Checking Logs

```bash
# View system logs
talosctl -e <node-ip> -n <node-ip> logs machined

# Check kernel messages
talosctl -e <node-ip> -n <node-ip> dmesg

# Monitor services
talosctl -e <node-ip> -n <node-ip> get services
```

## System Extensions Included

The custom ISO includes these extensions:

- **siderolabs/iscsi-tools**: iSCSI initiator tools for persistent storage
- **siderolabs/util-linux-tools**: Utility tools including fstrim for storage
- **siderolabs/intel-ucode**: Intel CPU microcode updates (harmless on AMD)
- **siderolabs/gvisor**: Container runtime sandbox (optional security enhancement)

These extensions enable:

- Longhorn distributed storage
- Improved security isolation
- CPU microcode updates
- Storage optimization tools

## Next Steps

After all nodes are configured:

1. **Install CNI**: Deploy a Container Network Interface (Cilium, Calico, etc.)
2. **Install CSI**: Deploy Container Storage Interface (Longhorn for persistent storage)
3. **Deploy workloads**: Your applications and services
4. **Monitor cluster**: Set up monitoring and logging

See the main project documentation for application deployment guides.
