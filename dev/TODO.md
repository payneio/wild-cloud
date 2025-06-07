# To Do

- Look at all FIXME comments.
- need to lock down w/ crowdsec (start an ops guide. follow ops discipline)
- Finish dnsmasq setup
- Create `wild-init` script.
- Create `wild` golang cli.

## Infrastructure Setup Cleanup

- Continue migrating from k3s to talos.
- Continue converting infrastructure_setup to kustomize
- Put Cloudflare-specific setup in a `dns_providers` directory.
- Standardize metallb allocation in coredns-service.yaml and traefik-service.yaml.
- Update setups to use kustomize patterns
- Figure out Traefik IngressRoute CRD. Is it better than just Ingress? (dashboard uses IngressRoute currently, example-admin uses Ingress)
- Standardize install methods
  - Remote yaml installs
    - certmanager uses remote yaml (certmanager.yaml is unused)
    - dashboard uses remote yaml
  - Local yaml installs
    - traefik
    - externaldns
  - Helm
    - metallb
- Swap out all uses of `envsubst` with `gomplate`. Or better yet, use `kustomize`.
- Template out the 192.168.8 addresses in infrastructure_setup.

## App packs to develop

- Operator
  - Cockpit?
  - Databases ✅
  - Tailscale?
  - Backups.
    - restic
  - SSO
    - zitadel
- Productivity
  - books: librum
- Communications Stack
  - Matrix/Synapse.
  - Email
  - Blog platforms
    - Ghost
  - Web hosting
    - Static web sites
- Intelligence stack
  - Set up cloud to utilize GPUs.
  - LLM: langfuse
- Data stack
  - mathesar (airtable)
  - nocodb (airtable)
  - Jupiter lab
- Dev stack?
  - faas: fx
  - pass: kubero
  - mobile-app-backend-aas: nhost
  - cloud: tau
- Misc
  - home assistant
