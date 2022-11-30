locals {
  kates_worker_count = 3
}

resource "local_file" "cloud_init_user_data_kates_worker_file" {
  count    = local.kates_worker_count
  content  = templatefile("${path.module}/cloud-init/user_data.cfg.pkrtpl", {
    hostname = "kates-worker-${count.index}",
    fqdn = "kates-worker-${count.index}.flight.kja.us"
  })
  filename = "${path.module}/cloud-init/build/user_data_kates-worker-${count.index}.cfg"
}

resource "null_resource" "cloud_init_kates_worker_config_files" {
  count = local.kates_worker_count
  connection {
    type     = "ssh"
    user     = local.pve_user
    password = local.pve_password
    host     = local.pve_host
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_kates_worker_file[count.index].filename
    destination = "/var/lib/vz/snippets/user_data_vm-kates-worker-${count.index}.yaml"
  }
}

resource "proxmox_vm_qemu" "kates-workers" {
  count = local.kates_worker_count

  depends_on = [
    null_resource.cloud_init_kates_worker_config_files,
  ]

  name = "kates-worker-${count.index}"
  desc = "kates worker node #${count.index}"

  target_node = local.pve_host_node
  clone       = "kates-debian-11.5.0-tpl"
  full_clone  = false
  memory      = 8192
  cores       = 2
  sockets     = 1
  # vcpus = sockets * cores
  onboot = true

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    size    = "32G"
    storage = "local"
    type    = "scsi"
    # format  = "qcow2"
  }

  os_type = "cloud-init"

  cicustom = "user=local:snippets/user_data_vm-kates-worker-${count.index}.yaml"

  cloudinit_cdrom_storage = "local"

  tags = "kates worker"
}
