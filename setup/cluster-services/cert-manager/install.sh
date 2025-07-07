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

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster-services"
CERT_MANAGER_DIR="${CLUSTER_SETUP_DIR}/cert-manager"

print_header "Setting up cert-manager"

# Collect required configuration variables
print_info "Collecting cert-manager configuration..."

# Prompt for configuration using helper functions
prompt_if_unset_config "cloud.domain" "Enter main domain name" "example.com"

# Get the domain value to use as default for internal domain
domain=$(wild-config "cloud.domain")
prompt_if_unset_config "cloud.internalDomain" "Enter internal domain name" "local.${domain}"
prompt_if_unset_config "operator.email" "Enter operator email address (for Let's Encrypt)" ""
prompt_if_unset_config "cluster.certManager.cloudflare.domain" "Enter Cloudflare domain (for DNS challenges)" "${domain}"
prompt_if_unset_secret "cloudflare.token" "Enter Cloudflare API token (for DNS challenges)" ""

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled cert-manager templates..."
if [ ! -d "${CERT_MANAGER_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

echo "Setting up cert-manager..."

# Install cert-manager using the official installation method 
# This installs CRDs, controllers, and webhook components
echo "Installing cert-manager components..."
# Using stable URL for cert-manager installation
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml || \
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n cert-manager --timeout=120s
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s

# Add delay to allow webhook to be fully ready
echo "Waiting additional time for cert-manager webhook to be fully operational..."
sleep 30

# Setup Cloudflare API token for DNS01 challenges
echo "Creating Cloudflare API token secret..."
CLOUDFLARE_API_TOKEN=$(wild-secret cloudflare.token) || exit 1
kubectl create secret generic cloudflare-api-token \
  --namespace cert-manager \
  --from-literal=api-token="${CLOUDFLARE_API_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Configure cert-manager to use external DNS for challenge verification
echo "Configuring cert-manager to use external DNS servers..."
kubectl patch deployment cert-manager -n cert-manager --patch '
spec:
  template:
    spec:
      dnsPolicy: None
      dnsConfig:
        nameservers:
          - "1.1.1.1"
          - "8.8.8.8"
        searches:
          - cert-manager.svc.cluster.local
          - svc.cluster.local
          - cluster.local
        options:
          - name: ndots
            value: "5"'

# Wait for cert-manager to restart with new DNS config
echo "Waiting for cert-manager to restart with new DNS configuration..."
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=120s

# Apply Let's Encrypt issuers and certificates using kustomize
echo "Creating Let's Encrypt issuers and certificates..."
kubectl apply -k ${CERT_MANAGER_DIR}/kustomize

# Wait for issuers to be ready
echo "Waiting for Let's Encrypt issuers to be ready..."
sleep 10
echo "Wildcard certificate creation initiated. This may take some time to complete depending on DNS propagation."

# Wait for the certificates to be issued (with a timeout)
echo "Waiting for wildcard certificates to be ready (this may take several minutes)..."
kubectl wait --for=condition=Ready certificate wildcard-internal-wild-cloud -n cert-manager --timeout=300s || true
kubectl wait --for=condition=Ready certificate wildcard-wild-cloud -n cert-manager --timeout=300s || true

echo "cert-manager setup complete!"
echo ""
echo "To verify the installation:"
echo "  kubectl get pods -n cert-manager"
echo "  kubectl get clusterissuers"
echo "  kubectl get certificates -n cert-manager"
