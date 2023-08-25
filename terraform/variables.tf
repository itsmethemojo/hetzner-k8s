variable "master_count" {
  type = number
}

variable "worker_count" {
  type = number
}

variable "hcloud_token" {
  type = string
}

variable "ssh_pub_key_absolute_path" {
  type = string
}

variable "k3s_init_token" {
  type = string
}