# To Do

## Current Backlog

- Get custom data out of coredns config.
- Ensure everything comes from .env and nowhere else. .env is the source of
  truth (not, e.g. the environment, though that will be set up).
- Remove helm dependency in preference of kustomize and small scripts (declarative, unix philosopy).
- Figure out how to manage docker dependencies. Really, the containers are the
  things that need to be updated regularly. The manifests only need to change if
  a docker version requires changes (e.g. a different env or secret required).
  - Can we rely on or join community efforts here? E.g.
    https://github.com/docker-library/official-images?
- Template out the 192.168.8 addresses in infrastructure_setup.
- Convert metallb from helm install to straight templates.
- Change all tls references to sovereign-cloud-tls
- Eliminate all `payne` references.

## Need to investigate

- k8s config and secrets
- Longhorn

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
