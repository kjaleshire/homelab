# Terraform

This directory is primarily for provisioning the Mikrotik router. Terraform requires these environment variables:

```fish
set -xg MIKROTIK_HOST=[https|api|apis]://192.168.1.1
set -xg MIKROTIK_USER="tf"
set -xg MIKROTIK_PASSWORD="abcd1234"
set -xg MIKROTIK_INSECURE="true" # if using the Terraform-provisioned self-signed cert
set -xg TF_VAR_outland_ethernet_mac="AA:BB:CC:DD:EE:FF"
set -xg TF_VAR_wan_ip="1.1.1.1"
```

On a factory-configured router TLS is not available, so protocol `api://` must be used. Once the `api-ssl` & `web-ssl` services are enabled and a certificate has been provisioned, you can switch off the insecure `api` & `web` services. The insecure services are not included in the Terraform config because they would be disabled during bootstap and you may lock yourself out. So,

*BE CAREFUL TO ORDER YOUR OPERATIONS CORRECTLY*

Otherwise the router will need to be [factory-reset](https://wiki.mikrotik.com/wiki/Manual:Reset) to regain access.
