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

resource "hcloud_server" "master_nodes" {
  count        = var.master_count
  name         = "master-node${count.index}"
  image        = "ubuntu-22.04"
  server_type  = "cx11"
  location     = "fsn1"
  firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys     = [hcloud_ssh_key.default.id]
  user_data = templatefile("${path.module}/scripts/init_master.sh", {
    K3S_NODE_NAME = "master-node${count.index}"
    K3S_TOKEN     = var.k3s_init_token
    IP_FILTER     = "10.0"
  })

  labels = {
    "node_type" : "master"
  }
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


  user_data = templatefile("${path.module}/scripts/init_worker.sh", {
    K3S_NODE_NAME = "worker-node${count.index}"
    K3S_TOKEN     = var.k3s_init_token
    MASTER_IP     = local.master_node_private_ips[0]
    IP_FILTER     = "10.0"
  })

  labels = {
    "node_type" : "worker"
  }
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

locals {
  master_node_private_ips = [for network in hcloud_server.master_nodes.*.network : network.*.ip[0]]
  worker_node_private_ips = [for network in hcloud_server.worker_nodes.*.network : network.*.ip[0]]
}

