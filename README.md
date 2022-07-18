### k8s homelab

Opiniated home setup for k8s

Deploys plex/radarr/sonarr/jackett/transmission+vpn.

Deploys unifi controller, adguard, homeassistant, mqtt

Runs on k3s with metallb and nginx ingress. Coredns with k8s_external exposes
Loadbalancer services to home network.

### install

1. Run through external/ folder first

2. Install utils/ chart

3. Install home/plex charts

### terraform

* uses cloudflare r2 as backend

#### cloudflare

* creates access group for tunnel whitelist to plex

#### mullvad

* creates mullvad wireguard peer
* creates dynamic port forward
* adds port forward port and peer as kubernetes secret for transmission in plex
  namespace
