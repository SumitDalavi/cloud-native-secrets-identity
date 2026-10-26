# Changelog

## [0.2.1] - 2026-10-27
### Added
- **Declarative GitOps Deployment:** Standardized `deploy/k8s/` base and environment overlays (`dev`, `staging`, `prod`) adhering to CNCF restricted pod security standards (non-root UID 10001, dropped capabilities, read-only rootfs).
- **ArgoCD Continuous Delivery:** Added declarative ArgoCD application manifests (`deploy/argocd/application.yaml`, `application-dev.yaml`, `application-prod.yaml`, `values-override.yaml`).
- **Multi-Cluster Orchestration:** Integrated with `multi-cluster-gitops-promotion` catalog for automated zero-drift self-healing in development/staging and gated PR promotion in production.

## [0.2.0] - 2026-10-20
### Added
- **Progressive Credential Loading (PCL):** Dynamic auto-promotion between zero-dependency mock fallbacks and live production backends based on environment credentials.
- **Dual Distribution:** Universal OCI container publishing to GitHub Container Registry (`ghcr.io/sumitdalavi/cloud-native-secrets-identity`) and Helm OCI registries alongside GitHub Release tarballs.
- **Health Reporting:** Exposed `/health` or `/healthz` endpoint with PCL status detection (`mock` vs `live`).
- **Dynamic Reloading:** Support for atomic ConfigMap / secret reloads without requiring pod restarts.
- **Supply Chain Security:** Trivy vulnerability scan gates and SPDX JSON SBOM (`sbom.spdx.json`) generation for all releases.

## [0.1.0] - 2026-10-18
### Added
- Initial baseline service implementation, unit test suites, and CI workflows.

## [2026-08-29] — Phase 2 Evidence
### Added
- Created `scripts/demo_denied_access_and_rotation.sh` to demonstrate OIDC/ESO/SPIFFE denied-access and rotation scenario.
- Standardized documentation (`runbook.md`, `decisions.md`, `ARCHITECTURE.md`).
- Added maturity badge and mock boundaries to `README.md`.


---

## [v0.1.0] — 2026-10-20
### Added
- **Release Automation:** Added `.github/workflows/release.yml` with automated catalog validation, tarball packaging, and SPDX SBOM generation.
- **Supply Chain Security:** Generated Anchore Syft SPDX JSON SBOM and cryptographic SHA-256 checksums.
- **Release Verification:** Added release verification documentation, badges, and operational runbook.
