# Cloud-Native Secrets & Identity Platform 🔐☁️

[![CI Pipeline](https://github.com/SumitDalavi/cloud-native-secrets-identity/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/SumitDalavi/cloud-native-secrets-identity/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/SumitDalavi/cloud-native-secrets-identity?color=0969da&label=release&logo=github)](https://github.com/SumitDalavi/cloud-native-secrets-identity/releases)
[![Release Workflow](https://github.com/SumitDalavi/cloud-native-secrets-identity/actions/workflows/release.yml/badge.svg)](https://github.com/SumitDalavi/cloud-native-secrets-identity/actions/workflows/release.yml)
[![Helm OCI](https://img.shields.io/badge/helm%20chart-0.2.0-0f1689?logo=helm&logoColor=white)](https://github.com/SumitDalavi/cloud-native-secrets-identity/pkgs/container/cloud-native-secrets-identity)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io)
[![SBOM](https://img.shields.io/badge/SBOM-SPDX%202.3-blueviolet?logo=spdx)](https://github.com/SumitDalavi/cloud-native-secrets-identity/releases/tag/v0.2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

> **Maturity:** Lab / Reference Implementation
> _A zero-trust identity architecture eliminating long-lived credentials by integrating Azure Key Vault, External Secrets Operator (ESO), and GitHub Actions OIDC._

> **⚡ Progressive Execution:** Supports zero-config local emulation with Vault backend (Tier 1) and promotes to live Azure Key Vault & Workload Identity when credentials are provided (Tier 2/3). See [Execution Tiers](#-progressive-credential-loading--execution-tiers).

## The Problem

Managing secrets in Kubernetes usually looks like this: a developer manually base64-encodes a database password, pastes it into a `Secret` YAML, and checks it into a private Git repo, or relies on brittle pipeline scripts to inject them. Worse, CI/CD pipelines use long-lived `client_secret` strings to authenticate to cloud providers, creating massive blast radiuses if a repository is compromised.

## The Solution

This architecture provides a modern, identity-first approach:
1. **GitHub Actions OIDC**: CI/CD pipelines do not store cloud credentials. They use ephemeral OIDC tokens to prove their identity to Azure, which grants them short-lived access to push images.
2. **Workload Identity**: Kubernetes pods do not have hardcoded credentials. They are assigned an Azure Managed Identity mapped to their Kubernetes Service Account.
3. **External Secrets Operator (ESO)**: ESO runs in the cluster, authenticates via Workload Identity, fetches secrets from Azure Key Vault, and syncs them into native K8s `Secrets`. If the secret in Key Vault rotates, ESO automatically rotates it in the cluster without downtime.

## Why This Over the Obvious Alternative

The alternative is storing secrets in a vault (like HashiCorp Vault) but injecting them at runtime via mutating webhooks (the Vault Agent Injector). While popular, that pattern hides the secret from the Kubernetes API entirely, breaking many third-party tools (like Helm charts) that expect standard K8s `Secret` objects to exist. ESO bridges the gap: it keeps the source of truth in Key Vault, but manifests them as native K8s Secrets for maximum compatibility.

## 🛠️ Tech Stack

- **Secrets Management**: Azure Key Vault
- **Kubernetes Integration**: External Secrets Operator (ESO)
- **Authentication**: Azure Workload Identity, GitHub Actions OIDC

## Decision Log

| Decision | Rationale |
|----------|-----------|
| External Secrets Operator over CSI Driver | The Secrets Store CSI driver requires modifying pod volumes. ESO creates native K8s `Secret` objects, meaning developers don't have to change their deployment YAMLs. |
| GitHub Actions OIDC | Eliminates the need to rotate Service Principal secrets manually. Trust is established cryptographically between GitHub and Entra ID. |

## 📁 Project Structure

```
├── eso-configs/
│   ├── cluster-secret-store.yaml  # Configures ESO to authenticate to Azure KV via Workload Identity
│   └── external-secret.yaml       # Defines which KV secrets to sync into K8s
├── github-actions/
│   └── oidc-azure-auth.yaml       # CI pipeline demonstrating OIDC cloud authentication
├── docs/ARCHITECTURE.md
└── README.md
```

## 📋 Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes CLI |
| [kind](https://kind.sigs.k8s.io/) or [minikube](https://minikube.sigs.k8s.io/) | Latest | Local K8s cluster |
| [Helm](https://helm.sh/) | >= 3.x | Package manager |

## 🚀 Step-by-Step Setup

### Option A: Local Cluster (kind)

```bash
# 1. Clone the repository
git clone https://github.com/SumitDalavi/cloud-native-secrets-identity.git
cd cloud-native-secrets-identity

# 2. Create a local cluster
kind create cluster --name secrets-lab

# 3. Install External Secrets Operator (ESO)
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace

# 4. Wait for ESO to be ready
kubectl wait --for=condition=available deployment/external-secrets \
  --namespace external-secrets --timeout=120s

# 5. Apply the ClusterSecretStore configuration
kubectl apply -f eso-configs/cluster-secret-store.yaml

# 6. Apply the ExternalSecret resource
kubectl apply -f eso-configs/external-secret.yaml
```

### Option B: Existing Cloud Cluster

```bash
kubectl cluster-info
# Follow steps 3-6 from Option A
# For cloud providers, configure the SecretStore with real credentials
```

## 🧪 Usage & Demo

### Step 1: Verify ESO is running
```bash
kubectl get pods -n external-secrets
```

### Step 2: Check the ClusterSecretStore status
```bash
kubectl get clustersecretstores
kubectl describe clustersecretstore vault-backend  # or your store name
```

### Step 3: Observe ExternalSecret sync
```bash
# Check the ExternalSecret status
kubectl get externalsecrets
kubectl describe externalsecret app-secrets  # or your secret name

# Verify the Kubernetes Secret was created
kubectl get secrets
kubectl get secret app-secrets -o jsonpath='{.data}' | jq .
```

### Step 4: GitHub Actions OIDC (Workload Identity Federation)
```bash
# Review the OIDC workflow for Azure
cat github-actions/oidc-azure-auth.yaml
# This demonstrates passwordless auth from GitHub Actions to Azure
```

## ✅ Verification

| Check | Command | Expected |
|-------|---------|----------|
| ESO running | `kubectl get pods -n external-secrets` | Pods running |
| Store valid | `kubectl get clustersecretstores` | Valid status |
| Secret synced | `kubectl get externalsecrets` | SecretSynced |
| K8s Secret created | `kubectl get secrets` | app-secrets present |

```bash
# Cleanup
kind delete cluster --name secrets-lab
```

## 👨‍💻 Author

**Sumit Dalavi** — Senior DevSecOps / Platform Engineer
[GitHub](https://github.com/SumitDalavi) | [LinkedIn](https://in.linkedin.com/in/sumit-dalavi-762838129)

---

*Built with a focus on robust patterns, not toy demos.*

## 🚀 Progressive Credential Loading & Execution Tiers

This project implements **Progressive Credential Loading (PCL)**, allowing it to run immediately out-of-the-box without external dependencies while seamlessly upgrading as credentials are provided.

### Tier 1: Zero-Config Mock Mode (Default)
Ideal for CI, testing, and rapid local evaluation.
- **Execution:** Run with default configuration (`cp .env.example .env`). Zero API keys, databases, or cloud credentials required.
- **Fallback Behavior:** In-memory caches, deterministic offline heuristics, mock vector embeddings, and local mock storage are automatically used.
- **Health Verification:** Endpoints report `{"mode": "mock"}` for unconfigured dependencies.

### Tier 2: Local Development with Live Services
Connect specific external services while keeping others mocked.
- **Execution:** Provide credentials in `.env` for the services you want active (e.g., `VAULT_ADDR, VAULT_TOKEN, VAULT_ROLE`).
- **Progressive Upgrade:** The runtime inspects environment variables on boot and dynamically promotes only configured modules to live mode.
- **Safe Fallback:** Any missing credentials automatically remain on mock fallbacks with no crashes or missing service errors.

### Tier 3: Production Hardened
Enterprise deployment with production-grade backends, security scans, and container distributions.
- **Helm OCI Chart:** Deploy directly via Helm without adding a chart repository:
  ```bash
  helm install cloud-native-secrets-identity oci://ghcr.io/sumitdalavi/cloud-native-secrets-identity --version 0.2.0
  ```
- **Kubernetes:** Injects secrets directly via Helm values or External Secrets Operator.
- **Release Verification:** Signed artifacts, checksums, and SPDX SBOM available on [GitHub Releases](https://github.com/SumitDalavi/cloud-native-secrets-identity/releases).

## 📚 Documentation

- [Architecture](docs/ARCHITECTURE.md) — System diagram and component details
- [Runbook](docs/runbook.md) — Setup, commands, and expected outputs
- [Decisions](docs/decisions.md) — ADRs for secrets management
- [Changelog](docs/changelog.md) — Change history

## Mock Boundaries (Honest Scope)

| What | Status | Details |
|---|---|---|
| Kubernetes Cluster | **Real** | Uses local `kind` cluster for the demo. |
| External Secrets Operator | **Real** | Helm deployment of actual ESO. |
| Cloud Vault (Azure KV) | **Mocked** | Simulated with local HashiCorp Vault in `dev` mode to avoid cloud costs. |
| Workload Identity (Azure) | **Simulated** | Uses local SPIFFE/SPIRE deployment to emulate identity-based auth. |

## 🔗 Related Projects

- [`secret-sprawl-remediation-bot`](../secret-sprawl-remediation-bot/) — Remediation of exposed secrets compliments zero-trust identity.

## Release & Security Verification

This repository is published as an immutable release catalog under the portfolio release standard:

- **Release Artifacts:** Authenticated distribution bundle (`cloud-native-secrets-identity-v0.2.0.tar.gz`) containing production policies, modules, and manifests.
- **Cryptographic Integrity:** SHA-256 integrity hash provided in `checksums.txt`.
- **Software Bill of Materials (SBOM):** Fully compliant SPDX JSON SBOM (`sbom.spdx.json`) generated by Anchore Syft.

### Verification Commands
```bash
# 1. View Release Metadata
gh release view v0.2.0 --repo SumitDalavi/cloud-native-secrets-identity

# 2. Download Release Assets & Verify SHA256 Checksum
gh release download v0.2.0 --repo SumitDalavi/cloud-native-secrets-identity --pattern "*.tar.gz" --pattern "checksums.txt"
sha256sum -c checksums.txt

# 3. Inspect SPDX SBOM
gh release download v0.2.0 --repo SumitDalavi/cloud-native-secrets-identity --pattern "sbom.spdx.json"
cat sbom.spdx.json | jq .spdxVersion
```
