#!/usr/bin/env bash

# kill.sh - Script to remove all cloud infrastructure resources

set -e

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source environment variables if not already loaded
if [[ -z "$ENVIRONMENT" ]]; then
  if [[ -f "${REPO_ROOT}/load-env.sh" ]]; then
    source "${REPO_ROOT}/load-env.sh"
  else
    echo "Warning: load-env.sh not found. Environment variables may not be available."
  fi
fi

# Print header
echo "====================================================="
echo "Cloud Infrastructure Resource Removal Tool"
echo "====================================================="
echo
echo "WARNING: This script will remove ALL cloud infrastructure components."
echo "This includes:"
echo "  - MetalLB (Load Balancer)"
echo "  - Traefik (Ingress Controller)"
echo "  - cert-manager (Certificate Management)"
echo "  - CoreDNS (Internal DNS)"
echo "  - ExternalDNS (External DNS Management)"
echo "  - Kubernetes Dashboard"
echo "  - Any associated ClusterIssuers, Certificates, etc."
echo
echo "This is a destructive operation and cannot be undone."
echo

# Ask for confirmation
read -p "Are you sure you want to proceed? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

echo
echo "Starting removal process..."
echo

# Function to safely remove resources
remove_resource() {
  local resource_type="$1"
  local resource_name="$2"
  local namespace="${3:-}"
  local ns_flag=""
  
  if [[ -n "$namespace" ]]; then
    ns_flag="-n $namespace"
  fi
  
  echo "Removing $resource_type: $resource_name ${namespace:+in namespace $namespace}"
  
  # Check if resource exists before trying to delete
  if kubectl get "$resource_type" "$resource_name" $ns_flag &>/dev/null; then
    kubectl delete "$resource_type" "$resource_name" $ns_flag
    echo "  ✓ Removed $resource_type: $resource_name"
  else
    echo "  ✓ Resource not found, skipping: $resource_type/$resource_name"
  fi
}

# Function to remove all resources of a type in a namespace
remove_all_resources() {
  local resource_type="$1"
  local namespace="$2"
  
  echo "Removing all $resource_type in namespace $namespace"
  
  # Check if namespace exists before trying to list resources
  if ! kubectl get namespace "$namespace" &>/dev/null; then
    echo "  ✓ Namespace $namespace not found, skipping"
    return
  fi
  
  # Get resources of the specified type in the namespace
  local resources=$(kubectl get "$resource_type" -n "$namespace" -o name 2>/dev/null || echo "")
  
  if [[ -z "$resources" ]]; then
    echo "  ✓ No $resource_type found in namespace $namespace"
    return
  fi
  
  # Delete each resource
  while IFS= read -r resource; do
    if [[ -n "$resource" ]]; then
      resource_name=$(echo "$resource" | cut -d/ -f2)
      kubectl delete "$resource_type" "$resource_name" -n "$namespace"
      echo "  ✓ Removed $resource"
    fi
  done <<< "$resources"
}

# Function to remove helm releases
remove_helm_release() {
  local release_name="$1"
  local namespace="${2:-default}"
  
  echo "Removing Helm release: $release_name from namespace $namespace"
  
  # Check if release exists before trying to uninstall
  if helm status "$release_name" -n "$namespace" &>/dev/null; then
    helm uninstall "$release_name" -n "$namespace"
    echo "  ✓ Uninstalled Helm release: $release_name"
  else
    echo "  ✓ Helm release not found, skipping: $release_name"
  fi
}

# Function to safely remove namespaces
remove_namespace() {
  local namespace="$1"
  
  echo "Removing namespace: $namespace"
  
  # Check if namespace exists before trying to delete
  if kubectl get namespace "$namespace" &>/dev/null; then
    kubectl delete namespace "$namespace" --wait=false
    echo "  ✓ Namespace deletion initiated: $namespace"
  else
    echo "  ✓ Namespace not found, skipping: $namespace"
  fi
}

