# Dnsmasq setup

Steps:

- Get some hardware. A $30 _Orange Pi Zero 3_ is good enough.
- See [Armbian Setup](./armbian-setup.md).
- From your wildcloud root, run `install-dnsmasq`. This will create the required installation files and copy them all to your dnsmasq server into `/tmp/dnsmasq-setup`.
- ssh into your dnsmasq server and run `/tmp/dnsmasq-setup/setup.sh`.
