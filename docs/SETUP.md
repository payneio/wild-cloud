# Setting Up Your Personal Cloud

Welcome to your journey toward digital independence! This guide will walk you through setting up your own personal cloud infrastructure using Kubernetes, providing you with privacy, control, and flexibility.

## Hardware Recommendations

For a pleasant experience, we recommend:

- A dedicated mini PC, NUC, or old laptop with at least:
  - 4 CPU cores
  - 8GB RAM (16GB recommended)
  - 128GB SSD (256GB or more recommended)
- A stable internet connection
- Optional: additional nodes for high availability

## Initial Setup

### 1. Prepare Environment Variables

First, create your environment configuration:

```bash
# Copy the example file and edit with your details
cp .env.example .env
nano .env

# Then load the environment variables
source load-env.sh
```

Important variables to set in your `.env` file:

- `DOMAIN`: Your domain name (e.g., `cloud.example.com`)
- `EMAIL`: Your email for Let's Encrypt certificates
- `CLOUDFLARE_API_TOKEN`: If using Cloudflare for DNS

### 2. Install K3s (Lightweight Kubernetes)

K3s provides a fully-compliant Kubernetes distribution in a small footprint:

```bash
# Install K3s without the default load balancer (we'll use MetalLB)
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644 --disable servicelb

# Set up kubectl configuration
mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config
```

### 3. Install Infrastructure Components

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

## Adding Additional Nodes (Optional)

For larger workloads or high availability, you can add more nodes:

```bash
# On your master node, get the node token
sudo cat /var/lib/rancher/k3s/server/node-token

# On each new node, join the cluster
curl -sfL https://get.k3s.io | K3S_URL=https://MASTER_IP:6443 K3S_TOKEN=NODE_TOKEN sh -
```

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
