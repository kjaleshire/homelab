locals {
  guest_os_type = "debian11-64"

  debian_image_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd"

  iso_url      = "${local.debian_image_url}/debian-11.5.0-amd64-netinst.iso"
  iso_checksum = "file:${local.debian_image_url}/SHA512SUMS"

  output_directory = "build/debian-11.5.0-amd64-master.vmwarevm"

  ssh_public_key = chomp(file("${path.root}/ssh/id_ed25519.pub"))
  vm_private_key = chomp(file("${path.root}/ssh/vm"))
  vm_public_key = chomp(file("${path.root}/ssh/vm.pub"))
}

source "vmware-iso" "debian-vm" {
  vm_name = "debian-11.5.0-amd64"

  headless = true

  version = 19

  guest_os_type = local.guest_os_type

  boot_wait         = "5s"
  boot_command      = ["<esc><wait>", "install", " initrd=initrd.gz", " auto=true", " priority=critical", " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg", " --- <wait>", "<enter><wait>"]
  boot_key_interval = "10ms"

  // disk_type_id = 0

  cpus   = var.cpus
  memory = var.memory

  usb = true
  vmx_data = {
    "usb_xhci.present" = true # USB 3
  }

  iso_url      = local.iso_url
  iso_checksum = local.iso_checksum

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", { ssh_public_key = local.ssh_public_key, vm_private_key_b64 = replace(base64encode(local.vm_private_key), "\n", ""), vm_public_key = local.vm_public_key, username = var.ssh_username, password_crypted = var.password_crypted })
  }

  ssh_timeout  = "10m"
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password

  shutdown_command = "sudo shutdown -P now"

  output_directory = local.output_directory
}

build {
  name    = "debian-vm-template"
  sources = ["sources.vmware-iso.debian-vm"]
}
