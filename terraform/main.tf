variable "wan_ip" {
  type = string
}

variable "outland_ethernet_mac" {
  type = string
}

variable "player_ips" {
  type = string
}
variable "wan_port" {
  type    = string
  default = "ether1"
}

variable "default_dhcp_range" {
  type    = string
  default = "10.44.1.128-10.44.1.254"
}

variable "outland_ip" {
  type    = string
  default = "10.44.1.254"
}

variable "router_ip" {
  type    = string
  default = "10.44.1.1"
}

variable "class_a_local_cidr" {
  type    = string
  default = "10.0.0.0/8"
}

variable "cluster_network_cidr" {
  type    = string
  default = "10.32.0.0/12"
}

variable "load_balancer_cidr" {
  type    = string
  default = "10.45.1.0/24"
}

variable "att_consumer_cidr" {
  type    = string
  default = "192.168.1.0/24"
}
