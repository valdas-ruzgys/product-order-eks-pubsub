#!/bin/bash

# Script to install Dapr on EKS cluster
# Usage: ./install-dapr.sh

set -e

echo "🎯 Installing Dapr on EKS..."
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed"
    echo ""
    echo "Please install Helm first:"
    echo "  macOS:   brew install helm"
    echo "  Linux:   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo "  Windows: choco install kubernetes-helm"
    echo ""
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured or cluster is not accessible"
    echo "Run: aws eks update-kubeconfig --name microservices-cluster --region <your-region>"
    exit 1
fi

# Add Dapr Helm repository
echo "1️⃣  Adding Dapr Helm repository..."
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

echo "  ✓ Dapr Helm repository added"

# Create dapr-system namespace
echo ""
echo "2️⃣  Creating dapr-system namespace..."
kubectl create namespace dapr-system --dry-run=client -o yaml | kubectl apply -f -

echo "  ✓ Namespace created"

# Install Dapr
echo ""
echo "3️⃣  Installing Dapr (this may take a few minutes)..."
helm upgrade --install dapr dapr/dapr \
    --version=1.13.5 \
    --namespace dapr-system \
    --set global.ha.enabled=false \
    --set global.logAsJson=true \
    --set global.daprControlPlaneOs=linux \
    --set global.daprControlPlaneArch=amd64 \
    --set dapr_placement.replicaCount=1 \
    --set dapr_operator.replicaCount=1 \
    --set dapr_sentry.replicaCount=1 \
    --set dapr_sidecar_injector.replicaCount=1 \
    --set dapr_scheduler.enabled=false \
    --set dapr_scheduler.replicaCount=0 \
    --wait \
    --timeout=10m

echo "  ✓ Dapr installed (scheduler disabled, single replica mode)"

# Wait for Dapr pods to be ready
echo ""
echo "⏳ Waiting for Dapr pods to be ready..."
kubectl wait --for=condition=ready pod \
    --all \
    --namespace=dapr-system \
    --timeout=300s

echo "  ✓ All Dapr pods are ready"

# Verify Dapr installation
echo ""
echo "🔍 Verifying Dapr installation..."
kubectl get pods -n dapr-system

echo ""
echo "✅ Dapr installed successfully on EKS!"
echo ""
echo "Next steps:"
echo "  1. Update Dapr components with AWS credentials"
echo "  2. Run: npm run k8s:deploy"
