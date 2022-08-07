#!/bin/bash

kubectl delete secret -n kube-system oci-volume-provisioner oci-cloud-controller-manager || true

kubectl create secret generic -n kube-system oci-cloud-controller-manager \
    --from-file=cloud-provider.yaml=./secret-oracle-controller.yaml

kubectl create secret generic -n kube-system oci-volume-provisioner \
    --from-file=config.yaml=./secret-oracle-controller.yaml
