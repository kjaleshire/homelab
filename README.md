# Homelab, VM & Localhost Provisioning

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
ssh-copy-id -i ~/.ssh/id_ed25519.pub $KALI_USERNAME@$KALI_HOST
```

Or if using 1Password as the SSH agent (public key auth temporarily disabled):

```shell
# $KEY_NAME being the name of the key in the password manager
# host has bash shell
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no $KALI_USERNAME@$KALI_HOST "mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; sed -i /$KEY_NAME\$/d ~/.ssh/authorized_keys; echo $(ssh-add -L | grep "$KEY_NAME\$") >> ~/.ssh/authorized_keys"

# host has fish shell
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no $KALI_USERNAME@$KALI_HOST "mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; sed -i /$KEY_NAME\\\$/d ~/.ssh/authorized_keys; echo $(ssh-add -L | grep $KEY_NAME\$) >> ~/.ssh/authorized_keys"
```

Next copy the VM-special private/public keypair so certain private repositories can be cloned:

```shell
# $VM_KEY_NAME being the name of the special vm-specific keypair.
scp ~/Downloads/id_ed25519 $KALI_USERNAME@$KALI_HOST:/home/kali/.ssh/id_ed25519.key
ssh $KALI_USERNAME@$KALI_HOST "chmod 0600 ~/.ssh/id_ed25519.key; echo $(ssh-add -L | grep $VM_KEY_NAME\$) > ~/.ssh/id_ed25519.key.pub"
```

Now you can run the provisioner playbooks:

``` shell
ansible-playbook debian-vm.yaml
# OR
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

## How to provision a single-node k3s server

### (After OS Installation)

1. Activate wi-fi if necessary.

1. Install sudo and add user.

1. Copy the machine-specific private & public keys to the primary user's `.ssh` directory.

1. Set the private key's permissions to `0400`.

1. Copy the provisioner's public key to `~/.ssh/authorized_keys`.

1. Create and mount external storage at `/data` as described [here](https://computingforgeeks.com/encrypt-ubuntu-debian-disk-partition-using-cryptsetup/) and [here](https://daenney.github.io/2021/01/11/systemd-encrypted-filesystems/)

1. Set the environment variables `OUTLAND_{HOST,USERNAME,PASSWORD}`.

1. Run `ansible-playbook outland.yaml`.

1. Follow the instructions in [`kubernetes/README.md`](kubernetes/README.md) to bootstrap the cluster.

### If hosting behind a router (self-signed certificates)

1. Create self-signed server certificate & key for `*.flight.kja.us`, Instructions [here](https://www.flatcar.org/docs/latest/setup/security/generate-self-signed-certificates/).

1. Check all the Ingresses to make sure they're using the right self-signed CA `ClusterIssuer`.

1. Import the CA certificate into Firefox as a trusted certificate authority.

1. Bootstrap the cluster.


## How to provision Ubuntu in WSL

### In Windows

1. Install WSL with (default) Ubuntu distribution

1. Install [piperelay](https://github.com/jstarks/npiperelay).

1. Make sure SSH agent is enabled in 1Password in Advanced settings.

### In Ubuntu on WSL

1. Ensure `npiperelay.exe` is in the PATH and runnable.

1. Copy the intended SSH public key to `~/.ssh/id_ed25519` (without `.pub` at the end) and into `~/.ssh/authorized_keys`.

1. In order to forward the ssh-agent connection to Windows, copy this snippet into the end of `.bashrc` and source it:

```shell
# Configure ssh forwarding
export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
# need `ps -ww` to get non-truncated command for matching
# use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
ALREADY_RUNNING=$(ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"; echo $?)
if [[ $ALREADY_RUNNING != "0" ]]; then
    if [[ -S $SSH_AUTH_SOCK ]]; then
        # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
        echo "removing previous socket..."
        rm $SSH_AUTH_SOCK
    fi
    echo "Starting SSH-Agent relay..."
    # setsid to force new session to keep running
    # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
fi
```

1. Run `ssh-add -l` to check that the connection is working. This should list all available keys in 1Password.

1. In `~/.ssh/config`, add this snippet to force all connections use the ssh-agent connection:

```shell
Host *
  IdentityAgent "~/.ssh/agent.sock"
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

1. Install Python 3: `sudo apt install python3 python3-pip`

1. Use pip to install Ansible: `pip3 install ansible`

1. Set the `UBUNTU_USERNAME` and `UBUNTU_PASSWORD` environment variables appropriately.

1. Start the SSH service: `service start ssh`

1. You should now be able to run `ansible-playbook ubuntu-wsl.yaml` to finish the provisioning process.
