#!/bin/bash
set -e
set -o pipefail

# Initialize Wild Cloud environment
if [ -z "${WC_ROOT}" ]; then
    print "WC_ROOT is not set."
    exit 1
else
    source "${WC_ROOT}/scripts/common.sh"
    init_wild_env
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
KUBERNETES_DASHBOARD_DIR="${CLUSTER_SETUP_DIR}/kubernetes-dashboard"

print_header "Setting up Kubernetes Dashboard"

# Collect required configuration variables
print_info "Collecting Kubernetes Dashboard configuration..."

# Prompt for configuration using helper functions
prompt_if_unset_config "cloud.internalDomain" "Enter internal domain name (for dashboard URL)" "local.example.com"

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled Dashboard templates..."
if [ ! -d "${KUBERNETES_DASHBOARD_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

NAMESPACE="kubernetes-dashboard"

# Apply the official dashboard installation 
echo "Installing Kubernetes Dashboard core components..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Wait for cert-manager certificates to be ready
echo "Waiting for cert-manager certificates to be ready..."
kubectl wait --for=condition=Ready certificate wildcard-internal-wild-cloud -n cert-manager --timeout=300s || echo "Warning: Internal wildcard certificate not ready yet"
kubectl wait --for=condition=Ready certificate wildcard-wild-cloud -n cert-manager --timeout=300s || echo "Warning: Wildcard certificate not ready yet"

# Copying cert-manager secrets to the dashboard namespace (if available)
echo "Copying cert-manager secrets to dashboard namespace..."
if kubectl get secret wildcard-internal-wild-cloud-tls -n cert-manager >/dev/null 2>&1; then
    copy-secret cert-manager:wildcard-internal-wild-cloud-tls $NAMESPACE
else
    echo "Warning: wildcard-internal-wild-cloud-tls secret not yet available"
fi

if kubectl get secret wildcard-wild-cloud-tls -n cert-manager >/dev/null 2>&1; then
    copy-secret cert-manager:wildcard-wild-cloud-tls $NAMESPACE
else
    echo "Warning: wildcard-wild-cloud-tls secret not yet available"
fi

# Apply dashboard customizations using kustomize
echo "Applying dashboard customizations..."
kubectl apply -k "${KUBERNETES_DASHBOARD_DIR}/kustomize"

# Restart CoreDNS to pick up the changes
kubectl delete pods -n kube-system -l k8s-app=kube-dns
echo "Restarted CoreDNS to pick up DNS changes"

# Wait for dashboard to be ready
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl rollout status deployment/kubernetes-dashboard -n $NAMESPACE --timeout=60s

echo "Kubernetes Dashboard setup complete!"
INTERNAL_DOMAIN=$(wild-config cloud.internalDomain) || exit 1
echo "Access the dashboard at: https://dashboard.${INTERNAL_DOMAIN}"
echo ""
echo "To get the authentication token, run:"
echo "wild-dashboard-token"
