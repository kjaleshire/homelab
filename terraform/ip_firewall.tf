################################################################################
#
# DEFAULT RULESET
#
################################################################################

################################################################################
# INPUT chain
################################################################################

resource "routeros_ip_firewall_filter" "defconf_accept_established_related_untracked" {
  comment          = "defconf: accept established,related,untracked"
  action           = "accept"
  chain            = "input"
  connection_state = "established,related,untracked"
}

resource "routeros_ip_firewall_filter" "defconf_drop_invalid" {
  comment          = "defconf: drop invalid"
  action           = "drop"
  chain            = "input"
  connection_state = "invalid"
}

resource "routeros_ip_firewall_filter" "defconf_accept_icmp" {
  comment  = "defconf: accept ICMP"
  action   = "accept"
  chain    = "input"
  protocol = "icmp"
}

resource "routeros_ip_firewall_filter" "defconf_accept_to_local_loopback" {
  comment     = "defconf: accept to local loopback (for CAPsMAN)"
  action      = "accept"
  chain       = "input"
  dst_address = "127.0.0.1"
}

locals {
  defconf_drop_non_lan_input_comment = "defconf: drop all not coming from LAN"
}

resource "routeros_ip_firewall_filter" "defconf_drop_all_not_coming_from_lan" {
  comment           = local.defconf_drop_non_lan_input_comment
  action            = "drop"
  chain             = "input"
  in_interface_list = "!LAN"
}

################################################################################
# FORWARD chain
################################################################################

resource "routeros_ip_firewall_filter" "defconf_accept_in_ipsec_policy" {
  comment      = "defconf: accept in ipsec policy"
  action       = "accept"
  chain        = "forward"
  ipsec_policy = "in,ipsec"
}

resource "routeros_ip_firewall_filter" "defconf_accept_out_ipsec_policy" {
  comment      = "defconf: accept out ipsec policy"
  action       = "accept"
  chain        = "forward"
  ipsec_policy = "out,ipsec"
}

resource "routeros_ip_firewall_filter" "defconf_fasttrack" {
  comment          = "defconf: fasttrack"
  action           = "fasttrack-connection"
  chain            = "forward"
  connection_state = "established,related"
  hw_offload       = true
}

resource "routeros_ip_firewall_filter" "defconf_accept_established_related_untracked_forward" {
  comment          = "defconf: accept established,related, untracked"
  action           = "accept"
  chain            = "forward"
  connection_state = "established,related,untracked"
}

resource "routeros_ip_firewall_filter" "defconf_drop_invalid_forward" {
  comment          = "defconf: drop invalid"
  action           = "drop"
  chain            = "forward"
  connection_state = "invalid"
}

resource "routeros_ip_firewall_filter" "defconf_drop_all_from_wan_not_dstnated" {
  comment              = "defconf: drop all from WAN not DSTNATed"
  action               = "drop"
  chain                = "forward"
  connection_state     = "new"
  connection_nat_state = "!dstnat"
  in_interface_list    = "WAN"
}

################################################################################
# INPUT chain (custom additions)
################################################################################

data "routeros_firewall" "fw" {
  rules {
    filter = {
      chain   = "input"
      comment = local.defconf_drop_non_lan_input_comment
    }
  }
}

# output "rules" {
#   value = [for value in data.routeros_firewall.fw.rules: [value.id, value.src_address]]
# }

resource "routeros_ip_firewall_filter" "allow_home_lan" {
  comment     = "allow input from home LAN"
  action      = "accept"
  chain       = "input"
  src_address = var.att_consumer_cidr
  # BOOTSTRAP uncomment to place rule correctly
  # place_before = "${data.routeros_firewall.fw.rules[0].id}"
}

################################################################################
# NAT foundation rules
################################################################################

resource "routeros_ip_firewall_nat" "default_masquerade" {
  comment            = "defconf: masquerade"
  action             = "masquerade"
  chain              = "srcnat"
  out_interface_list = routeros_interface_list.wan_interface.name
  ipsec_policy       = "out,none"
}

resource "routeros_ip_firewall_nat" "nat_hairpin" {
  comment            = "NAT Hairpin"
  place_before       = 0
  chain              = "srcnat"
  action             = "masquerade"
  src_address        = var.cluster_network_cidr
  dst_address        = var.load_balancer_cidr
  out_interface_list = routeros_interface_list.lan_interface.name
  protocol           = "tcp"
  log                = false
  log_prefix         = "NAT_HAIRPIN"
}

resource "routeros_ip_firewall_nat" "k8s_api_port_forward" {
  comment           = "Outland Kubernetes API"
  action            = "dst-nat"
  chain             = "dstnat"
  src_address       = var.att_consumer_cidr
  in_interface_list = routeros_interface_list.wan_interface.name
  dst_address       = var.wan_ip
  dst_port          = "6443"
  to_addresses      = var.outland_ip
  protocol          = "tcp"
  log               = false
}

