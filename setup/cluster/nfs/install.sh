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
NFS_DIR="${CLUSTER_SETUP_DIR}/nfs"

print_header "Registering NFS server with Kubernetes cluster"

# Collect required configuration variables
print_info "Collecting NFS configuration..."

# Get current values
current_nfs_host=$(get_current_config "cloud.nfs.host")
current_media_path=$(get_current_config "cloud.nfs.mediaPath")
current_storage_capacity=$(get_current_config "cloud.nfs.storageCapacity")

# Prompt for NFS host
nfs_host=$(prompt_with_default "Enter NFS server hostname or IP address" "192.168.1.100" "${current_nfs_host}")
wild-config-set "cloud.nfs.host" "${nfs_host}"

# Prompt for NFS media path
media_path=$(prompt_with_default "Enter NFS export path for media storage" "/mnt/storage/media" "${current_media_path}")
wild-config-set "cloud.nfs.mediaPath" "${media_path}"

# Prompt for storage capacity
storage_capacity=$(prompt_with_default "Enter NFS storage capacity (e.g., 1Ti, 500Gi)" "1Ti" "${current_storage_capacity}")
wild-config-set "cloud.nfs.storageCapacity" "${storage_capacity}"

print_success "Configuration collected successfully"

# Templates should already be compiled by wild-cluster-services-generate
echo "Using pre-compiled NFS templates..."
if [ ! -d "${NFS_DIR}/kustomize" ]; then
    echo "Error: Compiled templates not found. Run 'wild-cluster-services-generate' first."
    exit 1
fi

# Get NFS configuration from config.yaml
NFS_HOST=$(wild-config cloud.nfs.host) || exit 1
NFS_MEDIA_PATH=$(wild-config cloud.nfs.mediaPath) || exit 1
NFS_STORAGE_CAPACITY=$(wild-config cloud.nfs.storageCapacity) || exit 1

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
    
    # Apply the NFS Kubernetes manifests using kustomize (templates already processed)
    echo "Applying NFS manifests..."
    kubectl apply -k "${NFS_DIR}/kustomize"
    
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