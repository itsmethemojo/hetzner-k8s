#!/bin/bash

node_postfix=$(date '+%Y-%m-%d-%H-%M') && \
private_ip=$(ifconfig | grep 'inet ' | grep ${IP_FILTER} | awk '{print $2}') && \
curl -sfL https://get.k3s.io | K3S_NODE_NAME=${K3S_NODE_NAME}-$node_postfix K3S_TOKEN=${K3S_TOKEN} sh -s - \
  --disable-cloud-controller \
  --disable=traefik \
  --kubelet-arg="cloud-provider=external" \
  --kubelet-arg="provider-id=hcloud://$private_ip"