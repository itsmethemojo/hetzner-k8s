resource "hcloud_firewall" "myfirewall" {
  name = "my-firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "30080"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "30443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "30080"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "30443"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "80"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "443"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "6443"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

}


resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_ssh_key" "default" {
  name       = "ssh access"
  public_key = file(var.ssh_pub_key_absolute_path)
}

resource "hcloud_server" "jump_host" {
  count        = var.jump_host_count
  name         = "jump-host"
  image        = "ubuntu-22.04"
  server_type  = "cx11"
  location     = "fsn1"
  firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys     = [hcloud_ssh_key.default.id]
  #labels = {
  #  "test" : "tessst1"
  #}
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.network.id
  }
  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

resource "hcloud_server" "master_nodes" {
  count        = var.master_count
  name         = "master-node${count.index}"
  image        = "ubuntu-22.04"
  server_type  = "cx11"
  location     = "fsn1"
  firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys     = [hcloud_ssh_key.default.id]
  #labels = {
  #  "test" : "tessst1"
  #}
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.network.id
  }
  depends_on = [
    hcloud_network_subnet.network-subnet
  ]

}

resource "hcloud_server" "worker_nodes" {
  count        = var.worker_count
  name         = "worker-node${count.index}"
  image        = "ubuntu-22.04"
  server_type  = "cx11"
  location     = "fsn1"
  firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys     = [hcloud_ssh_key.default.id]
  #labels = {
  #  "test" : "tessst1"
  #}
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.network.id
  }
  depends_on = [
    hcloud_network_subnet.network-subnet
  ]

}


resource "hcloud_load_balancer" "load_balancer" {
  name               = "g-unit-load-balancer"
  load_balancer_type = "lb11"
  location           = "fsn1"
}

resource "hcloud_load_balancer_target" "load_balancer_target" {
  count            = var.worker_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  server_id        = hcloud_server.worker_nodes[count.index].id
}

resource "hcloud_load_balancer_service" "load_balancer_service_http" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 30080
  health_check {
    protocol = "tcp"
    port = 30080
    interval = 30
    timeout = 30
  }
}
resource "hcloud_load_balancer_service" "load_balancer_service_https" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 30443
  health_check {
    protocol = "tcp"
    port = 30443
    interval = 30
    timeout = 30
  }
}

#This works only for one master and worker node
resource "null_resource" "master_exec" {
  provisioner "local-exec" {
    command = "ssh -i ${var.ssh_priv_key_absolute_path} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new root@${hcloud_server.master_nodes[0].ipv4_address} 'curl -sfL https://get.k3s.io/ | K3S_TOKEN=${var.k3s_token} sh -s -'"
  }
  depends_on = [
    hcloud_server.master_nodes
  ]
}

#terraform state pull | jq .resources[] -c | grep worker_nodes | grep '"hcloud_server"' | jq .instances[1].attributes.network[0].ip -r

resource "null_resource" "worker_exec1" {
  count = var.worker_count
  provisioner "local-exec" {
    command = " sleep 10; export PRIVATE_IP=$(terraform state pull | jq .resources[] -c | grep worker_nodes | grep '\"hcloud_server\"' | jq .instances[${count.index}].attributes.network[0].ip -r); echo $PRIVATE_IP; ssh -i ${var.ssh_priv_key_absolute_path} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new root@$PRIVATE_IP 'curl -sfL https://get.k3s.io/ | K3S_NODE_NAME=$PRIVATE_IP K3S_URL=https://10.0.1.1:6443/ INSTALL_K3S_EXEC=agent K3S_TOKEN=${var.k3s_token} sh -s -'"
  }
  depends_on = [
    hcloud_server.worker_nodes
  ]
}