#!/usr/bin/env bash
# Register SPIFFE workload identities with the SPIRE server
set -euo pipefail

SPIRE_SERVER_SOCKET="${SPIRE_SERVER_SOCKET:-/tmp/spire-server/private/api.sock}"
TRUST_DOMAIN="${TRUST_DOMAIN:-example.org}"
CLUSTER="${CLUSTER:-demo-cluster}"

register() {
    local name="$1" ns="$2" sa="$3"
    local spiffe_id="spiffe://${TRUST_DOMAIN}/ns/${ns}/sa/${sa}"
    echo "Registering: $spiffe_id (${name})"
    /opt/spire/bin/spire-server entry create         -socketPath "$SPIRE_SERVER_SOCKET"         -spiffeID "$spiffe_id"         -parentID "spiffe://${TRUST_DOMAIN}/ns/spire/sa/spire-agent"         -selector "k8s:ns:${ns}"         -selector "k8s:sa:${sa}"         -ttl 3600
}

# Register application workloads
register "app-backend"   "production" "backend-sa"
register "app-frontend"  "production" "frontend-sa"
register "data-pipeline" "production" "pipeline-sa"

echo "All workload identities registered."
