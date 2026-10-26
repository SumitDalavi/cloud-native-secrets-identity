# Decisions

## ADR-001: Simulating Cloud Vaults Locally
**Date:** 2026-08-29  
**Status:** Accepted

**Context:**  
This lab relies on Azure Key Vault for the OIDC workload identity demonstration, but requires paid cloud resources which are difficult for an open-source portolio demo.

**Decision:**  
We replaced the hard dependency on Azure Key Vault in local tests with a local HashiCorp Vault dev server.

**Consequences:**  
- ✅ Allows anyone to run the full ESO rotation pipeline without cloud credentials.
- ⚠️ Azure-specific features (like Managed Identity token exchange) are approximated by SPIFFE/SPIRE.

## ADR-002: Progressive Credential Loading (PCL) Architecture
- **Context:** Production hardening required live backends (PostgreSQL, Redis, OpenAI, Anthropic), but removing mocks would break CI pipelines and create high developer onboarding friction.
- **Decision:** Implement Progressive Credential Loading. Keep in-memory and local mock heuristics as the default safe baseline, while wrapping external integrations in auto-promoting factory adapters triggered by environment variables.
- **Consequences:** 
  - *Pros:* 100% CI pass rate without requiring external secrets; zero setup friction for new contributors; progressive upgrade to production clusters.
  - *Cons:* Adds lightweight factory abstraction layers and runtime credential detection logic.

## ADR-003: Declarative Multi-Cluster GitOps Packaging with ArgoCD and Kustomize
- **Date:** 2026-10-27
- **Status:** Accepted
- **Context:** Deploying this service across multi-cluster environments (`dev`, `staging`, `prod`) requires a standardized cloud-native packaging format that separates environment-agnostic base specifications from environment-specific resource allocations, replica counts, and security policies without modifying source code or inducing configuration drift.
- **Decision:** Adopt Kustomize overlays under `deploy/k8s/` and declarative ArgoCD `Application` definitions under `deploy/argocd/`.
  1. `deploy/k8s/base`: Declares non-root PodSecurity standards (`runAsUser: 10001`, `drop: [ALL]`, `readOnlyRootFilesystem: true`), probes, and resource constraints without hardcoding namespace.
  2. `deploy/k8s/overlays/{dev,staging,prod}`: Overrides namespace, replica counts, and resources per environment tier.
  3. `deploy/argocd/`: Standalone `Application` CRDs with automated self-healing in `dev`/`staging` and gated PR synchronization in `prod`.
- **Consequences:**
  - *Pros:* Fully declarative, CNCF-compliant, drift-resistant, and natively integrates with the `multi-cluster-gitops-promotion` catalog.
  - *Cons:* Requires maintaining separate overlay directories for each target cluster tier.
