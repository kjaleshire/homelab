variable "cpus" {
  type = number
}

variable "memory" {
  type = number
}

variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type      = string
  default   = env("DEBIAN_PASSWORD")
  sensitive = true
}

variable "password_crypted" {
  type      = string
  # /etc/shadow format: salt + password > sha-512
  default   = env("DEBIAN_PASSWORD_CRYPTED")
  sensitive = true
}
