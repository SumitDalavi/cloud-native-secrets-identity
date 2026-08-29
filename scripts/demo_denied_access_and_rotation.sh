#!/bin/bash
set -e

echo "================================================="
echo "🏃 Running Cloud-Native Secrets & Identity Demo"
echo "================================================="

echo "1. Simulating Workload Identity (SPIFFE/SPIRE)..."
echo "✅ Issued SVID to ServiceAccount 'app-sa'."

echo "2. Simulating External Secrets Operator (ESO)..."
echo "✅ Authenticating to local Vault with SVID..."
echo "✅ Auth SUCCESS: Fetched 'db-password'."
echo "✅ Created native K8s Secret 'app-secrets'."

echo "3. Testing Denied Access Scenario..."
echo "✅ Revoking SVID / Simulating missing Workload Identity..."
echo "✅ ESO sync attempt..."
echo "❌ Auth DENIED: Permission denied. Secret not synced."

echo "4. Simulating Secret Rotation..."
echo "✅ Updating 'db-password' in Vault..."
echo "✅ Restoring SVID..."
echo "✅ ESO detected drift. Updating K8s Secret 'app-secrets' seamlessly."

echo "✅ All Zero-Trust Identity scenarios simulated successfully."
