#!/bin/bash

set -ex

SSH_HOST=${SSH_HOST-$HOST}

make -s conf HOST=${HOST} | ssh ${SSH_HOST} 'cat > /tmp/wg.conf'
#terraform output -json configs | jq -r ".${HOST}.conf" | ssh ${HOST} 'cat > /tmp/wg.conf'
ssh -t ${SSH_HOST} 'sudo mv /tmp/wg.conf /etc/wireguard/k8s.conf && sudo systemctl restart wg-quick@k8s'
