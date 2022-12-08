variable "proxmox_url" {
  type    = string
  default = "https://${env("PROXMOX_HOST1")}:8006/api2/json"
}

variable "proxmox_host_node" {
  type    = string
  default = env("PROXMOX_HOST1_NODE")
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  default   = env("PROXMOX_PASSWORD")
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = "kates"
}

variable "ssh_password" {
  type      = string
  default   = env("KATES_PASSWORD")
  sensitive = true
}

variable "password_crypted" {
  type      = string
  # /etc/shadow format: salt + password > sha-512
  default   = env("KATES_PASSWORD_CRYPTED")
  sensitive = true
}
