# Bootstrap Secrets

Generate & apply the Vault bootstrap secret via the 1Password CLI:

```shell
kubectl create namespace external-secrets -o yaml --dry-run=client | kubectl apply -f -
# Vault token for external secrets service. Generate with:
# vault token create -display-name="External Secrets Token" -role=secretreader
kubectl create secret generic --namespace external-secrets external-secrets-secret \
--from-literal=vault-token=(op read "op://Outland/Vault Outland/external-secrets-token") \
-o yaml --dry-run=client | kubectl apply -f -
```
