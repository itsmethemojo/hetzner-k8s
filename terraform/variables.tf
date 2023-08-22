variable "jump_host_count" {
  type = number
}

variable "master_count" {
  type = number
}

variable "worker_count" {
  type = number
}

variable "token" {
  type = string
}

variable "ssh_pub_key_absolute_path" {
  type = string
}

variable "ssh_priv_key_absolute_path" {
  type = string
}

variable "k3s_token" {
  type = string
}