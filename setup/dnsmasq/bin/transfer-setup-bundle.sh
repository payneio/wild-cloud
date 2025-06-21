#!/bin/bash

if [ ! -d ".wildcloud" ]; then
    echo "Error: You must run this script from a wild-cloud directory"
    exit 1
fi

SERVER_HOST=$(wild-config cloud.dns.ip2) || exit 1
SETUP_DIR="./setup/dnsmasq/setup-bundle"
DESTINATION_DIR="~/dnsmasq-setup"

echo "Copying DNSMasq setup files to ${SERVER_HOST}:${DESTINATION_DIR}..."
scp -r ${SETUP_DIR}/* root@${SERVER_HOST}:${DESTINATION_DIR}
