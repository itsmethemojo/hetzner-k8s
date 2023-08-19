resource "hcloud_firewall" "myfirewall" {
  name = "my-firewall"
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
  count       = var.jump_host_count
  name        = "jump-host"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  location    = "fsn1"
firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys = [hcloud_ssh_key.default.id]
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
  count       = var.master_count
  name        = "master-node${count.index}"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  location    = "fsn1"
  firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys = [hcloud_ssh_key.default.id]
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
  count       = var.worker_count
  name        = "worker-node${count.index}"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  location    = "fsn1"
  firewall_ids = [hcloud_firewall.myfirewall.id]
  ssh_keys = [hcloud_ssh_key.default.id]
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