#!/bin/bash

# Script to cleanup all AWS resources
# Usage: ./cleanup.sh

set -e

echo "🧹 Cleaning up AWS resources..."
echo ""
echo "⚠️  WARNING: This will delete all resources created by this project!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT_NAME="microservices"

echo ""
echo "🗑️  Starting cleanup process..."

# Delete Kubernetes resources
echo ""
echo "1️⃣  Deleting Kubernetes deployments..."
kubectl delete namespace microservices --ignore-not-found=true || true

echo "  ✓ Kubernetes resources deleted"

# Uninstall Dapr
echo ""
echo "2️⃣  Uninstalling Dapr..."
helm uninstall dapr -n dapr-system || true
kubectl delete namespace dapr-system --ignore-not-found=true || true

echo "  ✓ Dapr uninstalled"

# Delete ECR images
echo ""
echo "3️⃣  Deleting ECR images..."

# Get ECR repository names
REPOS=("product-service" "order-service")

for REPO in "${REPOS[@]}"; do
    echo "  Deleting images from ${REPO}..."
    aws ecr list-images \
        --repository-name "${REPO}" \
        --region "${AWS_REGION}" \
        --query 'imageIds[*]' \
        --output json | \
    jq -r '.[] | .imageDigest' | \
    while read digest; do
        aws ecr batch-delete-image \
            --repository-name "${REPO}" \
            --image-ids imageDigest="${digest}" \
            --region "${AWS_REGION}" || true
    done
done

echo "  ✓ ECR images deleted"

# Delete CloudFormation stacks
echo ""
echo "4️⃣  Deleting CloudFormation stacks (this may take 15-20 minutes)..."

# Delete EKS cluster using eksctl
echo "  Deleting EKS cluster with eksctl..."
CLUSTER_NAME="microservices-cluster"
eksctl delete cluster --name "${CLUSTER_NAME}" --region "${AWS_REGION}" --wait || true

echo "  ✓ EKS cluster deleted"

# Delete CloudFormation stacks (SNS/SQS managed by Dapr, will be deleted automatically)
STACKS=(
    "${ENVIRONMENT_NAME}-dapr-resources"
    "${ENVIRONMENT_NAME}-ecr"
    "${ENVIRONMENT_NAME}-network"
)

# Delete Dapr-managed AWS resources (SNS/SQS)
echo ""
echo "  Cleaning up Dapr-managed SNS/SQS resources..."
aws sns list-topics --region "${AWS_REGION}" --query 'Topics[?contains(TopicArn, `product-events`)].TopicArn' --output text | \
while read topic_arn; do
    if [ -n "$topic_arn" ]; then
        echo "    Deleting SNS topic: ${topic_arn}"
        aws sns delete-topic --topic-arn "${topic_arn}" --region "${AWS_REGION}" || true
    fi
done

aws sqs list-queues --region "${AWS_REGION}" --query 'QueueUrls[*]' --output text | grep -i order | \
while read queue_url; do
    if [ -n "$queue_url" ]; then
        echo "    Deleting SQS queue: ${queue_url}"
        aws sqs delete-queue --queue-url "${queue_url}" --region "${AWS_REGION}" || true
    fi
done

echo "  ✓ Dapr-managed resources deleted"

for STACK in "${STACKS[@]}"; do
    echo "  Deleting ${STACK}..."
    aws cloudformation delete-stack \
        --stack-name "${STACK}" \
        --region "${AWS_REGION}" || true
    
    aws cloudformation wait stack-delete-complete \
        --stack-name "${STACK}" \
        --region "${AWS_REGION}" || true
    
    echo "  ✓ ${STACK} deleted"
done

# Clean local files
echo ""
echo "5️⃣  Cleaning local files..."
rm -f cloudformation-outputs.json
rm -f stack-outputs.json

echo "  ✓ Local files cleaned"

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "All AWS resources have been deleted."
