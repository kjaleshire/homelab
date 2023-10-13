resource "routeros_interface_bridge" "bridge" {
  name           = "bridge"
  vlan_filtering = false
  auto_mac       = false
  comment        = "defconf"
}

resource "routeros_interface_bridge_port" "bridge_ether_ports" {
  for_each  = toset([for i in range(2, 9) : tostring(i)])
  bridge    = "bridge"
  interface = "ether${each.key}"
  comment   = "defconf"
  pvid      = 1
}

resource "routeros_interface_bridge_port" "bridge_sfp_port" {
  bridge    = "bridge"
  interface = "sfp-sfpplus1"
  comment   = "defconf"
  pvid      = 1
}

resource "routeros_interface_list" "lan_interface" {
  name    = "LAN"
  comment = "defconf"
}

resource "routeros_interface_list_member" "lan_bridge" {
  interface = routeros_interface_bridge.bridge.name
  list      = routeros_interface_list.lan_interface.name
}

resource "routeros_interface_list" "wan_interface" {
  name    = "WAN"
  comment = "defconf"
}

resource "routeros_interface_list_member" "wan_ether1" {
  interface = var.wan_port
  list      = routeros_interface_list.wan_interface.name
}
