#!/bin/sh

# env.sh

# Change the contents of this output to get the environment variables
# of interest. The output must be valid JSON, with strings for both
# keys and values.
cat <<EOF
{
    "proxmox_username": "$PROXMOX_USERNAME",
    "proxmox_password": "$PROXMOX_PASSWORD",
    "proxmox_host": "$PROXMOX_HOST1",
    "proxmox_host_node": "$PROXMOX_HOST1_NODE"
}
EOF
