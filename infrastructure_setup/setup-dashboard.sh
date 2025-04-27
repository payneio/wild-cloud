#!/bin/bash
set -e

# Store the script directory path for later use
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
cd "$SCRIPT_DIR"

# Source environment variables
if [[ -f "../load-env.sh" ]]; then
  source ../load-env.sh
fi

echo "Setting up Kubernetes Dashboard..."

# Apply the official dashboard installation 
echo "Installing Kubernetes Dashboard core components..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin service account and token
cat << EOF | kubectl apply -f -
---
# Service Account and RBAC
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
subjects:
  - kind: ServiceAccount
    name: dashboard-admin
    namespace: kubernetes-dashboard
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---
# Token for dashboard-admin
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-admin-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: dashboard-admin
type: kubernetes.io/service-account-token
EOF

# Clean up any existing IngressRoute resources that might conflict
echo "Cleaning up any existing dashboard resources to prevent conflicts..."
# Clean up all IngressRoutes related to dashboard in both namespaces
kubectl delete ingressroute -n kubernetes-dashboard --all --ignore-not-found
kubectl delete ingressroute -n kube-system kubernetes-dashboard --ignore-not-found
kubectl delete ingressroute -n kube-system kubernetes-dashboard-alt --ignore-not-found
kubectl delete ingressroute -n kube-system kubernetes-dashboard-http --ignore-not-found
kubectl delete ingressroute -n kube-system kubernetes-dashboard-alt-http --ignore-not-found

# Clean up middleware in both namespaces
kubectl delete middleware -n kubernetes-dashboard --all --ignore-not-found
kubectl delete middleware -n kube-system dashboard-internal-only --ignore-not-found
kubectl delete middleware -n kube-system dashboard-redirect-scheme --ignore-not-found

# Clean up ServersTransport in both namespaces
kubectl delete serverstransport -n kubernetes-dashboard dashboard-transport --ignore-not-found
kubectl delete serverstransport -n kube-system dashboard-transport --ignore-not-found

# Apply the dashboard configuration
echo "Applying dashboard configuration in kube-system namespace..."
# Use just the kube-system version since it works better with Traefik
cat "${SCRIPT_DIR}/kubernetes-dashboard/dashboard-kube-system.yaml" | envsubst | kubectl apply -f -

# No need to manually update the CoreDNS ConfigMap anymore
# The setup-coredns.sh script now handles variable substitution correctly

# Restart CoreDNS to pick up the changes
kubectl delete pods -n kube-system -l k8s-app=kube-dns
echo "Restarted CoreDNS to pick up DNS changes"

# Wait for dashboard to be ready
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard --timeout=60s

echo "Kubernetes Dashboard setup complete!"
echo "Access the dashboard at: https://dashboard.internal.${DOMAIN}"
echo ""
echo "To get the authentication token, run:"
echo "./bin/dashboard-token"
