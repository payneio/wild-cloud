# Central setup

"Central" is a Wild-cloud concept for a network appliance use for cloud utilities.

Right now, this is entirely `dnsmasq` to provide:

- LAN DNS w/ forwarding of internal and external cloud domains to the cluster.
- PXE for setting up cluster nodes.

## Setup

The setup is going through architecture design right now.

- Initially, the process used to bootstrap a node was:
  - Run `bin/install-dnsmasq` in your personal wildcloud dir to create a set of install files in `cluster/dnsmasq`.
  - Copy this dir to a configured debian machine to have the services set up correctly as your Central.

## Future setup

To provide a better user experience, we have been creating a debian apt package that also does this while providing a UI.

Development repo: https://github.com/civil-society-dev/wild-central

The setup will look something like this:

```bash
# Download and install GPG key
curl -fsSL https://mywildcloud.org/apt/wild-cloud-central.gpg | sudo tee /usr/share/keyrings/wild-cloud-central-archive-keyring.gpg > /dev/null

# Add repository (modern .sources format)
sudo tee /etc/apt/sources.list.d/wild-cloud-central.sources << 'EOF'
Types: deb
URIs: https://mywildcloud.org/apt
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/wild-cloud-central-archive-keyring.gpg
EOF

# Update and install
sudo apt update
sudo apt install wild-cloud-central
```

browse to `http://localhost:5050`!
