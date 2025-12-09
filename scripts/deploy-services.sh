#!/bin/bash

# Script to deploy microservices to Kubernetes
# Usage: ./deploy-services.sh

set -e

echo "🚀 Deploying microservices to Kubernetes..."
echo ""

# Get AWS configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}

export AWS_ACCOUNT_ID
export AWS_REGION

echo "📋 Configuration:"
echo "  AWS Account: ${AWS_ACCOUNT_ID}"
echo "  AWS Region: ${AWS_REGION}"
echo ""

# Create namespace
echo "1️⃣  Creating microservices namespace..."
kubectl apply -f infrastructure/kubernetes/namespace.yaml

echo "  ✓ Namespace created"

# Deploy Dapr components
echo ""
echo "2️⃣  Deploying Dapr components..."

# Get SNS Topic ARN from CloudFormation
SNS_TOPIC_ARN=$(aws cloudformation describe-stacks \
    --stack-name microservices-messaging \
    --query 'Stacks[0].Outputs[?OutputKey==`ProductEventsTopicArn`].OutputValue' \
    --output text \
    --region ${AWS_REGION} 2>/dev/null || echo "")

if [ -z "$SNS_TOPIC_ARN" ]; then
    echo "  ⚠️  Warning: Could not retrieve SNS Topic ARN from CloudFormation"
    echo "  Constructing ARN from AWS Account ID..."
    SNS_TOPIC_ARN="arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:product-events"
fi

echo "  ✓ SNS Topic ARN: ${SNS_TOPIC_ARN}"

# Replace AWS_REGION and SNS_TOPIC_ARN in Dapr components
sed -e "s|\${AWS_REGION}|${AWS_REGION}|g" \
    -e "s|\${SNS_TOPIC_ARN}|${SNS_TOPIC_ARN}|g" \
    infrastructure/dapr/components/pubsub-sns-sqs.yaml | \
    kubectl apply -f -

sed "s/\${AWS_REGION}/${AWS_REGION}/g" infrastructure/dapr/components/statestore-dynamodb.yaml | \
    kubectl apply -f -

kubectl apply -f infrastructure/dapr/config/dapr-config.yaml

echo "  ✓ Dapr components deployed"

# Deploy Product Service
echo ""
echo "3️⃣  Deploying Product Service..."

# Replace placeholders in deployment
sed -e "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" \
    -e "s/\${AWS_REGION}/${AWS_REGION}/g" \
    infrastructure/kubernetes/product-service/deployment.yaml | \
    kubectl apply -f -

echo "  ✓ Product Service deployed"

# Deploy Order Service
echo ""
echo "4️⃣  Deploying Order Service..."

# Replace placeholders in deployment
sed -e "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" \
    -e "s/\${AWS_REGION}/${AWS_REGION}/g" \
    infrastructure/kubernetes/order-service/deployment.yaml | \
    kubectl apply -f -

echo "  ✓ Order Service deployed"

# Wait for deployments to be ready
echo ""
echo "⏳ Waiting for deployments to be ready (this may take a few minutes)..."

kubectl wait --for=condition=available deployment/product-service \
    -n microservices \
    --timeout=300s || true

kubectl wait --for=condition=available deployment/order-service \
    -n microservices \
    --timeout=300s || true

echo ""
echo "📊 Deployment Status:"
kubectl get pods -n microservices

echo ""
echo "🌐 Services:"
kubectl get svc -n microservices

echo ""
echo "✅ Microservices deployed successfully!"
echo ""
echo "To access the services:"
echo "  Product Service: kubectl port-forward -n microservices svc/product-service 4000:80"
echo "  Order Service:   kubectl port-forward -n microservices svc/order-service 4001:80"
echo ""
echo "To view logs:"
echo "  Product: npm run logs:product"
echo "  Order: npm run logs:order"
