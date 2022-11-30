locals {
  iso_file     = "local:iso/debian-11.5.0-amd64-netinst.iso"
  iso_checksum = "6a6607a05d57b7c62558e9c462fe5c6c04b9cfad2ce160c3e9140aa4617ab73aff7f5f745dfe51bbbe7b33c9b0e219a022ad682d6c327de0e53e40f079abf66a"

  # Only for building purposes. Runtime cores + memory are set with Terraform.
  cores  = 4
  memory = 8192

  # Multi-line files need to be base64-encoded before embedding in the preseed file.
  # There they can be unencoded.
  ssh_public_key       = chomp(file("${path.root}/ssh/id_ed25519.pub"))
  node_private_key_b64 = replace(base64encode(chomp(file("${path.root}/ssh/vm"))), "\n", "")
  node_public_key      = chomp(file("${path.root}/ssh/vm.pub"))
  tls_ca_b64           = replace(base64encode(chomp(file("${path.root}/certs/flight-ca.pem"))), "\n", "")
  tls_certificate_b64  = replace(base64encode(chomp(file("${path.root}/certs/flight.kja.us.crt"))), "\n", "")
  tls_private_key_b64  = replace(base64encode(chomp(file("${path.root}/certs/flight.kja.us.key"))), "\n", "")
}

source "proxmox" "kates-base-node" {
  boot         = "order=scsi0;ide2"
  boot_command = [
    "<esc><wait>",
    "install",
    " initrd=initrd.gz",
    " auto=true",
    " priority=critical",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " --- <wait>",
    "<enter><wait>"
  ]
  boot_wait    = "3s"

  cores  = local.cores
  memory = local.memory

  disks {
    disk_size         = "8G"
    format            = "raw"
    storage_pool      = "local"
    storage_pool_type = "directory"
    type              = "scsi"
  }

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl",
    {
      ssh_public_key       = local.ssh_public_key,
      node_private_key_b64 = local.node_private_key_b64,
      node_public_key      = local.node_public_key,
      tls_ca_b64           = local.tls_ca_b64,
      tls_certificate_b64  = local.tls_certificate_b64,
      tls_private_key_b64  = local.tls_private_key_b64,
      username             = var.ssh_username,
      password_crypted     = var.password_crypted
    })
  }

  insecure_skip_tls_verify = true
  scsi_controller          = "virtio-scsi-pci"
  iso_file                 = local.iso_file
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  os          = "l26"
  qemu_agent  = true
  unmount_iso = true

  node         = var.proxmox_host_node
  proxmox_url  = var.proxmox_url
  username     = var.proxmox_username
  password     = var.proxmox_password

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "15m"
}

locals {
  builds = {
    "kates-template" = {
      template_name = "kates-debian-11.5.0-tpl"
      vm_name       = "kates-debian-11.5.0-tpl"
      vm_id         = "1003"
    }
  }
}

build {
  name = "kates-node"

  dynamic "source" {
    for_each = local.builds

    labels = ["source.proxmox.kates-base-node"]

    content {
      name = source.key

      template_name = source.value.template_name
      vm_id         = source.value.vm_id
      vm_name       = source.value.vm_name
    }
  }
}
