#!/bin/bash

sudo apt-get update
sudo apt-get install -y jq curl

private_ip=$(curl -s -H "Authorization: Bearer ${HCLOUD_TOKEN}" 'https://api.hetzner.cloud/v1/servers' | jq '.servers[] | select(.name=="${SERVER_NAME}")' | jq .private_net[0].ip -r) && \
server_id=$(curl -s -H "Authorization: Bearer ${HCLOUD_TOKEN}" 'https://api.hetzner.cloud/v1/servers' | jq '.servers[] | select(.name=="${SERVER_NAME}")' | jq .id) && \
curl -sfL https://get.k3s.io | K3S_NODE_NAME=$private_ip K3S_TOKEN=${K3S_TOKEN} sh -s - agent \
  --node-ip $private_ip \
  --server https://${MASTER_IP}:6443 \
  --kubelet-arg="cloud-provider=external" \
  --kubelet-arg="provider-id=hcloud://$server_id"