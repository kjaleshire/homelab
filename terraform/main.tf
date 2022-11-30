data "external" "env" {
  program = ["${path.module}/env.sh"]
}

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.0"
    }
  }
}

locals {
  pve_user            = data.external.env.result["proxmox_username"]
  pve_realm           = "pam"
  pve_password        = data.external.env.result["proxmox_password"]
  pve_host            = data.external.env.result["proxmox_host"]
  pve_host_node       = data.external.env.result["proxmox_host_node"]
  pve_api_url         = "https://${data.external.env.result["proxmox_host"]}:8006/api2/json"
  pve_user_with_realm = "${local.pve_user}@${local.pve_realm}"
}

provider "proxmox" {
  pm_user         = local.pve_user_with_realm
  pm_password     = local.pve_password
  pm_api_url      = local.pve_api_url
  pm_tls_insecure = true

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = false
  pm_log_levels = {
    _default    = "info"
    _capturelog = ""
  }
}
