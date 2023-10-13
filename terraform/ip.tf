resource "routeros_ip_address" "bridge_subnet" {
  address   = "${var.router_ip}/${split("/", var.class_a_local_cidr)[1]}"
  interface = routeros_interface_bridge.bridge.name
  network   = split("/", var.class_a_local_cidr)[0]
}

resource "routeros_ip_dhcp_client" "wan_client" {
  interface = var.wan_port
  comment   = "defconf"
}

resource "routeros_ip_dhcp_server" "bridge_server" {
  address_pool = routeros_ip_pool.default_dhcp.name
  interface    = routeros_interface_bridge.bridge.name
  name         = "defconf"
}

resource "routeros_ip_dhcp_server_network" "dhcp_server_network" {
  address    = var.cluster_network_cidr
  gateway    = var.router_ip
  dns_server = var.router_ip
  netmask    = split("/", var.cluster_network_cidr)[1]
  comment    = "defconf"
}

resource "routeros_ip_dhcp_server_lease" "outland_lease" {
  address     = var.outland_ip
  comment     = "outland"
  mac_address = var.outland_ethernet_mac
}

resource "routeros_ip_pool" "default_dhcp" {
  name   = "default-dhcp"
  ranges = [var.default_dhcp_range]
}

resource "routeros_ip_dns_record" "outland_record" {
  name    = "outland.lan"
  address = var.outland_ip
  type    = "A"
}

resource "routeros_ip_dns_record" "router_record" {
  name    = "router.lan"
  address = var.router_ip
  type    = "A"
}
