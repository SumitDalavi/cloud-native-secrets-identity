# Vault policy for workload identity access
# Applied to the Kubernetes auth role mapped to the application service account

path "secret/data/app/*" {
  capabilities = ["read", "list"]
}

path "database/creds/app-role" {
  capabilities = ["read"]
}

path "pki/issue/app-cert" {
  capabilities = ["create", "update"]
}

path "sys/leases/renew" {
  capabilities = ["create"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}
