#!/bin/bash

# Script to login to Amazon ECR
# Usage: ./docker-login.sh

set -e

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "🔐 Logging in to Amazon ECR..."
echo "  Account: ${AWS_ACCOUNT_ID}"
echo "  Region: ${AWS_REGION}"
echo ""

aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo ""
echo "✅ Successfully logged in to ECR!"
