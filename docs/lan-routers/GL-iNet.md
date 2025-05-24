# GL-iNet LAN Router Setup

- Applications > Dynamic DNS > Enable DDNS
  - Enable
  - Use Host Name as your CNAME at Cloudflare.
- Network > LAN > Address Reservation
  - Add all cluster nodes.
- Network > Port Forwarding
  - Add TCP, port 22 to your bastion
  - Add TCP/UDP, port 443 to your cluster load balancer.
- Network > DNS > DNS Server Settings
  - Set to cluster DNS server IP
