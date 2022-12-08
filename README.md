# Homelab Provisioning

## How to provision k3s cluster

Build the k3s server & worker images with packer (see README.md in the `packer` directory).

Follow the instructions in `terraform/` to provision the Proxmox cluster & spin up the VM nodes.

Run `refresh_kates_known_hosts.sh` in the project root. Then in `ansible/` run:

```shell
ansible-playbook kates-nodes.yaml
```

This will spin up a 3+3 master+worker cluster configuration in a few minutes with big storage attached to workers 0 and 1.

## How to provision new Kali & Debian VMs

First, enable and start SSH on the VMs:

``` shell
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

Set the appropriate environment variables for each host: HOSTTYPE_USERNAME, HOSTTYPE_PASSWORD, HOSTTYPE_HOST, where HOSTTYPE is something like `KALI` or `DEBIAN`

Then copy the SSH key (to Kali at least; if using Debian gold master the SSH public key is already present):

Using `ssh-copy-id` if the public key is on the filesystem:

``` shell
ssh-copy-id -i ~/.ssh/id_ed25519 $KALI_USERNAME@$KALI_HOST
```

Or if using 1Password as the SSH agent (public key auth temporarily disabled):

```shell
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no $KALI_USERNAME@$KALI_HOST "mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; sed -i /$KEY_NAME\$/d ~/.ssh/authorized_keys; echo $(ssh-add -L | grep "$KEY_NAME\$") >> ~/.ssh/authorized_keys"
```

Where `$KEY_NAME` is the name of the key in 1Password.

Next copy the VM-special private/public keypair so certain private repositories can be cloned:

```shell
scp ~/Downloads/id_ed25519 $KALI_USERNAME@$KALI_HOST:/home/kali/.ssh/id_ed25519
ssh $KALI_USERNAME@$KALI_HOST "chmod 0600 ~/.ssh/id_ed25519;echo $(ssh-add -L | grep "virtual-machine\$") > ~/.ssh/id_ed25519.pub"
```

Now you can run the provisioner playbooks:

``` shell
ansible-playbook debian-vm.yaml
ansible-playbook kali-vm.yaml
```

## How to provision a FreeBSD VM

1. Download a FreeBSD VMware disk image, the latest of which at this time is [here](https://download.freebsd.org/ftp/releases/VM-IMAGES/13.1-RELEASE/amd64/Latest/FreeBSD-13.1-RELEASE-amd64.vmdk.xz) and decompress it

1. Create a new virtual machine in VMware by dragging the expanded disk image into the New Virtual Machine dialogue, choose a correct OS, choose to use the existing decompressed disk, and at the final step, click "Customize Settings", and save the new VM with an appropriate name

1. Update the new VM settings: set the number of processors and available memory appropriately (for example, 4 CPUs & 8192 MB of memory), in "Advanced" check "Disable Side Channel Mitigations", and finally in "Hard Disk", set the disk size appropriately (50GB should be sufficient, it's sparse)

1. Start the VM

1. Log in as `root`, no password

1. Create a new user `freebsd` with `useradd`, setting the password to the value of `$FREEBSD_PASSWORD`

1. Install `sudo`: `pkg install sudo`

1. Give `freebsd` sudo privileges by creating a file at `/usr/local/etc/sudoers.d/90-freebsd`, containing `freebsd ALL=(ALL) ALL`

1. Start a one-off SSHD service with `service sshd onestart`

1. On the local controller, you can now run `ansible-playbook freebsd-vm-bootstrap.yaml` to finish the FreeBSD bootstrap

1. Run `ansible-playbook freebsd-vm.yaml` to complete provisioning

## How to provision a Proxmox cluster

Set the appropriate environment variables: `PROXMOX_USERNAME`, `PROXMOX_PASSWORD`, `PROXMOX_HOST1`.

Then run:

``` shell
ansible-playbook proxmox-cluster.yaml
```
