# oracle free tier arm instances

## Installation:

### create resources

```
terraform apply -var enable_ssh=true
```

### go into node and remove the default oci firewall (breaks metallb comms):

```
sudo systemctl disable --now ufw
sudo iptables -F
sudo ip6tables -F
sudo netfilter-persistent save
sudo systemctl restart k3s-agent
```

### install wireguard confs to each node

```
make -C ../wg-k8s-nodes install HOST=oci-cloud-0.<domain>
```

### remove ssh access

```
terraform apply
```

### install k3s from master node:

get args with `terraform output args`

```
./k3sup join ...
```
