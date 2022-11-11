### k8s homelab

Opiniated home setup for k8s

| component             | purpose                                               |
|---                    |---                                                    |
| metallb               | home LB                                               |
| cert-manager          | letsencrypt ssl                                       |
| gpu-operator          | nvidia runtime                                        |
| oci csi               | pvs for oracle cloud free tier                        |
| nginx ingress lan     | ingress on home network                               |
| nginx ingress cloud   | ingress wan                                           |
| nginx ingress wg      | ingress tailscale                                     |
| external-dns          | public dns records for wan                            |
| keycloak              | authn                                                 |
| storage               | postgres/minio/redis/docker registry                  |
| utils                 | cluster issuer, metallb pools, pvs, etc               |
| headscale             | tailscale self-hosted                                 |
| home                  | adguard/unifi/filebrowser etc                         |
| iot                   | internet-of-things, hass/mqtt                         |
| plex                  | plex/radarr/sonarr/jackett/transmission/vpn etc       |

### install

Managed with kustomize.

`kubectl kustomize --enable-helm . | kubectl apply -f -`

### terraform

* uses cloudflare r2 as backend

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

#### cloud node

prevent scheduling:

```
kubectl taint node cloud cloud=<provider>:NoExecute
```

#### oci lb

LB created with terraform in terraform/oracle, not via k8s cloud controller.
Uses nodePorts on oracle cloud node and external dns cname record for
forwarding.

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
"cloud-oracle" for home (with ssl), tailscale, and wan access respectively. Allows
selective control over what is exposed per-network.
