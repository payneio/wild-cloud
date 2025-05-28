#!/bin/bash
set -e
set -o pipefail

# Navigate to script directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source environment variables
source "${PROJECT_DIR}/load-env.sh"

echo "Registering NFS server with Kubernetes cluster..."

# Check if NFS_HOST is configured
if [[ -z "${NFS_HOST}" ]]; then
    echo "NFS_HOST not set. Skipping NFS Kubernetes setup."
    echo "To enable NFS media sharing:"
    echo "1. Set NFS_HOST=<hostname> in your environment"
    echo "2. Run setup-nfs-host.sh on the NFS host"
    echo "3. Re-run this script"
    exit 0
fi

# Set default for NFS_STORAGE_CAPACITY if not already set
if [[ -z "${NFS_STORAGE_CAPACITY}" ]]; then
    export NFS_STORAGE_CAPACITY="250Gi"
    echo "Using default NFS_STORAGE_CAPACITY: ${NFS_STORAGE_CAPACITY}"
fi

echo "NFS host: ${NFS_HOST}"
echo "Media path: ${NFS_MEDIA_PATH}"
echo "Storage capacity: ${NFS_STORAGE_CAPACITY}"

# Function to resolve NFS host to IP
resolve_nfs_host() {
    if [[ "${NFS_HOST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # NFS_HOST is already an IP address
        NFS_HOST_IP="${NFS_HOST}"
    else
        # Resolve hostname to IP
        NFS_HOST_IP=$(getent hosts "${NFS_HOST}" | awk '{print $1}' | head -n1)
        if [[ -z "${NFS_HOST_IP}" ]]; then
            echo "Error: Unable to resolve hostname ${NFS_HOST} to IP address"
            echo "Make sure ${NFS_HOST} is resolvable from this cluster"
            exit 1
        fi
        
        # Check if resolved IP is localhost - auto-detect network IP instead
        if [[ "${NFS_HOST_IP}" =~ ^127\. ]]; then
            echo "Warning: ${NFS_HOST} resolves to localhost (${NFS_HOST_IP})"
            echo "Auto-detecting network IP for cluster access..."
            
            # Try to find the primary network interface IP (exclude docker/k8s networks)
            local network_ip=$(ip route get 8.8.8.8 | grep -oP 'src \K\S+' 2>/dev/null)
            
            if [[ -n "${network_ip}" && ! "${network_ip}" =~ ^127\. ]]; then
                echo "Using detected network IP: ${network_ip}"
                NFS_HOST_IP="${network_ip}"
            else
                echo "Could not auto-detect network IP. Available IPs:"
                ip addr show | grep "inet " | grep -v "127.0.0.1" | grep -v "10.42" | grep -v "172." | awk '{print "  " $2}' | cut -d/ -f1
                echo "Please set NFS_HOST to the correct IP address manually."
                exit 1
            fi
        fi
    fi
    
    echo "NFS server IP: ${NFS_HOST_IP}"
    export NFS_HOST_IP
}

# Function to test NFS accessibility
test_nfs_accessibility() {
    echo "Testing NFS accessibility from cluster..."
    
    # Check if showmount is available
    if ! command -v showmount >/dev/null 2>&1; then
        echo "Installing NFS client tools..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y nfs-common
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y nfs-utils
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y nfs-utils
        else
            echo "Warning: Unable to install NFS client tools. Skipping accessibility test."
            return 0
        fi
    fi
    
    # Test if we can reach the NFS server
    echo "Testing connection to NFS server..."
    if timeout 10 showmount -e "${NFS_HOST_IP}" >/dev/null 2>&1; then
        echo "✓ NFS server is accessible"
        echo "Available exports:"
        showmount -e "${NFS_HOST_IP}"
    else
        echo "✗ Cannot connect to NFS server at ${NFS_HOST_IP}"
        echo "Make sure:"
        echo "1. NFS server is running on ${NFS_HOST}"
        echo "2. Network connectivity exists between cluster and NFS host"
        echo "3. Firewall allows NFS traffic (port 2049)"
        exit 1
    fi
    
    # Test specific export
    if showmount -e "${NFS_HOST_IP}" | grep -q "${NFS_MEDIA_PATH}"; then
        echo "✓ Media path ${NFS_MEDIA_PATH} is exported"
    else
        echo "✗ Media path ${NFS_MEDIA_PATH} is not found in exports"
        echo "Available exports:"
        showmount -e "${NFS_HOST_IP}"
        echo
        echo "Run setup-nfs-host.sh on ${NFS_HOST} to configure the export"
        exit 1
    fi
}

# Function to create test mount
test_nfs_mount() {
    echo "Testing NFS mount functionality..."
    
    local test_mount="/tmp/nfs-test-$$"
    mkdir -p "${test_mount}"
    
    # Try to mount the NFS export
    if timeout 30 sudo mount -t nfs4 "${NFS_HOST_IP}:${NFS_MEDIA_PATH}" "${test_mount}"; then
        echo "✓ NFS mount successful"
        
        # Test read access
        if ls "${test_mount}" >/dev/null 2>&1; then
            echo "✓ NFS read access working"
        else
            echo "✗ NFS read access failed"
        fi
        
        # Unmount
        sudo umount "${test_mount}" || echo "Warning: Failed to unmount test directory"
    else
        echo "✗ NFS mount failed"
        echo "Check NFS server configuration and network connectivity"
        exit 1
    fi
    
    # Clean up
    rmdir "${test_mount}" 2>/dev/null || true
}

# Function to create Kubernetes resources
create_k8s_resources() {
    echo "Creating Kubernetes NFS resources..."
    
    # Generate config file with resolved variables
    local nfs_dir="${SCRIPT_DIR}/nfs"
    local env_file="${nfs_dir}/config/.env"
    local config_file="${nfs_dir}/config/config.env"
    
    echo "Generating NFS configuration..."
    export NFS_HOST_IP
    export NFS_MEDIA_PATH
    export NFS_STORAGE_CAPACITY
    envsubst < "${env_file}" > "${config_file}"
    
    # Apply the NFS Kubernetes manifests using kustomize
    echo "Applying NFS manifests from: ${nfs_dir}"
    kubectl apply -k "${nfs_dir}"
    
    echo "✓ NFS PersistentVolume and StorageClass created"
    
    # Verify resources were created
    echo "Verifying Kubernetes resources..."
    if kubectl get storageclass nfs >/dev/null 2>&1; then
        echo "✓ StorageClass 'nfs' created"
    else
        echo "✗ StorageClass 'nfs' not found"
        exit 1
    fi
    
    if kubectl get pv nfs-media-pv >/dev/null 2>&1; then
        echo "✓ PersistentVolume 'nfs-media-pv' created"
        kubectl get pv nfs-media-pv
    else
        echo "✗ PersistentVolume 'nfs-media-pv' not found"
        exit 1
    fi
}

# Function to show usage instructions
show_usage_instructions() {
    echo
    echo "=== NFS Kubernetes Setup Complete ==="
    echo
    echo "NFS server ${NFS_HOST} (${NFS_HOST_IP}) has been registered with the cluster"
    echo
    echo "Kubernetes resources created:"
    echo "- StorageClass: nfs"
    echo "- PersistentVolume: nfs-media-pv (${NFS_STORAGE_CAPACITY}, ReadWriteMany)"
    echo
    echo "To use NFS storage in your applications:"
    echo "1. Set storageClassName: nfs in your PVC"
    echo "2. Use accessMode: ReadWriteMany for shared access"
    echo
    echo "Example PVC:"
    echo "---"
    echo "apiVersion: v1"
    echo "kind: PersistentVolumeClaim"
    echo "metadata:"
    echo "  name: my-nfs-pvc"
    echo "spec:"
    echo "  accessModes:"
    echo "    - ReadWriteMany"
    echo "  storageClassName: nfs"
    echo "  resources:"
    echo "    requests:"
    echo "      storage: 10Gi"
    echo
}

# Main execution
main() {
    resolve_nfs_host
    test_nfs_accessibility
    test_nfs_mount
    create_k8s_resources
    show_usage_instructions
}

# Run main function
main "$@"