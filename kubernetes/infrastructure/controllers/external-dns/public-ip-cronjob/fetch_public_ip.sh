#!/bin/sh
set -euo pipefail

# MIKROTIK_USERNAME <- set in secret
# MIKROTIK_PASSWORD <- set in secret
: "${WAN_IF:=ether1}"
# DOMAIN_NAME <- set in job config
POD_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
API_GROUP=externaldns.k8s.io
API_VERSION=v1alpha1
DNS_ENDPOINT_NAME=outland-kja-us-dns-record
: "${CONFIGMAP_NAME:=current-public-ip}"
APISERVER=$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT_HTTPS


echo "=> Fetching WAN IP from router"
WAN_IP=$(curl -s -k -u $MIKROTIK_USERNAME:$MIKROTIK_PASSWORD https://$ROUTER_API_IP:$ROUTER_API_PORT/rest/ip/address | jq --arg wan_if "$WAN_IF" -r '.[] | select(.interface == $wan_if) | .address | split("/")[0]')
echo "=> Got IP $WAN_IP"

CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

echo "=> Checking for existing DNSEndpoint \`$DNS_ENDPOINT_NAME\`"
EXISTING_DNS_ENDPOINT=$(curl -s --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" "https://$APISERVER/apis/$API_GROUP/$API_VERSION/namespaces/$POD_NAMESPACE/dnsendpoints/$DNS_ENDPOINT_NAME")

if [ "$(echo $EXISTING_DNS_ENDPOINT | jq .code)" == "404" ]; then
    echo "=> Existing DNSEndpoint not found, creating it"
    jq -c -n --arg wan_ip "$WAN_IP" --arg domain_name "$DOMAIN_NAME" --arg dns_endpoint_name "$DNS_ENDPOINT_NAME" --arg namespace "$POD_NAMESPACE" '{
        "apiVersion": "externaldns.k8s.io\/v1alpha1",
        "kind": "DNSEndpoint",
        "metadata": {
            "name": $dns_endpoint_name,
            "namespace": $namespace
        },
        "spec": {
            "endpoints": [
                {
                    "dnsName": $domain_name,
                    "recordTTL": 600,
                    "recordType": "A",
                    "targets": [$wan_ip]
                }
            ]
        }
    }' | curl -s --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" -X POST "https://$APISERVER/apis/$API_GROUP/$API_VERSION/namespaces/$POD_NAMESPACE/dnsendpoints/$DNS_ENDPOINT_NAME" -H "Content-type: application/json" -d @-
else
    echo "=> Existing DNSEndpoint found, check for matching IP address & domain"
    if [ "$(echo $EXISTING_DNS_ENDPOINT | jq -r .spec.endpoints[0].dnsName)" == "$DOMAIN_NAME" ] && [ "$(echo $EXISTING_DNS_ENDPOINT | jq -r .spec.endpoints[0].targets[0])" == "$WAN_IP" ]; then
        echo "=> IP address and domain match, nothing to do"
    else
        echo "=> IP address or domain needs updating, patching"
        jq -c -n --arg wan_ip "$WAN_IP" --arg domain_name "$DOMAIN_NAME" '{
            "spec": {
                "endpoints": [
                    {
                        "dnsName": $domain_name,
                        "recordTTL": 600,
                        "recordType": "A",
                        "targets": [$wan_ip]
                    }
                ]
            }
        }' | curl -s --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" -X PATCH "https://$APISERVER/apis/$API_GROUP/$API_VERSION/namespaces/$POD_NAMESPACE/dnsendpoints/$DNS_ENDPOINT_NAME" -H "Content-type: application/merge-patch+json" -d @-
        # Notify via Telegram of updated IP address
        OLD_IP="$(echo $EXISTING_DNS_ENDPOINT | jq -r .spec.endpoints[0].targets[0])"
        MESSAGE="The DNSEndpoint IP address has been updated from $OLD_IP to $WAN_IP."
        curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE" > /dev/null
    fi
fi

echo "=> Finished DNSEndpoint handling"

echo "=> Checking for existing ConfigMap \`$CONFIGMAP_NAME\`"

EXISTING_CONFIGMAP=$(curl -s --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" "https://$APISERVER/api/v1/namespaces/$POD_NAMESPACE/configmaps/$CONFIGMAP_NAME")

if [ "$(echo $EXISTING_CONFIGMAP | jq .code)" == "404" ]; then
    echo "=> Existing ConfigMap not found, creating"
    jq -c -n --arg wan_ip "$WAN_IP" --arg configmap_name "$CONFIGMAP_NAME" --arg namespace "$POD_NAMESPACE" '{
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {
            "name": $configmap_name,
            "namespace": $namespace
        },
        "data": {
            "wanIp": $wan_ip
        }
    }' | curl -s --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" -X POST "https://$APISERVER/api/v1/namespaces/$POD_NAMESPACE/configmaps" -H "Content-type: application/json" -d @-
else
    echo "=> Existing ConfigMap found, check for matching IP address"
    if [ "$(echo $EXISTING_CONFIGMAP | jq -r .data.wanIp)" == "$WAN_IP" ]; then
        echo "=> IP address matches, nothing to do"
    else
        echo "=> IP address needs updating, patching"
        jq -c -n --arg wan_ip "$WAN_IP" '{
            "data": {
                "wanIp": $wan_ip
            }
        }' | curl -s --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" -X PATCH "https://$APISERVER/api/v1/namespaces/$POD_NAMESPACE/configmaps/$CONFIGMAP_NAME" -H "Content-type: application/merge-patch+json" -d @-
    fi
fi

echo
echo "=> Finished ConfigMap handling"

echo "=> Finished"
