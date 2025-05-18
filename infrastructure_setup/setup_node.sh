#!/bin/bash
set -e

apt-get update

# Longhorn requirements

# Install iscsi on all nodes.
# apt-get install open-iscsi
# modprobe iscsi_tcp
# systemctl restart open-iscsi
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.8.1/deploy/prerequisite/longhorn-iscsi-installation.yaml

# Install NFSv4 client on all nodes.
# apt-get install nfs-common
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.8.1/deploy/prerequisite/longhorn-nfs-installation.yaml

apt-get install cryptsetup

# To check longhorn requirements:
# curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.8.1/scripts/environment_check.sh | bash
