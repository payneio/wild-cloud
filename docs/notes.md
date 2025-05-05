# Notes

## Netowrk topology

LAN: `192.168.8.0/24` (192.168.8.x)

- Metal LB pool: `192.168.8.240/29` (240-247) but actually 240-250
- CAN: `10.42.0.0/16` (10.42.x.x)
  - Service Network: `10.43.0.0/16`
    - Internal DNS: `kube-dns.kube-system.svc.cluster.local` `10.43.0.10`
    - External DNS: `10.43.194.196` == `192.168.8.241`
  - Node civil: `10.42.0.0/24`
  - Node box-01: `10.42.1.0/24`

## Metal LB assignments

- traefik service: 192.168.8.240 (traefik-service.yaml)
- coredns-lb service: 192.168.8.241 (coredns-service.yaml)

## Internal DNS Records

- `kube-dns.kube-system.svc.cluster.local` (k3s default) == `10.43.0.10` (k8s service assigned)
- `coredns-lb.kube-system.svc.cluster.local` (coredns-service.yaml) == `10.43.194.196` (k8s service assigned)

## CoreDNS NodeHosts map:

- traefik.cloud.payne.io == `192.168.8.240` (coredns-config.yaml)
- dns.internal.cloud.payne.io: == `192.168.8.241` (coredns-config.yaml)

- Default CoreDNS service (kube-dns):
  - Internal cluster IP: `10.43.0.10`
  - Internal DNS name: `kube-dns.kube-system.svc.cluster.local`
  - Type: ClusterIP (only accessible within the cluster)
  - Used by: Kubernetes pods for internal DNS resolution
- LoadBalancer CoreDNS service (coredns-lb):
  - Internal cluster IP: `10.43.194.196`
  - External IP: `192.168.8.241`
  - Internal DNS name: `coredns-lb.kube-system.svc.cluster.local`
  - Type: LoadBalancer (accessible both inside and outside the cluster)
  - Used by: External clients (like your LAN devices)

Both services point to the same CoreDNS pods with the selector k8s-app=kube-dns.
The main difference is accessibility - kube-dns is internal-only, while
coredns-lb is exposed to your network at `192.168.8.241`.

## The components

- MetalLB reserves a pool of LAN ip addresses. Services can claim them. Traefik and CoreDNS do that. LoadBalancer resources will use MetalLB to allocate an ip address. This is only useful for giving new IP addresses on the LAN to an internal K8S service.
- CoreDNS assigns DNS names to services and pods and hosts for internal visibility.
- CoreDNS can also assign DNS names for \*.internal.cloud.payne.io for internal lookups, but I haven't figured out how to do this yet.
- ExternalDNS works with CloudFlare to create domain records for \*.cloud.payne.io, needed for auto certs
- Traefik routes external traffic with \*.cloud.payne.io to the right pods
- CertManager takes care of obtaining certs for services with ingress routes.
-

Adding an annotation to a Ingress or IngressRoute resource like this:
external-dns.alpha.kubernetes.io/hostname: dashboard.internal.${DOMAIN}
Prompts Traefik to start reverse proxying to the correct service.

## Discovery

ExternalDNS watches for Ingress resources with `external-dns.alpha.kubernetes.io/hostname` annotations and makes DNS records at Cloudflare.

- WAN
  - A CNAME record at CloudFlare sets `cloud.payne.io` to a dynamic DNS address provided by my router: `fzaf1fa.glddns.com`.
  - ExternalDNS watches for annotations on Ingress or IngressRoute resources to trigger public zone records creation (CNAME to `cloud.payne.io`) on Cloudflare.
    - `external-dns.alpha.kubernetes.io/hostname: "<domain1>,<domain2>"`
- LAN
  - Router hijacks DNS lookups on the LAN and sends them to: to `192.168.8.241`, which `coredns-service.yaml` has squatted on via it's metallb annotation.
  - `example-admin.example-admin.svc.internal.cloud.payne.io` is made accessible by CoreDNS because of the CoreDNS kubernetes plugin.
  - Otherwise, it forwards `1.1.1.1` or `8.8.8.8` for WAN resolution.
- In-cloud
  - CoreDNS is used for resolution. The kubernetes plugin makes all internal resources available in a `cluster.local` domain. E.g. `example-admin.example-admin.svc.cluster.local`

## Incoming traffic routing

- WAN
  - DNS set to router ip.
  - The router port-forwards all `80` and `443` traffic to `192.168.8.240` which is the traefik service is squatting on via it's metallb config.
- LAN

  - DNS hijacked by router ip and resolves to the traefik service.

- Traefik uses its routing table (dynamically created from Ingress and IngressRoute resources) to forward traffic to the correct service.
- The Service forwards to a healthy pod.
- The Pod forwards to the correct container.

## Encryption

Cert-Manager

- `ClusterIssuer` configured to use CloudFlare for dns01 solver for wildcard certificates (`letsencrypt-prod-dns01.yaml`).
- `cert-manager.wildcard-sovereign-cloud-tls` or `cert-manager.wildcard-internal-sovereign-cloud-tls`.
  - Must be copied into the namespace. `deploy-service` does this, e.g.
  - Add to IngressRoute via the `spec.tls.[hosts].secretName` config.

## TO DO

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
