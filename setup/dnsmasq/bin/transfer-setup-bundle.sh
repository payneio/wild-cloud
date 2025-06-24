#!/bin/bash

# Check if WC_HOME is set
if [ -z "${WC_HOME:-}" ]; then
    echo "Error: WC_HOME environment variable not set. Run \`source ./env.sh\`."
    exit 1
fi

SERVER_HOST=$(wild-config cloud.dns.ip) || exit 1
SETUP_DIR="${WC_HOME}/setup/dnsmasq/setup-bundle"
DESTINATION_DIR="~/dnsmasq-setup"

echo "Copying DNSMasq setup files to ${SERVER_HOST}:${DESTINATION_DIR}..."
scp -r ${SETUP_DIR}/* root@${SERVER_HOST}:${DESTINATION_DIR}
