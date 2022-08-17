#!/bin/bash

set -e

# dirty script to keep coredns private dns in sync.

update() {
  HOSTS="$(kubectl get ing,svc -A -o go-template-file=/data/dns.gotmpl)"
  kubectl create cm \
    -n kube-system \
    --dry-run=client \
    private-dns-hosts \
    --from-literal=hosts="$HOSTS" -o yaml | \
    kubectl apply -f -
}

echo "starting..."
rm -f pipe && mkfifo /tmp/pipe

kubectl get ing --watch-only -A --no-headers > /tmp/pipe &
kubectl get svc --watch-only -A --no-headers > /tmp/pipe &

while IFS= read -r data; do
    echo $data
    update
done < /tmp/pipe
