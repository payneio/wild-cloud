# Deploying Applications

Once you have your personal cloud infrastructure up and running, you'll want to start deploying applications. This guide explains how to deploy and manage applications on your infrastructure.

## Application Charts

The `/charts` directory contains curated Helm charts for common applications that are ready to deploy on your personal cloud.

### Available Charts

| Chart | Description | Internal/Public |
|-------|-------------|----------------|
| mariadb | MariaDB database for applications | Internal |
| postgres | PostgreSQL database for applications | Internal |

### Installing Charts

Use the `bin/helm-install` script to easily deploy charts with the right configuration:

```bash
# Install PostgreSQL
./bin/helm-install postgres

# Install MariaDB
./bin/helm-install mariadb
```

The script automatically:
- Uses values from your environment variables
- Creates the necessary namespace
- Configures storage and networking
- Sets up appropriate secrets

### Customizing Chart Values

Each chart can be customized by:

1. Editing environment variables in your `.env` file
2. Creating a custom values file:

```bash
# Create a custom values file
cp charts/postgres/values.yaml my-postgres-values.yaml
nano my-postgres-values.yaml

# Install with custom values
./bin/helm-install postgres --values my-postgres-values.yaml
```

### Creating Your Own Charts

You can add your own applications to the charts directory:

1. Create a new directory: `mkdir -p charts/my-application`
2. Add the necessary templates and values
3. Document any required environment variables

## Deploying Custom Services

For simpler applications or services without existing charts, use the `deploy-service` script to quickly deploy from templates.

### Service Types

The system supports four types of services:

1. **Public** - Accessible from the internet
2. **Internal** - Only accessible within your local network
3. **Database** - Internal database services
4. **Microservice** - Services that are only accessible by other services

### Deployment Examples

```bash
# Deploy a public blog using Ghost
./bin/deploy-service --type public --name blog --image ghost:4.12 --port 2368

# Deploy an internal admin dashboard
./bin/deploy-service --type internal --name admin --image my-admin:v1 --port 8080

# Deploy a database service
./bin/deploy-service --type database --name postgres --image postgres:15 --port 5432

# Deploy a microservice
./bin/deploy-service --type microservice --name auth --image auth-service:v1 --port 9000
```

### Service Structure

When you deploy a service, a directory is created at `services/[service-name]/` containing:

- `service.yaml` - The Kubernetes manifest for your service

You can modify this file directly and reapply it with `kubectl apply -f services/[service-name]/service.yaml` to update your service.

## Accessing Services

Services are automatically configured with proper URLs and TLS certificates.

### URL Patterns

- **Public services**: `https://[service-name].[domain]`
- **Internal services**: `https://[service-name].internal.[domain]`
- **Microservices**: `https://[service-name].svc.[domain]`
- **Databases**: `[service-name].[namespace].svc.cluster.local:[port]`

### Dashboard Access

Access the Kubernetes Dashboard at `https://dashboard.internal.[domain]`:

```bash
# Get the dashboard token
./bin/dashboard-token
```

### Service Management

Monitor your running services with:

```bash
# List all services
kubectl get services -A

# View detailed information about a service
kubectl describe service [service-name] -n [namespace]

# Check pods for a service
kubectl get pods -n [namespace] -l app=[service-name]

# View logs for a service
kubectl logs -n [namespace] -l app=[service-name]
```

## Advanced Configuration

### Scaling Services

Scale your services by editing the deployment:

```bash
kubectl scale deployment [service-name] --replicas=3 -n [namespace]
```

### Adding Environment Variables

Add environment variables to your service by editing the service YAML file and adding entries to the `env` section:

```yaml
env:
- name: DATABASE_URL
  value: "postgres://user:password@postgres:5432/db"
```

### Persistent Storage

For services that need persistent storage, add a PersistentVolumeClaim to your service YAML.

## Troubleshooting

If a service isn't working correctly:

1. Check pod status: `kubectl get pods -n [namespace]`
2. View logs: `kubectl logs [pod-name] -n [namespace]`
3. Describe the pod: `kubectl describe pod [pod-name] -n [namespace]`
4. Verify the service: `kubectl get svc [service-name] -n [namespace]`
5. Check the ingress: `kubectl get ingress [service-name] -n [namespace]`