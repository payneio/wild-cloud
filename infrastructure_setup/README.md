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
- **Kubernetes Dashboard** - Web UI for cluster management (accessible via https://dashboard.internal.${DOMAIN})

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
