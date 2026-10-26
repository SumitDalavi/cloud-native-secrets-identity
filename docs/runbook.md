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

## Operations & Diagnostics Guide (v0.2.0)

### Mode Verification & Diagnostics
Inspect the active execution mode and backing provider status via the health endpoint:
```bash
# Check runtime mode and adapter status
curl -s http://localhost:8080/health | jq .
# Expected output when running without keys:
# {"status": "ok", "mode": {"database": "mock", "ai": "mock", "cache": "mock"}}
```

### Running in Mock Mode (Tier 1)
Start the service with zero external dependencies:
```bash
cp .env.example .env
# Start service without modifying .env
npm start || python main.py || go run .
```

### Running with Live Credentials (Tier 2 / 3)
Populate target credentials in `.env` and restart:
```bash
# Verify live upgrade via health check
curl -s http://localhost:8080/health | jq .mode
```

### Pulling Pre-Built OCI Image
```bash
docker pull ghcr.io/sumitdalavi/cloud-native-secrets-identity:v0.2.0
docker run -d -p 8080:8080 --env-file .env ghcr.io/sumitdalavi/cloud-native-secrets-identity:v0.2.0
```

## GitOps Deployment & Multi-Cluster Operations (v0.2.1)

### Local Overlay Validation
Validate environment-specific manifests offline with `kubectl kustomize`:
```bash
# Validate Dev Overlay
kubectl kustomize deploy/k8s/overlays/dev

# Validate Staging Overlay
kubectl kustomize deploy/k8s/overlays/staging

# Validate Production Overlay
kubectl kustomize deploy/k8s/overlays/prod
```

### ArgoCD Standalone Application Deployment
Apply the standalone declarative ArgoCD application to your local or target cluster:
```bash
# Deploy default staging application
kubectl apply -f deploy/argocd/application.yaml

# Deploy environment-specific applications
kubectl apply -f deploy/argocd/application-dev.yaml
kubectl apply -f deploy/argocd/application-prod.yaml
```
