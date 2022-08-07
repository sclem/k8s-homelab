### k8s homelab

Opiniated home setup for k8s

Deploys plex/radarr/sonarr/jackett/transmission+vpn.

Deploys unifi controller, adguard, homeassistant, mqtt

Runs on k3s with metallb and nginx ingress. Coredns with k8s_external exposes
Loadbalancer services to home network.

### install

Managed with helmfile.

`helmfile sync`

### terraform

* uses cloudflare r2 as backend

#### cloudflare

* creates access group for tunnel whitelist to plex

#### mullvad

* creates mullvad wireguard peer
* creates dynamic port forward
* adds port forward port and peer as kubernetes secret for transmission in plex
  namespace

#### wg-k8s-nodes

* creates wireguard configs for mesh between peers.
Run `terraform apply` and then `make conf HOST=<fqdn>`. Copy to host and use
wg-quick.

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

#### metallb default pool

```
kubectl label node heavybrick location=home
```

#### cloud node

prevent scheduling:

```
kubectl taint node cloud cloud=<provider>:NoExecute
```

configure wireguard externally, set --flannel-iface=k8s and
flannel-backend=host-gw. Add pod routes for 10.42.0.0/24 etc for each node
manually. Requires manual intervention to add node to cluster, keeps from
having extra level of indirection with vxlan or wireguard-in-wireguard.

#### vultr csi

Installed with kustomize

```
kubectl apply -k ./vultr-csi/
```

#### oci csi

k3s agent opts:
```
--kubelet-arg=cloud-provider=external
--kubelet-arg=provider-id=<instance ocid>
```

required label/annotations:

https://github.com/oracle/oci-cloud-controller-manager/blob/906eec8156b64c25e0d9deabe98a6a7c1e9934dd/pkg/util/commons.go#L18

```
kubectl annotate node oci-cloud-arm  oci-cloud-arm oci.oraclecloud.com/compartment-id=<ocid compartment>
kubectl label node oci-cloud-arm failure-domain.beta.kubernetes.io/zone=US-ASHBURN-AD-1 --overwrite
```

#### ingress

Separate nginx ingress classes are created per network, "lan", "wg", and
"cloud" for home (with ssl), tailscale, and wan access respectively. Allows
selective control over what is exposed per-network.
