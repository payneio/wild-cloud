# Setup instructions

Follow the instructions to [set up a dnsmasq machine](./dnsmasq/README.md).

Follow the instructions to [set up cluster nodes](./cluster-nodes/README.md).

Set up cluster services:

```bash
./setup/cluster/setup-all.sh
```

Now make sure everything works:

```bash
./setup/cluster/validate-setup.sh
```
