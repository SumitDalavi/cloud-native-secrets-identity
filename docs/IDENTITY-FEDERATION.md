# Workload Identity Federation Architecture

## Components

| Component | Role |
|-----------|------|
| SPIRE Server | Issues SPIFFE SVIDs (X.509 certs) to workloads |
| SPIRE Agent | Runs on each node, attests workload identity |
| Vault | Dynamic secrets engine, K8s auth backend |
| External Secrets Operator | Syncs Vault secrets to K8s Secrets |
| cert-manager | Manages TLS certificates using SPIFFE SVIDs |

## Flow

```
Pod startup
  → kubelet injects service account token
  → SPIRE Agent attests pod identity (k8s_psat)
  → SPIRE Server issues SVID to workload
  → App uses SVID to authenticate to Vault
  → Vault returns short-lived dynamic credentials
  → App uses credentials (DB password, API key, etc.)
  → Credentials auto-rotate every 1h
```

## Zero-Trust Principles Applied

1. **No static secrets** — all credentials are dynamic and short-lived
2. **Workload attestation** — identity is cryptographically proven, not configured
3. **Least privilege** — each workload only accesses its own secret paths
4. **Audit trail** — every secret access logged in Vault audit log
