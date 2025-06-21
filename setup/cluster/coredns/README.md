# CoreDNS

- https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
- https://github.com/kubernetes/dns/blob/master/docs/specification.md
- https://coredns.io/

CoreDNS has the `kubernetes` plugin, so it returns all k8s service endpoints in well-known format.

All services and pods are registered in CoreDNS.

- <service-name>.<namespace>.svc.cluster.local
- <service-name>.<namespace>
- <service-name> (if in the same namespace)

- <pod-ipv4-address>.<namespace>.pod.cluster.local
- <pod-ipv4-address>.<service-name>.<namespace>.svc.cluster.local

Any query for a resource in the `internal.$DOMAIN` domain will be given the IP of the Traefik proxy. We expose the CoreDNS server in the LAN via MetalLB just for this capability.

## Default CoreDNS Configuration

Found at: https://github.com/k3s-io/k3s/blob/master/manifests/coredns.yaml

This is k3s default CoreDNS configuration, for reference:

```txt
.:53 {
    errors
    health
    ready
    kubernetes %{CLUSTER_DOMAIN}% in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
    }
    hosts /etc/coredns/NodeHosts {
      ttl 60
      reload 15s
      fallthrough
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
    import /etc/coredns/custom/*.override
}
import /etc/coredns/custom/*.server
```
