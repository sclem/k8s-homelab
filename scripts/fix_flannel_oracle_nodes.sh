#!/bin/bash

# Until k3s releases with new flannel and supports ipv6 combined flannel, need
# to set the endpoints because oci uses private ip with a gateway.

HOME_NODE_LIST=(
    videx
    heavybrick
    pi@homepi
)

ORACLE_NODE_LIST=(
    oci-cloud-arm
)

DOMAIN="clem.stream"

pubkey() {
    kubectl get node "$1" -o jsonpath='{.metadata.annotations.flannel\.alpha\.coreos\.com/backend-data}' | jq -r '.PublicKey'
}

setendpoint() {
    ssh -t "$1" sudo wg set flannel-wg peer "$2" endpoint $(dig +short "$3" AAAA):51820
}

for ORACLE_NODE in ${ORACLE_NODE_LIST[@]}; do
    PUBKEY="$(pubkey $ORACLE_NODE)"
    for NODE in ${HOME_NODE_LIST[@]}; do
        set -x
        setendpoint $NODE $PUBKEY "$ORACLE_NODE.$DOMAIN"
        set +x
    done
done
