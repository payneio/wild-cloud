# Maintenance Guide

This guide covers essential maintenance tasks for your personal cloud infrastructure, including troubleshooting, backups, updates, and security best practices.

## Troubleshooting

### General Troubleshooting Steps

1. **Check Component Status**:
   ```bash
   # Check all pods across all namespaces
   kubectl get pods -A
   
   # Look for pods that aren't Running or Ready
   kubectl get pods -A | grep -v "Running\|Completed"
   ```

2. **View Detailed Pod Information**:
   ```bash
   # Get detailed info about problematic pods
   kubectl describe pod <pod-name> -n <namespace>
   
   # Check pod logs
   kubectl logs <pod-name> -n <namespace>
   ```

3. **Run Validation Script**:
   ```bash
   ./infrastructure_setup/validate_setup.sh
   ```

4. **Check Node Status**:
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

### Common Issues

#### Certificate Problems

If services show invalid certificates:

1. Check certificate status:
   ```bash
   kubectl get certificates -A
   ```

2. Examine certificate details:
   ```bash
   kubectl describe certificate <cert-name> -n <namespace>
   ```

3. Check for cert-manager issues:
   ```bash
   kubectl get pods -n cert-manager
   kubectl logs -l app=cert-manager -n cert-manager
   ```

4. Verify the Cloudflare API token is correctly set up:
   ```bash
   kubectl get secret cloudflare-api-token -n internal
   ```

#### DNS Issues

If DNS resolution isn't working properly:

1. Check CoreDNS status:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   kubectl logs -l k8s-app=kube-dns -n kube-system
   ```

2. Verify CoreDNS configuration:
   ```bash
   kubectl get configmap -n kube-system coredns -o yaml
   ```

3. Test DNS resolution from inside the cluster:
   ```bash
   kubectl run -i --tty --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
   ```

#### Service Connectivity

If services can't communicate:

1. Check network policies:
   ```bash
   kubectl get networkpolicies -A
   ```

2. Verify service endpoints:
   ```bash
   kubectl get endpoints -n <namespace>
   ```

3. Test connectivity from within the cluster:
   ```bash
   kubectl run -i --tty --rm debug --image=busybox --restart=Never -- wget -O- <service-name>.<namespace>
   ```

## Backup and Restore

### What to Back Up

1. **Persistent Data**:
   - Database volumes
   - Application storage
   - Configuration files

2. **Kubernetes Resources**:
   - Custom Resource Definitions (CRDs)
   - Deployments, Services, Ingresses
   - Secrets and ConfigMaps

### Backup Methods

#### Simple Backup Script

Create a backup script at `bin/backup.sh` (to be implemented):

```bash
#!/bin/bash
# Simple backup script for your personal cloud
# This is a placeholder for future implementation

BACKUP_DIR="/path/to/backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

# Back up Kubernetes resources
kubectl get all -A -o yaml > "$BACKUP_DIR/all-resources.yaml"
kubectl get secrets -A -o yaml > "$BACKUP_DIR/secrets.yaml"
kubectl get configmaps -A -o yaml > "$BACKUP_DIR/configmaps.yaml"

# Back up persistent volumes
# TODO: Add logic to back up persistent volume data

echo "Backup completed: $BACKUP_DIR"
```

#### Using Velero (Recommended for Future)

[Velero](https://velero.io/) is a powerful backup solution for Kubernetes:

```bash
# Install Velero (future implementation)
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero --namespace velero --create-namespace

# Create a backup
velero backup create my-backup --include-namespaces default,internal

# Restore from backup
velero restore create --from-backup my-backup
```

### Database Backups

For database services, set up regular dumps:

```bash
# PostgreSQL backup (placeholder)
kubectl exec <postgres-pod> -n <namespace> -- pg_dump -U <username> <database> > backup.sql

# MariaDB/MySQL backup (placeholder)
kubectl exec <mariadb-pod> -n <namespace> -- mysqldump -u root -p<password> <database> > backup.sql
```

## Updates

### Updating Kubernetes (K3s)

1. Check current version:
   ```bash
   k3s --version
   ```

2. Update K3s:
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```

3. Verify the update:
   ```bash
   k3s --version
   kubectl get nodes
   ```

### Updating Infrastructure Components

1. Update the repository:
   ```bash
   git pull
   ```

2. Re-run the setup script:
   ```bash
   ./infrastructure_setup/setup-all.sh
   ```

3. Or update specific components:
   ```bash
   ./infrastructure_setup/setup-cert-manager.sh
   ./infrastructure_setup/setup-dashboard.sh
   # etc.
   ```

### Updating Applications

For Helm chart applications:

```bash
# Update Helm repositories
helm repo update

# Upgrade a specific application
./bin/helm-install <chart-name> --upgrade
```

For services deployed with `deploy-service`:

```bash
# Edit the service YAML
nano services/<service-name>/service.yaml

# Apply changes
kubectl apply -f services/<service-name>/service.yaml
```

## Security

### Best Practices

1. **Keep Everything Updated**:
   - Regularly update K3s
   - Update all infrastructure components
   - Keep application images up to date

2. **Network Security**:
   - Use internal services whenever possible
   - Limit exposed services to only what's necessary
   - Configure your home router's firewall properly

3. **Access Control**:
   - Use strong passwords for all services
   - Implement a secrets management strategy
   - Rotate API tokens and keys regularly

4. **Regular Audits**:
   - Review running services periodically
   - Check for unused or outdated deployments
   - Monitor resource usage for anomalies

### Security Scanning (Future Implementation)

Tools to consider implementing:

1. **Trivy** for image scanning:
   ```bash
   # Example Trivy usage (placeholder)
   trivy image <your-image>
   ```

2. **kube-bench** for Kubernetes security checks:
   ```bash
   # Example kube-bench usage (placeholder)
   kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml
   ```

3. **Falco** for runtime security monitoring:
   ```bash
   # Example Falco installation (placeholder)
   helm repo add falcosecurity https://falcosecurity.github.io/charts
   helm install falco falcosecurity/falco --namespace falco --create-namespace
   ```

## System Health Monitoring

### Basic Monitoring

Check system health with:

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -A

# Persistent volume claims
kubectl get pvc -A
```

### Advanced Monitoring (Future Implementation)

Consider implementing:

1. **Prometheus + Grafana** for comprehensive monitoring:
   ```bash
   # Placeholder for future implementation
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
   ```

2. **Loki** for log aggregation:
   ```bash
   # Placeholder for future implementation
   helm repo add grafana https://grafana.github.io/helm-charts
   helm install loki grafana/loki-stack --namespace logging --create-namespace
   ```

## Additional Resources

This document will be expanded in the future with:

- Detailed backup and restore procedures
- Monitoring setup instructions
- Comprehensive security hardening guide
- Automated maintenance scripts

For now, refer to the following external resources:

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)
- [Velero Backup Documentation](https://velero.io/docs/latest/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)