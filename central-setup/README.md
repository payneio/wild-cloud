# Central setup

**Central** is a separate machine on your network that provides core wild-cloud services.

Right now, this is entirely `dnsmasq` to provide:

- LAN DNS w/ forwarding of internal and external cloud domains to the cluster.
- PXE for setting up cluster nodes.

Read the [dnsmasq README.md](./dnsmasq/README.md) for how we set things up right now.

## _Future_ setup

We _may_ follow a Central network appliance in the future, where one could install an apt package and use Central like a LAN router.

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
