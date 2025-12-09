#!/bin/bash

# Script to get CloudFormation stack outputs
# Usage: ./get-stack-outputs.sh

set -e

AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT_NAME="microservices"

echo "📊 Retrieving CloudFormation Stack Outputs..."
echo ""

# Function to get stack output
get_output() {
    local STACK_NAME=$1
    local OUTPUT_KEY=$2
    
    aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --query "Stacks[0].Outputs[?OutputKey=='${OUTPUT_KEY}'].OutputValue" \
        --output text \
        --region "${AWS_REGION}" 2>/dev/null || echo "N/A"
}

# Network Stack Outputs
echo "🌐 Network Stack:"
echo "  VPC ID: $(get_output "${ENVIRONMENT_NAME}-network" "VPC")"
echo "  Public Subnet 1: $(get_output "${ENVIRONMENT_NAME}-network" "PublicSubnet1")"
echo "  Public Subnet 2: $(get_output "${ENVIRONMENT_NAME}-network" "PublicSubnet2")"
echo "  Private Subnet 1: $(get_output "${ENVIRONMENT_NAME}-network" "PrivateSubnet1")"
echo "  Private Subnet 2: $(get_output "${ENVIRONMENT_NAME}-network" "PrivateSubnet2")"
echo ""

# ECR Stack Outputs
echo "📦 ECR Stack:"
echo "  Product Service URI: $(get_output "${ENVIRONMENT_NAME}-ecr" "ProductServiceRepositoryUri")"
echo "  Order Service URI: $(get_output "${ENVIRONMENT_NAME}-ecr" "OrderServiceRepositoryUri")"
echo ""

# EKS Stack Outputs
echo "☸️  EKS Stack:"
echo "  Cluster Name: $(get_output "${ENVIRONMENT_NAME}-eks" "ClusterName")"
echo "  Cluster Endpoint: $(get_output "${ENVIRONMENT_NAME}-eks" "ClusterEndpoint")"
echo "  Node Role ARN: $(get_output "${ENVIRONMENT_NAME}-eks" "NodeRoleArn")"
echo ""
