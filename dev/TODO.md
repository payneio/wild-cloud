# To Do

- Look at all FIXME comments.
- Finish Longhorn setup.

## Infrastructure Setup Cleanup

- Standardize metallb allocation in coredns-service.yaml and traefik-service.yaml.
- Remove helm dependency in preference of kustomize.
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

- Manager
  - Cockpit?
  - Databases ✅
  - Tailscale?
  - Backups.
  - SSO?
- Productivity
  - Nextcloud ✅
    - Require 3 nodes for Longhorn.
    - Consider https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner for nextcloud nfs storage.
  - Jellyfin?
- Communications Stack
  - Matrix/Synapse.
  - Email
  - Blog platforms
    - Ghost
  - Web hosting
    - Static web sites
- Intelligence stack
  - Set up cloud to utilize GPUs.
