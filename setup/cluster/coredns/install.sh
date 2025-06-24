#!/bin/bash
set -e

if [ -z "${WC_HOME}" ]; then
    echo "Please source the wildcloud environment first. (e.g., \`source ./env.sh\`)"
    exit 1
fi

CLUSTER_SETUP_DIR="${WC_HOME}/setup/cluster"
COREDNS_DIR="${CLUSTER_SETUP_DIR}/coredns"

echo "Setting up CoreDNS for k3s..."

# Process templates with wild-compile-template-dir
echo "Processing CoreDNS templates..."
wild-compile-template-dir --clean ${COREDNS_DIR}/kustomize.template ${COREDNS_DIR}/kustomize

# Apply the k3s-compatible custom DNS override (k3s will preserve this)
echo "Applying CoreDNS custom override configuration..."
kubectl apply -f "${COREDNS_DIR}/kustomize/coredns-custom-config.yaml"

# Apply the LoadBalancer service for external access to CoreDNS
echo "Applying CoreDNS service configuration..."
kubectl apply -f "${COREDNS_DIR}/kustomize/coredns-lb-service.yaml"

# Restart CoreDNS pods to apply the changes
echo "Restarting CoreDNS pods to apply changes..."
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system

echo "CoreDNS setup complete!"
echo
echo "To verify the installation:"
echo "  kubectl get pods -n kube-system"
echo "  kubectl get svc -n kube-system coredns"
echo "  kubectl describe svc -n kube-system coredns"
echo "  kubectl logs -n kube-system -l k8s-app=kube-dns -f"
