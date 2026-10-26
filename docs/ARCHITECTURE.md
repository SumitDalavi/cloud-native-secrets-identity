# Architecture: Cloud-Native Secrets & Identity
> Maturity: Lab / Reference Implementation

## System Diagram
The following Mermaid.js sequence diagram maps the core workflow and interactions:

```mermaid
sequenceDiagram
    Pod->>Vault: K8s ServiceAccount Token
Vault->>Vault: Validate with K8s API
Vault-->>Pod: Vault Token
Pod->>Vault: Read Secret
```


## The Problem with Static Credentials
Historically, CI/CD pipelines required a `client_secret` stored in GitHub Actions to authenticate to Azure/AWS. If that secret leaked, attackers had persistent access to the cloud environment. Similarly, Kubernetes pods required `secrets` mounted into them containing database passwords. These secrets were often checked into Git repositories, leading to massive breaches.

## The Zero-Trust Identity Architecture

### 1. GitHub Actions OIDC (OpenID Connect)
Instead of storing an Azure password in GitHub, we configure an Azure App Registration to trust GitHub's OIDC provider. When a GitHub Action runs, it requests a JWT (JSON Web Token) from GitHub, which includes cryptographic proof of the repository name and branch. The Action presents this token to Azure. Azure verifies the signature, sees that it's from the trusted `main` branch of `my-org/my-repo`, and grants a temporary access token valid for 1 hour. **No secrets to rotate, no secrets to leak.**

### 2. Azure Workload Identity for AKS
Similarly, pods inside Kubernetes should not have hardcoded credentials to access Azure Key Vault. Using Azure Workload Identity, a Kubernetes `ServiceAccount` is federated to an Azure Managed Identity. When the External Secrets Operator pod starts, it requests an Azure token using its Service Account identity.

### 3. External Secrets Operator (ESO)
ESO acts as a bridge. It uses its Workload Identity to connect to Azure Key Vault, fetches the requested secrets (like database passwords), and dynamically writes them into the Kubernetes cluster as native `Secret` objects. Applications simply mount these K8s Secrets as normal. If the DB password changes in Key Vault, ESO automatically rotates the K8s Secret within the configured `refreshInterval`.

## Progressive Credential Loading & Production Architecture (v0.2.0)

This service implements the **Progressive Credential Loading (PCL)** pattern, decoupling development speed from external infrastructure provisioning:

```mermaid
graph LR
    Env[Environment Credentials] -->|Detect Keys & URLs| Detector[Credential Detector]
    Detector -->|No Credentials / Missing| Mock[Mock Mode Factory]
    Detector -->|Valid Credentials Present| Live[Live Provider Factory]
    Mock --> Runtime[Application Core & /health]
    Live --> Runtime
```

### Core Architecture Components
1. **Mode Detection Singleton:** Inspects environment configuration at boot time without hard crashes on missing secrets.
2. **Dual-Mode Factory Wrappers:**
   - **Storage / Cache:** In-process maps or SQLite `:memory:` transparently promote to managed Redis or PostgreSQL when connection strings are supplied.
   - **AI Providers:** Deterministic heuristic generators and local embeddings transparently promote to live OpenAI, Anthropic, or Gemini API clients.
3. **Hot-Reload & Dynamic TLS:** File watchers monitor mounted volume paths (Kubernetes ConfigMaps and Secrets) to update certificates and limit configs atomically without process restarts.
4. **Health & Observability:** The `/health` endpoint exposes real-time runtime mode metadata (`mock` vs `live`) across all backing adapters.

## Declarative GitOps & Multi-Cluster Deployment Architecture (v0.2.1)

This service participates in the portfolio-wide **ArgoCD Hub-and-Spoke GitOps continuous delivery catalog**:

```mermaid
graph TD
    Hub[GitOps Hub: multi-cluster-gitops-promotion] -->|AppSet Matrix: dev| DevCluster[Dev Cluster: kubernetes.default]
    Hub -->|AppSet Matrix: staging| StagingCluster[Staging Cluster: staging-k8s:6443]
    Hub -->|AppSet Matrix: prod| ProdCluster[Prod Cluster: prod-k8s:6443]
    
    subgraph WorkloadRepo["Workload Repo: cloud-native-secrets-identity"]
        Base[deploy/k8s/base] --> DevOverlay[deploy/k8s/overlays/dev]
        Base --> StagingOverlay[deploy/k8s/overlays/staging]
        Base --> ProdOverlay[deploy/k8s/overlays/prod]
    end
    
    DevOverlay -.->|Continuous Reconciliation| DevCluster
    StagingOverlay -.->|Continuous Reconciliation| StagingCluster
    ProdOverlay -.->|Gated PR Promotion| ProdCluster
```

### GitOps Topology & Separation of Concerns
1. **Base Manifests (`deploy/k8s/base`):** Declares non-root PodSecurity standards (`runAsUser: 10001`, `drop: [ALL]`, `readOnlyRootFilesystem: true`), readiness/liveness HTTP probes, and CPU/memory requests and limits without hardcoding namespace.
2. **Environment Overlays (`deploy/k8s/overlays/`):**
   - `dev/`: 1 replica, `300m/256Mi` limit, automated drift self-healing.
   - `staging/`: 2 replicas, `500m/512Mi` limit, automated drift self-healing.
   - `prod/`: 3 replicas, `1000m/1Gi` limit, gated pull-request review.
3. **ArgoCD Declarations (`deploy/argocd/`):** Houses standalone `Application` CRDs (`application.yaml`, `application-dev.yaml`, `application-prod.yaml`) and values overrides for OCI Helm and Kustomize reconciliation.
