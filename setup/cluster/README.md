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

- **[MetalLB](metallb/README.md)** - Provides load balancing for bare metal clusters
- **[Traefik](traefik/README.md)** - Handles ingress traffic, TLS termination, and routing
- **[cert-manager](cert-manager/README.md)** - Manages TLS certificates
- **[CoreDNS](coredns/README.md)** - Provides DNS resolution for services
- **[ExternalDNS](externaldns/README.md)** - Automatic DNS record management
- **[Longhorn](longhorn/README.md)** - Distributed storage system for persistent volumes
- **[NFS](nfs/README.md)** - Network file system for shared media storage (optional)
- **[Kubernetes Dashboard](kubernetes-dashboard/README.md)** - Web UI for cluster management (accessible via https://dashboard.internal.${DOMAIN})
- **[Docker Registry](docker-registry/README.md)** - Private container registry for custom images
- **[Utils](utils/README.md)** - Cluster utilities and debugging tools

## Idempotent Design

All setup scripts are designed to be idempotent:

- Scripts can be run multiple times without causing harm
- Each script checks for existing resources before creating new ones
- Configuration updates are applied cleanly without duplication
- Failed or interrupted setups can be safely retried
- Changes to configuration will be properly applied on subsequent runs

This idempotent approach ensures consistent, reliable infrastructure setup and allows for incremental changes without requiring a complete teardown and rebuild.
