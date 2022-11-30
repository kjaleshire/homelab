## OS Gold Master generation with Packer

_Note: make sure the appropriate environment variables are set beforehand (for example, with `direnv`). See below for an example `.envrc` file._

### How to build the Debian VM image

`cd` into the `debian-vm` directory and run:
```
packer build .
```

### Example `.envrc`
```
export KALI_HOST=192.168.0.2
export KALI_USERNAME=kali
export KALI_PASSWORD=example_kali_password

export DEBIAN_HOST=192.168.0.3
export DEBIAN_USERNAME=debian
export DEBIAN_PASSWORD=example_debian_password

export PROXMOX_HOST1=192.168.0.4
export PROXMOX_HOST1_NODE=example_proxmox_host
export PROXMOX_USERNAME=root
export PROXMOX_PASSWORD=example_proxmox_password
```
