# Cloud-Native Secrets & Identity Platform 🔐☁️

> A zero-trust identity architecture eliminating long-lived credentials by integrating Azure Key Vault, External Secrets Operator (ESO), and GitHub Actions OIDC.

> **⚠️ PoC Note:** Full ESO setup works on a local `kind` cluster. Azure-specific features (Workload Identity, Key Vault integration) require real Azure credentials.


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

*Built with a focus on production-grade patterns, not toy demos.*