echo "=== Removing certificate and DNS resources ==="

# 1. Remove ClusterIssuers
echo "Removing ClusterIssuers..."
remove_resource clusterissuer letsencrypt-prod
remove_resource clusterissuer letsencrypt-staging
remove_resource clusterissuer selfsigned-issuer

# 2. Remove Certificates in various namespaces
echo "Removing Certificates..."
remove_all_resources certificates default
remove_all_resources certificates internal
remove_all_resources certificates kubernetes-dashboard

# 3. Remove Issuers
echo "Removing Issuers..."
remove_resource issuer kubernetes-dashboard-ca kubernetes-dashboard
remove_resource issuer selfsigned-issuer kubernetes-dashboard

# 4. Cleanup ExternalDNS records (if possible)
echo "Note: ExternalDNS records in CloudFlare will be orphaned. You may need to manually clean up DNS records."

echo "=== Removing MetalLB resources ==="

# 5. Remove MetalLB custom resources
echo "Removing MetalLB IPAddressPools and L2Advertisements..."
remove_all_resources ipaddresspools.metallb.io metallb-system
remove_all_resources l2advertisements.metallb.io metallb-system

# 5.1. Remove MetalLB core components
echo "Removing MetalLB core components..."
remove_all_resources deployments.apps metallb-system
remove_all_resources daemonsets.apps metallb-system
remove_all_resources services metallb-system
remove_all_resources serviceaccounts metallb-system
remove_all_resources configmaps metallb-system

# 5.2. Remove MetalLB webhook configs
echo "Removing MetalLB Webhook configurations..."
remove_resource validatingwebhookconfiguration metallb-webhook-configuration

echo "=== Removing Traefik resources ==="

# 6. Remove Traefik IngressRoutes and Middlewares
echo "Removing Traefik IngressRoutes and Middlewares..."
remove_all_resources ingressroutes.traefik.containo.us kubernetes-dashboard
remove_all_resources ingressroutes.traefik.containo.us default
remove_all_resources ingressroutes.traefik.containo.us internal
remove_all_resources middlewares.traefik.containo.us cloud-infra
remove_all_resources middlewares.traefik.containo.us default

echo "=== Removing ExternalDNS resources ==="

# 6.1. Remove ExternalDNS resources
echo "Removing ExternalDNS ClusterRole and ClusterRoleBinding..."
remove_resource clusterrole external-dns
remove_resource clusterrolebinding external-dns-viewer
remove_resource secret cloudflare-api-token cloud-infra

echo "=== Removing Helm releases ==="

# 7. Uninstall Helm releases
echo "Uninstalling Helm releases..."
remove_helm_release metallb metallb-system
remove_helm_release traefik cloud-infra
remove_helm_release cert-manager cert-manager
remove_helm_release coredns cloud-infra
remove_helm_release externaldns cloud-infra
remove_helm_release kubernetes-dashboard kubernetes-dashboard
# remove_helm_release postgresql postgres
# remove_helm_release mariadb mariadb

echo "=== Removing namespaces ==="

# 8. Remove namespaces
echo "Removing namespaces..."
remove_namespace cert-manager
remove_namespace cloud-infra
remove_namespace metallb-system
remove_namespace kubernetes-dashboard
remove_namespace internal
# remove_namespace postgres
# remove_namespace mariadb

echo
echo "====================================================="
echo "Cloud infrastructure resources removal completed!"
echo "====================================================="
echo
echo "To reinstall the infrastructure using the recommended approach:"
echo "1. Source environment variables:"
echo "   source load-env.sh"
echo
echo "2. Install components one by one:"
echo "   ./bin/helm-install metallb"
echo "   ./bin/helm-install traefik"
echo "   ./bin/helm-install cert-manager"
echo "   ./bin/helm-install coredns"
echo "   ./bin/helm-install externaldns"
echo
echo "Or use the unified setup script:"
echo "   ./bin/setup-cloud"