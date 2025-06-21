# Infrastructure setup scripts

Creates a fully functional personal cloud infrastructure on a bare metal Kubernetes (k3s) cluster that provides:

1. **External access** to services via configured domain names (using ${DOMAIN})
2. **Internal-only access** to admin interfaces (via internal.${DOMAIN} subdomains)
3. **Secure traffic routing** with automatic TLS
4. **Reliable networking** with proper load balancing

## Architecture

```
Internet → External DNS → MetalLB LoadBalancer → Traefik → Kubernetes Services
                                    ↑
                                 Internal DNS
                                    ↑
                              Internal Network
```

## Key Components

- **MetalLB** - Provides load balancing for bare metal clusters
- **Traefik** - Handles ingress traffic, TLS termination, and routing
- **cert-manager** - Manages TLS certificates
- **CoreDNS** - Provides DNS resolution for services
- **Longhorn** - Distributed storage system for persistent volumes
- **NFS** - Network file system for shared media storage (optional)
- **Kubernetes Dashboard** - Web UI for cluster management (accessible via https://dashboard.internal.${DOMAIN})
- **Docker Registry** - Private container registry for custom images

## Configuration Approach

All infrastructure components use a consistent configuration approach:

1. **Environment Variables** - All configuration settings are managed using environment variables loaded by running `source load-env.sh`
2. **Template Files** - Configuration files use templates with `${VARIABLE}` syntax
3. **Setup Scripts** - Each component has a dedicated script in `infrastructure_setup/` for installation and configuration

## Idempotent Design

All setup scripts are designed to be idempotent:

- Scripts can be run multiple times without causing harm
- Each script checks for existing resources before creating new ones
- Configuration updates are applied cleanly without duplication
- Failed or interrupted setups can be safely retried
- Changes to configuration will be properly applied on subsequent runs

This idempotent approach ensures consistent, reliable infrastructure setup and allows for incremental changes without requiring a complete teardown and rebuild.

## NFS Setup (Optional)

The infrastructure supports optional NFS (Network File System) for shared media storage across the cluster:

### Host Setup

First, set up the NFS server on your chosen host:

```bash
# Set required environment variables
export NFS_HOST=box-01                    # Hostname or IP of NFS server
export NFS_MEDIA_PATH=/data/media         # Path to media directory
export NFS_STORAGE_CAPACITY=1Ti          # Optional: PV size (default: 250Gi)

# Run host setup script on the NFS server
./infrastructure_setup/setup-nfs-host.sh
```

### Cluster Integration

Then integrate NFS with your Kubernetes cluster:

```bash
# Run cluster setup (part of setup-all.sh or standalone)
./infrastructure_setup/setup-nfs.sh
```

### Features

- **Automatic IP detection** - Uses network IP even when hostname resolves to localhost
- **Cluster-wide access** - Any pod can mount the NFS share regardless of node placement
- **Configurable capacity** - Set PersistentVolume size via `NFS_STORAGE_CAPACITY`
- **ReadWriteMany** - Multiple pods can simultaneously access the same storage

### Usage

Applications can use NFS storage by setting `storageClassName: nfs` in their PVCs:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 100Gi
```
