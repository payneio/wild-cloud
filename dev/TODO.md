# To Do

## Current Backlog

- Ensure everything comes from .env and nowhere else. .env is the source of
  truth (not, e.g. the environment, though that will be set up).
- Remove helm dependency in preference of kustomize and small scripts (declarative, unix philosophy).
- Figure out how to manage docker dependencies. Really, the containers are the
  things that need to be updated regularly. The manifests only need to change if
  a docker version requires changes (e.g. a different env or secret required).
  - Can we rely on or join community efforts here? E.g.
    https://github.com/docker-library/official-images?
- Eliminate all `payne` references.
- How should I handle port setup (look at example-admin service/ingress)
- Figure out Traefik IngressRoute CRD. Is it better than just Ingress? (dashboard uses IngressRoute currently, example-admin uses Ingress)
- Look at all FIXME comments.
- Standardize install methods
  - Remote yaml installs
    - certmanager uses remote yaml (certmanager.yaml is unused)
    - dashboard uses remote yaml
  - Local yaml installs
    - traefik
    - externaldns
  - Helm
    - metallb
- Standardize metallb allocation in coredns-service.yaml and traefik-service.yaml.
- Swap out all uses of `envsubst` with `gomplate`. Or better yet, use `kustomize`.
- Template out the 192.168.8 addresses in infrastructure_setup.
- consider https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner for nextcloud nfs storage

## App packs to develop

- Manager
  - Cockpit?
  - Databases?
  - Tailscale?
  - Backups.
  - SSO?
- Productivity
  - Nextcloud?
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
