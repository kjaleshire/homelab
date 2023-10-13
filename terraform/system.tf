resource "routeros_system_certificate" "tls_cert" {
  name        = "tls-cert"
  common_name = "Mikrotik Router"
  days_valid  = 3650
  key_usage   = ["key-cert-sign", "crl-sign", "digital-signature", "key-agreement", "tls-server"]
  key_size    = "prime256v1"
  trusted     = true
  sign {
  }
}
