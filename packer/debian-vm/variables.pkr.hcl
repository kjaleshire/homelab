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
  default   = ""
  sensitive = true
}

variable "password_crypted" {
  type      = string
  # salt + password > sha-512
  # /etc/shadow format
  default   = ""
  sensitive = true
}
