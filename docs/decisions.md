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
