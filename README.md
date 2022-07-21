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

#### nvidia drivers

```
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf install akmod-nvidia
dnf install xorg-x11-drv-nvidia-cuda # or xorg-x11-drv-nvidia-470xx-cuda for older gpu, akmod-nvidia-470xx
dnf install nvidia-modprobe

distribution=centos8 && \
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | \
    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf install nvidia-container-toolkit
```

label old gpu system that doesn't work with new cuda:

```
kubectl label nodes heavybrick nvidia.com/gpu.deploy.operands=false
```

#### cloud node

configure wireguard externally, set --flannel-iface=k8s and
flannel-backend=host-gw. Add pod routes for 10.42.0.0/24 etc for each node
manually. Requires manual intervention to add node to cluster, keeps from
having extra level of indirection with vxlan or wireguard-in-wireguard.

#### ingress

Separate nginx ingress classes are created per network, "lan", "wg", and
"cloud" for home (with ssl), tailscale, and wan access respectively. Allows
selective control over what is exposed per-network.
