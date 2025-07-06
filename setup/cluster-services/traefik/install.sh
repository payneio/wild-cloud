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
TRAEFIK_DIR="${CLUSTER_SETUP_DIR}/traefik"

print_header "Setting up Traefik ingress controller"

# Collect required configuration variables
print_info "Collecting Traefik configuration..."

# Prompt for configuration using helper functions
prompt_if_unset_config "cluster.loadBalancerIp" "Enter load balancer IP address for Traefik" "192.168.1.240"

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
