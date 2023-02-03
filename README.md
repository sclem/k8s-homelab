### k8s homelab

Opiniated home setup for k8s

| component             | purpose                                               |
|---                    |---                                                    |
| metallb               | home LB                                               |
| cert-manager          | letsencrypt ssl                                       |
| gpu-operator          | nvidia runtime                                        |
| oci csi               | pvs for oracle cloud free tier                        |
| nginx ingress lan     | ingress on home network                               |
| nginx ingress dev     | ingress on home dev vlan                              |
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

Helm releases are managed via flux:

`flux install` to bootstrap.

Then kustomize:

`kubectl apply -k .`

### terraform

* uses cloudflare r2 as backend

#### oracle

creates free arm instance, free nlb with backend portmapping for nodePort
services

#### wg-k8s-nodes

* creates wireguard configs for mesh between peers.
Run `terraform apply` and then `make conf HOST=<fqdn>`. Copy to host and use
wg-quick.

#### nvidia drivers

install on gpu hosts with nvidia-container-toolkit manually.

#### cloud node

prevent scheduling:

```
kubectl taint node cloud cloud=<provider>:NoExecute
```

#### oci lb

LB created with terraform in terraform/oracle, not via k8s cloud controller.
Uses nodePorts on oracle cloud node and external dns cname record for
forwarding.

#### ingress

Separate nginx ingress classes are created per network, "lan", "dev", "wg", and
"cloud-oracle" for home (with ssl), home dev vlan, tailscale, and wan access
respectively. Allows selective control over what is exposed per-network.
