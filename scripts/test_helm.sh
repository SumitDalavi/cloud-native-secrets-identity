#!/bin/bash
set -e

echo "Linting Helm chart..."
helm lint helm/

echo "Templating Helm chart to verify syntax..."
helm template myapp helm/ > /dev/null

echo "✅ Helm chart is valid!"
