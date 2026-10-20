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


---

## Release Runbook

### Release Trigger
Tag push matching `v*.*.*` (e.g., `v0.1.0`).

### Automated Pipeline Stages
1. **Quality & Validation Gate:** Validates policy syntax, manifest schemas, and configuration integrity.
2. **Distribution Packaging:** Bundles clean production manifests into `cloud-native-secrets-identity-<tag>.tar.gz` and calculates SHA256 checksums.
3. **Syft Source SBOM:** Generates `sbom.spdx.json` adhering to SPDX 2.3 standard.
4. **GitHub Release:** Publishes release assets and release notes.

### Verification
```bash
gh release view v0.1.0 --repo SumitDalavi/cloud-native-secrets-identity
gh release download v0.1.0 --repo SumitDalavi/cloud-native-secrets-identity --pattern "checksums.txt"
```

### Failure Modes & Remediation
- **Linter / Test Failure:** Inspect policy syntax, configurations, or module arguments locally before tagging.
- **Checksum Mismatch:** Ensure file was completely downloaded without network truncation.
