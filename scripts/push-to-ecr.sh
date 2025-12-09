#!/bin/bash

# Script to push Docker images to Amazon ECR
# Usage: ./push-to-ecr.sh

set -e

echo "📤 Pushing Docker images to Amazon ECR..."
echo ""

# Get AWS configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "  ✓ Logged in to ECR"
echo ""

# Push Product Service
echo "1️⃣  Pushing Product Service..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/product-service:latest

echo "  ✓ Product Service pushed"

# Push Order Service
echo ""
echo "2️⃣  Pushing Order Service..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/order-service:latest

echo "  ✓ Order Service pushed"

echo ""
echo "✅ All images pushed to ECR successfully!"
echo ""
echo "Next step: Run 'npm run dapr:install' to install Dapr on EKS"
