# Runbook — cloud-native-secrets-identity
> Last updated: 2026-08-29

## Quick Start
```bash
# Bring up the cluster and deploy ESO + Vault
kind create cluster --name secrets-lab
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

## Run Tests / Demos
```bash
bash scripts/demo_denied_access_and_rotation.sh
```

## Failure Modes
| Symptom | Cause | Fix |
|---|---|---|
| SecretSyncError | Vault token expired or Workload ID denied | Check SPIRE logs and recreate the access token |
