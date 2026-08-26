#!/usr/bin/env bash
# Configure Vault Kubernetes authentication method
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
K8S_HOST="${K8S_HOST:-https://kubernetes.default.svc}"
NAMESPACE="${APP_NAMESPACE:-production}"
SERVICE_ACCOUNT="${APP_SA:-backend-sa}"
ROLE_NAME="${VAULT_ROLE:-app-role}"

echo "[vault-setup] Enabling Kubernetes auth..."
vault auth enable kubernetes 2>/dev/null || true

echo "[vault-setup] Configuring K8s auth backend..."
vault write auth/kubernetes/config     kubernetes_host="$K8S_HOST"     kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt     token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

echo "[vault-setup] Writing app policy..."
vault policy write app-policy vault/vault-policy.hcl

echo "[vault-setup] Creating role: $ROLE_NAME"
vault write "auth/kubernetes/role/$ROLE_NAME"     bound_service_account_names="$SERVICE_ACCOUNT"     bound_service_account_namespaces="$NAMESPACE"     policies="app-policy"     ttl=1h

echo "[vault-setup] Storing sample secrets..."
vault kv put secret/app/config     db_password="super-secret-db-pass"     api_key="prod-api-key-$(openssl rand -hex 8)"

echo "[vault-setup] Done."
