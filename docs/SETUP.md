# Setting Up Your Wild Cloud

## Set up your personal cloud operations directory

- Create a directory somewhere. We recommend you use an Ubuntu machine.
- Inside it, run `wild-init`. This will scaffold your cloud directory.
- In your cloud directory, update `.wildcloud/config.yaml`. Use the same values in this dir in a `.env`

## Set up your Cloud Central

See [Central Setup](../central-setup/README.md).

## Set up Control Nodes

### 2. Install K3s (Lightweight Kubernetes)

See [Cluster Node Setup](../cluster-node-setup/README.md).

## Install Infrastructure Components

> Currently, these are set up to run from this directory. This will be moved to (1) a `bin/wild-generate-infrastructure-setup` script to copy them all to your personal cloud dir, (2) `wild-cli` (to do the same), or (3) `wild-central`, once I get my mind made up.

One command sets up your entire cloud infrastructure:

```bash
./infrastructure_setup/setup-all.sh
```

This installs and configures:

- **MetalLB**: Provides IP addresses for services
- **LongHorn**: Provides distributed block storage on the cluster
- **Traefik**: Handles ingress (routing) with automatic HTTPS
- **cert-manager**: Manages TLS certificates automatically
- **CoreDNS**: Provides internal DNS resolution
- **ExternalDNS**: Updates DNS records automatically
- **Kubernetes Dashboard**: Web UI for managing your cluster

## Next Steps

Now that your infrastructure is set up, you can:

1. **Deploy Applications**: See [Applications Guide](./APPS.md) for deploying services and applications
2. **Access Dashboard**: Visit `https://dashboard.internal.yourdomain.com` and use the token from `./bin/dashboard-token`
3. **Validate Setup**: Run `./infrastructure_setup/validate_setup.sh` to ensure everything is working

## Validation and Troubleshooting

Run the validation script to ensure everything is working correctly:

```bash
./infrastructure_setup/validate_setup.sh
```

This script checks:

- All infrastructure components
- DNS resolution
- Service connectivity
- Certificate issuance
- Network configuration

If issues are found, the script provides specific remediation steps.

## What's Next?

Now that your personal cloud is running, consider:

- Setting up backups with [Velero](https://velero.io/)
- Adding monitoring with Prometheus and Grafana
- Deploying applications like Nextcloud, Home Assistant, or Gitea
- Exploring the Kubernetes Dashboard to monitor your services

Welcome to your personal cloud journey! You now have the foundation for hosting your own services and taking control of your digital life.
