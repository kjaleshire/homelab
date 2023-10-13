#!/bin/sh
set -euo pipefail

VAULT_ADDR=http://127.0.0.1:8200
SECRET_SHARES=3
SECRET_THRESHOLD=2

sleep 5 # wait a few seconds for Vault to come online

VAULT_HEALTH=$(curl -s $VAULT_ADDR/v1/sys/health)
echo "=> Current Vault status:"
echo $VAULT_HEALTH | jq .

# check if Vault is initialized
if [ "$(echo $VAULT_HEALTH | jq .initialized)" == "false" ]; then
    echo "=> Vault is not initialized, initializing"
    curl -s -XPOST $VAULT_ADDR/v1/sys/init --data "{\"secret_shares\":$SECRET_SHARES,\"secret_threshold\":$SECRET_THRESHOLD}" > /vault/keys/keys.json
    echo "=> Vault initialized"
else
    echo "=> Vault already initialized"
fi

echo "=> Checking Vault seal"
if [ "$(echo $VAULT_HEALTH | jq .sealed)" == "true" ]; then
    echo "=> Vault is sealed, unsealing"
    if [ ! -f /vault/keys/keys.json ]; then
    echo "=> Keys file was not found, stopping"
    exit 1
    fi

    i=0; while [ ${i} -lt $SECRET_THRESHOLD ]; do
    echo "=> Unsealing with key $i"
    KEY=$(cat /vault/keys/keys.json | jq -r .keys[$i])
    curl -s -XPOST $VAULT_ADDR/v1/sys/unseal --data "{\"key\":\"$KEY\"}" | jq .
    i=$(( i + 1 ))
    done

    echo "=> Rechecking Vault seal"
    VAULT_HEALTH=$(curl -s $VAULT_ADDR/v1/sys/health)
    if [ "$(echo $VAULT_HEALTH | jq .sealed)" == "false" ]; then
    echo "=> Vault unsealed"
    else
    echo "=> Vault is still sealed, maybe the unseal threshold is incorrect?"
    exit 1
    fi
else
    echo "=> Vault is already unsealed"
fi

VAULT_TOKEN=$(cat /vault/keys/keys.json | jq -r .root_token)
CURL_OPT="-s -H X-Vault-Token:$VAULT_TOKEN -X POST"

# Perhaps someday do something sophisticated as explained here:
# https://www.hashicorp.com/blog/codifying-vault-policies-and-configuration

echo "=> Checking kv secrets engine"
KV_ENGINE_STATUS=$(curl -s -H X-Vault-Token:$VAULT_TOKEN $VAULT_ADDR/v1/sys/mounts/secret)
if [ "$(echo $KV_ENGINE_STATUS | jq -r .type)" == "kv" ]; then
    echo "=> kv engine already mounted"
else
    echo "=> kv engine not mounted, mounting"
    curl ${CURL_OPT} $VAULT_ADDR/v1/sys/mounts/secret --data '{"type":"kv","options":{"version":"2"}}'
    curl ${CURL_OPT} $VAULT_ADDR/v1/secret/config --data '{"max_versions":3,"cas_required":false,"delete_version_after":"0s"}'
fi

echo "=> Setting policies and roles"
KVREADER_BASE64_POLICY=$(echo 'path "secret/*" { capabilities = ["list", "read"] }' | base64)
curl ${CURL_OPT} $VAULT_ADDR/v1/sys/policies/acl/kvreader --data "{\"policy\":\"$KVREADER_BASE64_POLICY\"}"
curl ${CURL_OPT} $VAULT_ADDR/v1/auth/token/roles/secretreader --data '{"allowed_policies":["kvreader"]}'

echo "=> Final Vault status:"
curl -s $VAULT_ADDR/v1/sys/health | jq .

sleep infinity

exit 0
