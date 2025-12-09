#!/bin/bash

# Script to uninstall Dapr from EKS cluster
# Usage: ./uninstall-dapr.sh

set -e

echo "🗑️  Uninstalling Dapr from EKS..."
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Uninstall Dapr using Helm
echo "1️⃣  Uninstalling Dapr Helm release..."
if helm list -n dapr-system 2>/dev/null | grep -q dapr; then
    helm uninstall dapr --namespace dapr-system
    echo "  ✓ Helm release uninstalled"
else
    echo "  ⚠️  Dapr Helm release not found, skipping..."
fi

# Delete Dapr CRDs
echo ""
echo "2️⃣  Deleting Dapr CRDs..."
kubectl delete crd -l app.kubernetes.io/part-of=dapr --ignore-not-found=true

echo "  ✓ Dapr CRDs deleted"

# Delete dapr-system namespace
echo ""
echo "3️⃣  Deleting dapr-system namespace..."
if kubectl get namespace dapr-system &> /dev/null; then
    kubectl delete namespace dapr-system --timeout=60s
    echo "  ✓ Namespace deleted"
else
    echo "  ⚠️  dapr-system namespace not found, skipping..."
fi

# Verify cleanup
echo ""
echo "🔍 Verifying cleanup..."
REMAINING_CRDS=$(kubectl get crd -l app.kubernetes.io/part-of=dapr 2>/dev/null | wc -l)
if [ "$REMAINING_CRDS" -gt 0 ]; then
    echo "  ⚠️  Warning: Some Dapr CRDs still exist"
    kubectl get crd -l app.kubernetes.io/part-of=dapr
else
    echo "  ✓ All Dapr CRDs removed"
fi

if kubectl get namespace dapr-system &> /dev/null; then
    echo "  ⚠️  Warning: dapr-system namespace still exists"
else
    echo "  ✓ dapr-system namespace removed"
fi

echo ""
echo "✅ Dapr uninstalled successfully!"
echo ""
echo "To reinstall Dapr, run: bash scripts/install-dapr.sh"
