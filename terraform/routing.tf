locals {
  as = "65530" # should match CiliumBGPPeeringPolicy AS
}

resource "routeros_routing_bgp_connection" "outland" {
  name = "outland-bgp"
  as   = local.as

  connect        = true
  listen         = true
  hold_time      = "10m"
  keepalive_time = "30"

  local {
    role = "ibgp"
  }

  remote {
    address = var.outland_ip
  }
}
