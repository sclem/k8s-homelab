#!/bin/bash

set -e

POD_NAME=$(kubectl get pods -n home -l name=docker -o custom-columns=NAME:.metadata.name --no-headers | head -n1)

kubectl cp -n home $POD_NAME:certs/client ./docker/

docker context rm cloud-remote || true

docker context create cloud-remote --docker "host=tcp://docker.home.sclem.dev:2376,ca=./docker/ca.pem,cert=./docker/cert.pem,key=./docker/key.pem"

# docker copies these to .docker/...
rm -r ./docker/

docker context use cloud-remote
