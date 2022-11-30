# Tinyminimicro k3s cluster

## Stuff for provisioning and deploying a Proxmox-backed 3+3 k3s

_Note: make sure the appropriate environment variables are set (for example, with `direnv`). See below for an example `.envrc`._

### High-level setup instructions

1. Procure micro server (Dell Optiplex 5070 Micro).

1. Install Proxmox with routed (not bridged!) networking, the VM bridge interface with CIDR 10.0.0.0/24, a ZFS pool called 'local', and otherwise default settings.

1. Update the local environment variables if necessary (see below for an example `.envrc` file).

1. Ensure the Proxmox node(s) have your SSH public key installed in `authorized_keys`, and that the node is a SSH known host: `ssh-copy-id $PROXMOX_USERNAME@$PROXMOX_HOST1`

1. Use Ansible to provision Proxmox node(s) (`provision-proxmox.yaml`).

1. Use Packer to build k3s server & worker node images: in the `packer-gold-masters` repo, `kates-nodes` directory, run `packer build .`

1. Use Terraform to bootstrap the 3+3 k3s cluster nodes: in the `terraform` directory, run `terraform apply -target=proxmox_vm_qemu.kates-servers -target=proxmox_vm_qemu.kates-workers`

1. Use Ansible to set up k3s (`kates-nodes.yaml`). This will automatically initialize & run k3s on each of the nodes as appropriate, and copy the kubeconfig to `kubernetes/.kube`

1. Once the k3s cluster is operative, you can provision the k3s workloads within the `kubernetes` subdirectory.

1. To setup local resolution for nodes names in the `flight.kja.us` subdomain, re-run Proxmox provisioning (`provision-proxmox.yaml`).

_You should now have a fully-provisioned 3+3 node cluster running k3s ready to run workloads._

### Example `.envrc`

``` shell
# Local IP address of the Proxmox node
export PROXMOX_HOST1=192.168.0.4
# Hostname of the Proxmox node
export PROXMOX_HOST1_NODE=example_proxmox_host
# Credentials you set up during install, usually `root`
export PROXMOX_USERNAME=root
export PROXMOX_PASSWORD=example_proxmox_password
```
