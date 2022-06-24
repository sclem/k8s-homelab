# values for installing external services with helm

#### nginx

#### certmanager

#### metallb

#### coredns

kubectl edit -n kube-system cm coredns-coredns

add:

```
k8s_external k8s.lan
...
forward . 10.43.0.53
```
