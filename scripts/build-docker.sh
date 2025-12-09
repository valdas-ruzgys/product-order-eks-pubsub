#!/bin/bash

# Script to build Docker images for both services
# Usage: ./build-docker.sh

set -e

echo "🐳 Building Docker images..."
echo ""

# Get AWS configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "📋 Configuration:"
echo "  AWS Account: ${AWS_ACCOUNT_ID}"
echo "  AWS Region: ${AWS_REGION}"
echo ""

# Build Product Service
echo "1️⃣  Building Product Service..."
cd services/product-service
docker build --platform linux/amd64 -t product-service:latest \
    -t product-service:$(date +%Y%m%d-%H%M%S) \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/product-service:latest \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/product-service:$(date +%Y%m%d-%H%M%S) \
    .

echo "  ✓ Product Service image built"
cd ../..

# Build Order Service
echo ""
echo "2️⃣  Building Order Service..."
cd services/order-service
docker build --platform linux/amd64 -t order-service:latest \
    -t order-service:$(date +%Y%m%d-%H%M%S) \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/order-service:latest \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/order-service:$(date +%Y%m%d-%H%M%S) \
    .

echo "  ✓ Order Service image built"
cd ../..

# List images
echo ""
echo "📦 Built images:"
docker images | grep -E "product-service|order-service" | head -4

echo ""
echo "✅ Docker images built successfully!"
echo ""
echo "Next step: Run 'npm run docker:push' to push images to ECR"