resource "routeros_ip_firewall_nat" "outland_ssh_port_forward" {
  comment           = "outland SSH"
  chain             = "dstnat"
  action            = "dst-nat"
  src_address       = var.att_consumer_cidr
  in_interface_list = routeros_interface_list.wan_interface.name
  dst_address       = var.wan_ip
  dst_port          = "6222"
  protocol          = "tcp"
  to_addresses      = var.outland_ip
  to_ports          = "22"
  log               = false
}

# resource "routeros_ip_firewall_nat" "endpoint_independent_nat_out" {
#   comment           = "Endpoint-independent NAT out"
#   chain             = "srcnat"
#   action            = "endpoint-independent-nat"
#   out_interface_list = routeros_interface_list.wan_interface.name
#   protocol          = "udp"
#   log               = false
# }

# resource "routeros_ip_firewall_nat" "endpoint_independent_nat_in" {
#   comment           = "Endpoint-independent NAT in"
#   chain             = "dstnat"
#   action            = "endpoint-independent-nat"
#   in_interface_list = routeros_interface_list.wan_interface.name
#   protocol          = "udp"
#   log               = false
# }

################################################################################
# NAT for Kubernetes BGP-based load balancers
################################################################################

locals {
  local_addresses_and_interfaces = {
    (var.cluster_network_cidr) = routeros_interface_list.lan_interface.name,
    (var.att_consumer_cidr)    = routeros_interface_list.wan_interface.name
  }

  # https://api.github.com/meta
  # For flux
  github_webhook_source_ips = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "143.55.64.0/20"
  ]
}

resource "routeros_ip_firewall_nat" "tls_port_forward" {
  for_each = merge(local.local_addresses_and_interfaces, {
    for ip in local.github_webhook_source_ips :
    ip => routeros_interface_list.wan_interface.name
  })

  comment           = "NGINX Ingress"
  chain             = "dstnat"
  action            = "dst-nat"
  src_address       = each.key
  in_interface_list = each.value
  dst_address       = var.wan_ip
  dst_port          = "443"
  protocol          = "tcp"
  to_addresses      = "10.45.1.20"
  log               = false
  log_prefix        = "NGINX_PORT_FORWARD"
}

resource "routeros_ip_firewall_nat" "adguardhome_udp_port_forward" {
  comment           = "adguardhome udp"
  chain             = "dstnat"
  action            = "dst-nat"
  dst_port          = "853"
  protocol          = "udp"
  to_addresses      = "10.45.1.10"
  log               = false
}

resource "routeros_ip_firewall_nat" "adguardhome_tcp_port_forward" {
  for_each = local.local_addresses_and_interfaces

  comment           = "adguardhome tcp"
  chain             = "dstnat"
  action            = "dst-nat"
  src_address       = each.key
  in_interface_list = each.value
  dst_address       = var.wan_ip
  dst_port          = "853"
  protocol          = "tcp"
  to_addresses      = "10.45.1.10"
  log               = false
}

resource "routeros_ip_firewall_nat" "azerothcore_port_forward" {
  for_each = merge(local.local_addresses_and_interfaces, {
    for ip in split(",", var.player_ips) :
    ip => routeros_interface_list.wan_interface.name
  })

  comment           = "azerothcore"
  chain             = "dstnat"
  action            = "dst-nat"
  src_address       = each.key
  in_interface_list = each.value
  dst_address       = var.wan_ip
  dst_port          = "3724,8085"
  protocol          = "tcp"
  to_addresses      = "10.45.1.16"
  log               = false
}

resource "routeros_ip_firewall_nat" "gitlab_shell_port_forward" {
  for_each = local.local_addresses_and_interfaces

  comment           = "gitlab shell"
  chain             = "dstnat"
  action            = "dst-nat"
  src_address       = each.key
  in_interface_list = each.value
  dst_address       = var.wan_ip
  dst_port          = "4243"
  protocol          = "tcp"
  to_addresses      = "10.45.1.12"
  log               = false
}

resource "routeros_ip_firewall_nat" "jellyfin_udp_port_forward" {
  comment           = "jellyfin udp"
  chain             = "dstnat"
  action            = "dst-nat"
  dst_port          = "1900,7359"
  protocol          = "udp"
  to_addresses      = "10.45.1.13"
  log               = false
}

resource "routeros_ip_firewall_nat" "utility_belt_port_forward" {
  for_each = local.local_addresses_and_interfaces

  comment           = "utility belt ssh"
  chain             = "dstnat"
  action            = "dst-nat"
  src_address       = each.key
  in_interface_list = each.value
  dst_address       = var.wan_ip
  dst_port          = "6938"
  protocol          = "tcp"
  to_addresses      = "10.45.1.14"
  log               = false
}

resource "routeros_ip_firewall_nat" "wireguard_port_forward" {
  comment           = "wireguard"
  chain             = "dstnat"
  action            = "dst-nat"
  dst_port          = "26668"
  protocol          = "udp"
  to_addresses      = "10.45.1.15"
  log               = false
}
