locals {
  kates_server_count = 3
}

resource "local_file" "cloud_init_user_data_kates_server_file" {
  count    = local.kates_server_count
  content  = templatefile("${path.module}/cloud-init/user_data.cfg.pkrtpl", {
    hostname = "kates-server-${count.index}",
    fqdn = "kates-server-${count.index}.flight.kja.us"
  })
  filename = "${path.module}/cloud-init/build/user_data_kates-server-${count.index}.cfg"
}

resource "null_resource" "cloud_init_kates_server_config_files" {
  count = local.kates_server_count
  connection {
    type     = "ssh"
    user     = local.pve_user
    password = local.pve_password
    host     = local.pve_host
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_kates_server_file[count.index].filename
    destination = "/var/lib/vz/snippets/user_data_vm-kates-server-${count.index}.yaml"
  }
}

resource "proxmox_vm_qemu" "kates-servers" {
  count = local.kates_server_count

  depends_on = [
    null_resource.cloud_init_kates_server_config_files,
  ]

  name = "kates-server-${count.index}"
  desc = "kates server node #${count.index}"

  target_node = local.pve_host_node
  clone       = "kates-debian-11.5.0-tpl"
  full_clone  = false
  memory      = 4096
  cores       = 1
  sockets     = 1
  # vcpus = sockets * cores
  onboot = true

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    size    = "16G"
    storage = "local"
    type    = "scsi"
    # format  = "qcow2"
  }

  os_type = "cloud-init"

  cicustom = "user=local:snippets/user_data_vm-kates-server-${count.index}.yaml"

  cloudinit_cdrom_storage = "local"

  tags = "kates server"
}
