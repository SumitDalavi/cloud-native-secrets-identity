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
