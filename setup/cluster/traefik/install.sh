#!/bin/bash
set -e
set -o pipefail

# Source common utilities
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../bin/wild-common.sh"

# Initialize Wild-Cloud environment
init_wild_env

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
TRAEFIK_DIR="${CLUSTER_SETUP_DIR}/traefik"

print_header "Setting up Traefik ingress controller"

# Collect required configuration variables
print_info "Collecting Traefik configuration..."

# Get current value
current_lb_ip=$(get_current_config "cluster.loadBalancerIp")

# Prompt for load balancer IP
lb_ip=$(prompt_with_default "Enter load balancer IP address for Traefik" "192.168.1.240" "${current_lb_ip}")
wild-config-set "cluster.loadBalancerIp" "${lb_ip}"

print_success "Configuration collected successfully"

# Install required CRDs first
echo "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

echo "Installing Traefik CRDs..."
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

echo "Waiting for CRDs to be established..."
kubectl wait --for condition=established crd/gateways.gateway.networking.k8s.io --timeout=60s
kubectl wait --for condition=established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s
kubectl wait --for condition=established crd/ingressroutes.traefik.io --timeout=60s
kubectl wait --for condition=established crd/middlewares.traefik.io --timeout=60s

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled Traefik templates..."
if [ ! -d "${TRAEFIK_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

# Apply Traefik using kustomize
echo "Deploying Traefik..."
kubectl apply -k ${TRAEFIK_DIR}/kustomize

# Wait for Traefik to be ready
echo "Waiting for Traefik to be ready..."
kubectl wait --for=condition=Available deployment/traefik -n traefik --timeout=120s


echo "✅ Traefik setup complete!"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n traefik"
echo "  kubectl get svc -n traefik"
