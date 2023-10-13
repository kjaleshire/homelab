locals {
  tls_service      = { "api-ssl" = 8729, "www-ssl" = 4443 }
  disabled_service = { "ftp" = 21, "telnet" = 23 }
  enabled_service  = { "ssh" = 4222, "winbox" = 8291 }
  # other services needing to be manually disabled after bootstrap. See README.md in this directory.
  # disabled_services = {"api" = 8728, "www" = 80}
}

# terraform state rm 'routeros_ip_service.tls["www-ssl"]'
# terraform import 'routeros_ip_service.tls["www-ssl"]' www-ssl
resource "routeros_ip_service" "tls" {
  for_each    = local.tls_service
  numbers     = each.key
  port        = each.value
  certificate = routeros_system_certificate.tls_cert.name
  tls_version = "only-1.2"
  disabled    = false
}

resource "routeros_ip_service" "disabled" {
  for_each = local.disabled_service
  numbers  = each.key
  port     = each.value
  disabled = true
}

resource "routeros_ip_service" "enabled" {
  for_each = local.enabled_service
  numbers  = each.key
  port     = each.value
  disabled = false
}
