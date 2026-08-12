# Cloud-Native Secrets & Identity Platform 🔐☁️

> A zero-trust identity architecture eliminating long-lived credentials by integrating Azure Key Vault, External Secrets Operator (ESO), and GitHub Actions OIDC.

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

## 👨‍💻 Author

*Built to demonstrate zero-trust identity, credential rotation, and secure supply chains.*
