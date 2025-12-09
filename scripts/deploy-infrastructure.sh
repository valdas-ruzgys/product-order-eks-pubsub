#!/bin/bash

# Script to deploy CloudFormation infrastructure
# Usage: ./deploy-infrastructure.sh [--profile PROFILE_NAME]

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--profile PROFILE_NAME]"
      exit 1
      ;;
  esac
done

# Set AWS CLI arguments
if [ -n "${AWS_PROFILE}" ]; then
    AWS_CLI_ARGS="--profile ${AWS_PROFILE}"
    echo "Using AWS profile: ${AWS_PROFILE}"
else
    AWS_CLI_ARGS=""
fi

echo "🚀 Deploying CloudFormation Infrastructure..."
echo ""

# Get AWS account and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity ${AWS_CLI_ARGS} --query Account --output text)
AWS_REGION=${AWS_REGION:-$(aws configure get region ${AWS_CLI_ARGS})}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "📋 Configuration:"
echo "  AWS Account: ${AWS_ACCOUNT_ID}"
echo "  AWS Region: ${AWS_REGION}"
echo ""

# Set stack name
STACK_NAME="eks-microservices-main"
ENVIRONMENT_NAME="microservices"

# Create S3 bucket for CloudFormation templates (if not exists)
BUCKET_NAME="cf-templates-${AWS_ACCOUNT_ID}-${AWS_REGION}"
echo "📦 Checking S3 bucket for templates..."

if ! aws s3 ls "s3://${BUCKET_NAME}" ${AWS_CLI_ARGS} 2>&1 | grep -q 'NoSuchBucket'; then
    echo "  ✓ Bucket exists: ${BUCKET_NAME}"
else
    echo "  Creating bucket: ${BUCKET_NAME}"
    if [ "$AWS_REGION" == "us-east-1" ]; then
        aws s3 mb "s3://${BUCKET_NAME}" ${AWS_CLI_ARGS}
    else
        aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}" ${AWS_CLI_ARGS}
    fi
fi

# Upload templates to S3
echo ""
echo "📤 Uploading CloudFormation templates to S3..."
aws s3 sync infrastructure/cloudformation/ "s3://${BUCKET_NAME}/cloudformation/" \
    --exclude "*" --include "*.yaml" ${AWS_CLI_ARGS}

echo "  ✓ Templates uploaded"

# Deploy CloudFormation stacks
echo ""
echo "🏗️  Deploying CloudFormation stacks..."
echo ""

# Deploy ECR Stack
echo "1️⃣  Deploying ECR Stack..."
aws cloudformation deploy ${AWS_CLI_ARGS} \
    --template-file infrastructure/cloudformation/ecr-repositories.yaml \
    --stack-name "${ENVIRONMENT_NAME}-ecr" \
    --parameter-overrides EnvironmentName=${ENVIRONMENT_NAME} \
    --region "${AWS_REGION}" \
    --no-fail-on-empty-changeset

echo "  ✓ ECR stack deployed"

# Note: SNS/SQS resources are now managed by Dapr (not CloudFormation)
echo ""
echo "ℹ️  SNS/SQS resources will be created by Dapr automatically"

# Deploy Dapr Resources Stack (DynamoDB, IAM Policies)
echo ""
echo "2️⃣  Deploying Dapr Resources Stack (DynamoDB, IAM Policies)..."
aws cloudformation deploy ${AWS_CLI_ARGS} \
    --template-file infrastructure/cloudformation/dapr-resources.yaml \
    --stack-name "${ENVIRONMENT_NAME}-dapr-resources" \
    --parameter-overrides EnvironmentName=${ENVIRONMENT_NAME} \
    --region "${AWS_REGION}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

echo "  ✓ Dapr resources stack deployed"

# Deploy Network Stack (VPC, Subnets, Security Groups)
echo ""
echo "3️⃣  Deploying Network Stack (VPC, Subnets, Security Groups)..."
aws cloudformation deploy ${AWS_CLI_ARGS} \
    --template-file infrastructure/cloudformation/network.yaml \
    --stack-name "${ENVIRONMENT_NAME}-network" \
    --parameter-overrides EnvironmentName=${ENVIRONMENT_NAME} \
    --region "${AWS_REGION}" \
    --no-fail-on-empty-changeset

echo "  ✓ Network stack deployed"

# Get VPC and Subnet information
echo ""
echo "🔍 Retrieving network information..."
VPC_ID=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
    --stack-name "${ENVIRONMENT_NAME}-network" \
    --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

PRIVATE_SUBNETS=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
    --stack-name "${ENVIRONMENT_NAME}-network" \
    --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetIds`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

PUBLIC_SUBNETS=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
    --stack-name "${ENVIRONMENT_NAME}-network" \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnetIds`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

echo "  ✓ VPC ID: ${VPC_ID}"
echo "  ✓ Private Subnets: ${PRIVATE_SUBNETS}"
echo "  ✓ Public Subnets: ${PUBLIC_SUBNETS}"

# Deploy EKS Cluster using eksctl
echo ""
echo "4️⃣  Deploying EKS Cluster (this will take 15-20 minutes)..."
echo ""

# Cluster configuration
CLUSTER_NAME="microservices-cluster"
K8S_VERSION="1.31"
NODE_TYPE="t3.medium"
MIN_NODES=2
MAX_NODES=4
DESIRED_NODES=2

# Convert comma-separated subnets to arrays
IFS=',' read -ra PRIVATE_SUBNET_ARRAY <<< "$PRIVATE_SUBNETS"
IFS=',' read -ra PUBLIC_SUBNET_ARRAY <<< "$PUBLIC_SUBNETS"

# Trim whitespace from subnet IDs
PRIVATE_SUBNET_ARRAY=("${PRIVATE_SUBNET_ARRAY[@]// /}")
PUBLIC_SUBNET_ARRAY=("${PUBLIC_SUBNET_ARRAY[@]// /}")

echo "  ✓ Found ${#PRIVATE_SUBNET_ARRAY[@]} private subnets and ${#PUBLIC_SUBNET_ARRAY[@]} public subnets"
echo "  Private: ${PRIVATE_SUBNET_ARRAY[@]}"
echo "  Public: ${PUBLIC_SUBNET_ARRAY[@]}"

# Verify we have at least 2 subnets of each type
if [ ${#PRIVATE_SUBNET_ARRAY[@]} -lt 2 ] || [ ${#PUBLIC_SUBNET_ARRAY[@]} -lt 2 ]; then
    echo "❌ Error: Need at least 2 private and 2 public subnets"
    echo "   Private subnets found: ${#PRIVATE_SUBNET_ARRAY[@]}"
    echo "   Public subnets found: ${#PUBLIC_SUBNET_ARRAY[@]}"
    exit 1
fi

# Create eksctl config file
echo "📝 Creating eksctl cluster configuration..."
cat > /tmp/eks-cluster-config.yaml <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${AWS_REGION}
  version: "${K8S_VERSION}"

# Use created VPC and subnets
vpc:
  id: "${VPC_ID}"
  subnets:
    private:
      ${AWS_REGION}a: { id: ${PRIVATE_SUBNET_ARRAY[0]} }
      ${AWS_REGION}b: { id: ${PRIVATE_SUBNET_ARRAY[1]} }
    public:
      ${AWS_REGION}a: { id: ${PUBLIC_SUBNET_ARRAY[0]} }
      ${AWS_REGION}b: { id: ${PUBLIC_SUBNET_ARRAY[1]} }
  clusterEndpoints:
    publicAccess: true
    privateAccess: true

# Managed node group in private subnets
managedNodeGroups:
  - name: microservices-nodes
    instanceType: ${NODE_TYPE}
    minSize: ${MIN_NODES}
    maxSize: ${MAX_NODES}
    desiredCapacity: ${DESIRED_NODES}
    volumeSize: 20
    volumeType: gp3
    
    # Use private subnets for nodes
    privateNetworking: true
    
    labels:
      role: microservices
      environment: dev
    
    tags:
      Environment: dev
      Application: microservices
    
    iam:
      withAddonPolicies:
        autoScaler: true
        ebs: true
        cloudWatch: true
        albIngress: true

# Enable CloudWatch logging and Container Insights
cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    logRetentionInDays: 7

# Add-ons
addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
EOF

echo "  ✓ Configuration created"

# Deploy cluster
echo ""
echo "🏗️  Creating EKS cluster..."
eksctl create cluster -f /tmp/eks-cluster-config.yaml

echo ""
echo "  ✓ EKS cluster created"

# Update kubeconfig
echo ""
echo "⚙️  Updating kubeconfig..."
aws eks update-kubeconfig \
    --name ${CLUSTER_NAME} \
    --region ${AWS_REGION} \
    ${AWS_CLI_ARGS}

echo "  ✓ kubeconfig updated"

# Install CloudWatch Container Insights
echo ""
echo "📊 Installing CloudWatch Container Insights..."

# Create namespace for CloudWatch
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

# Install CloudWatch agent and Fluent Bit
ClusterName="${CLUSTER_NAME}"
RegionName="${AWS_REGION}"
FluentBitHttpPort='"2020"'
FluentBitReadFromHead='"Off"'
[[ ${FluentBitReadFromHead} = '"On"' ]] && FluentBitReadFromTail='"Off"' || FluentBitReadFromTail='"On"'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='"Off"' || FluentBitHttpServer='"On"'

curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | \
sed "s/{{cluster_name}}/${ClusterName}/;s/{{region_name}}/${RegionName}/;s/{{http_server_toggle}}/${FluentBitHttpServer}/;s/{{http_server_port}}/${FluentBitHttpPort}/;s/{{read_from_head}}/${FluentBitReadFromHead}/;s/{{read_from_tail}}/${FluentBitReadFromTail}/" | \
kubectl apply -f -

echo "  ✓ CloudWatch Container Insights installed"
echo "  ✓ Logs will be available at: CloudWatch → Log groups → /aws/containerinsights/${CLUSTER_NAME}"

# Attach IAM policies to EKS node role for Dapr
echo ""
echo "🔐 Attaching IAM policies to EKS node role..."

# Get the node role name
NODE_ROLE_NAME=$(aws iam list-roles ${AWS_CLI_ARGS} \
    --query "Roles[?contains(RoleName, '${CLUSTER_NAME}-nodeg-NodeInstanceRole')].RoleName" \
    --output text \
    --region "${AWS_REGION}")

if [ -z "$NODE_ROLE_NAME" ]; then
    echo "⚠️  Warning: Could not find EKS node role. Trying alternative method..."
    NODE_ROLE_NAME=$(aws cloudformation describe-stack-resources ${AWS_CLI_ARGS} \
        --stack-name "eksctl-${CLUSTER_NAME}-nodegroup-microservices-nodes" \
        --query "StackResources[?ResourceType=='AWS::IAM::Role'].PhysicalResourceId" \
        --output text \
        --region "${AWS_REGION}")
fi

if [ -n "$NODE_ROLE_NAME" ]; then
    echo "  ✓ Found node role: ${NODE_ROLE_NAME}"
    
    # Get policy ARNs from Dapr resources stack
    DYNAMODB_POLICY_ARN=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
        --stack-name "${ENVIRONMENT_NAME}-dapr-resources" \
        --query 'Stacks[0].Outputs[?OutputKey==`DynamoDBAccessPolicyArn`].OutputValue' \
        --output text \
        --region "${AWS_REGION}")
    
    SNSSQS_POLICY_ARN=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
        --stack-name "${ENVIRONMENT_NAME}-dapr-resources" \
        --query 'Stacks[0].Outputs[?OutputKey==`SNSSQSAccessPolicyArn`].OutputValue' \
        --output text \
        --region "${AWS_REGION}")
    
    CLOUDWATCH_POLICY_ARN=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
        --stack-name "${ENVIRONMENT_NAME}-dapr-resources" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudWatchLogsPolicyArn`].OutputValue' \
        --output text \
        --region "${AWS_REGION}")
    
    echo "  ✓ DynamoDB Policy ARN: ${DYNAMODB_POLICY_ARN}"
    echo "  ✓ SNS/SQS Policy ARN: ${SNSSQS_POLICY_ARN}"
    echo "  ✓ CloudWatch Logs Policy ARN: ${CLOUDWATCH_POLICY_ARN}"
    
    # Attach policies
    echo "  📎 Attaching DynamoDB policy..."
    aws iam attach-role-policy ${AWS_CLI_ARGS} \
        --role-name "${NODE_ROLE_NAME}" \
        --policy-arn "${DYNAMODB_POLICY_ARN}" \
        --region "${AWS_REGION}" || echo "    (Policy may already be attached)"
    
    echo "  📎 Attaching SNS/SQS policy..."
    aws iam attach-role-policy ${AWS_CLI_ARGS} \
        --role-name "${NODE_ROLE_NAME}" \
        --policy-arn "${SNSSQS_POLICY_ARN}" \
        --region "${AWS_REGION}" || echo "    (Policy may already be attached)"
    
    echo "  📎 Attaching CloudWatch Logs policy..."
    aws iam attach-role-policy ${AWS_CLI_ARGS} \
        --role-name "${NODE_ROLE_NAME}" \
        --policy-arn "${CLOUDWATCH_POLICY_ARN}" \
        --region "${AWS_REGION}" || echo "    (Policy may already be attached)"
    
    echo "  ✓ IAM policies attached successfully"
else
    echo "  ⚠️  Warning: Could not find node role. You may need to attach policies manually."
fi

# Verify cluster
echo ""
echo "🔍 Verifying cluster..."
kubectl cluster-info
kubectl get nodes

# Clean up temp file
rm -f /tmp/eks-cluster-config.yaml

# Get stack outputs
echo ""
echo "📊 Stack Outputs:"
echo ""

# ECR Repository URIs
PRODUCT_REPO_URI=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
    --stack-name "${ENVIRONMENT_NAME}-ecr" \
    --query 'Stacks[0].Outputs[?OutputKey==`ProductServiceRepositoryUri`].OutputValue' \
    --output text --region "${AWS_REGION}")

ORDER_REPO_URI=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
    --stack-name "${ENVIRONMENT_NAME}-ecr" \
    --query 'Stacks[0].Outputs[?OutputKey==`OrderServiceRepositoryUri`].OutputValue' \
    --output text --region "${AWS_REGION}")

# DynamoDB Table Name
DYNAMODB_TABLE=$(aws cloudformation describe-stacks ${AWS_CLI_ARGS} \
    --stack-name "${ENVIRONMENT_NAME}-dapr-resources" \
    --query 'Stacks[0].Outputs[?OutputKey==`DaprStateStoreTableName`].OutputValue' \
    --output text --region "${AWS_REGION}")

echo "  Product Service ECR: ${PRODUCT_REPO_URI}"
echo "  Order Service ECR: ${ORDER_REPO_URI}"
echo "  DynamoDB Table: ${DYNAMODB_TABLE}"
echo "  ℹ️  SNS/SQS resources will be created by Dapr when services are deployed"

# Save outputs to file
echo ""
echo "💾 Saving outputs to cloudformation-outputs.json..."
cat > cloudformation-outputs.json <<EOF
{
  "awsAccountId": "${AWS_ACCOUNT_ID}",
  "awsRegion": "${AWS_REGION}",
  "productServiceRepoUri": "${PRODUCT_REPO_URI}",
  "orderServiceRepoUri": "${ORDER_REPO_URI}",
  "dynamodbTable": "${DYNAMODB_TABLE}"
}
EOF

echo ""
echo "✅ Infrastructure deployment completed successfully!"
echo ""
echo "What was deployed:"
echo "  ✓ ECR repositories for Docker images"
echo "  ✓ DynamoDB state store for Dapr"
echo "  ✓ IAM policies for Dapr components (SNS, SQS, DynamoDB)"
echo "  ✓ CloudWatch Container Insights for monitoring"
echo "  ✓ VPC with public/private subnets"
echo "  ✓ EKS cluster (${CLUSTER_NAME})"
echo "  ✓ EKS node group (${DESIRED_NODES}x ${NODE_TYPE})"
echo ""
echo "ℹ️  Note: SNS/SQS resources will be created automatically by Dapr"
echo ""
echo "Cluster details:"
echo "  Name: ${CLUSTER_NAME}"
echo "  Region: ${AWS_REGION}"
echo "  Version: ${K8S_VERSION}"
echo "  VPC: ${VPC_ID}"
echo ""
echo "Monitoring:"
echo "  CloudWatch Log Group: /aws/containerinsights/${CLUSTER_NAME}"
echo "  Container Insights: CloudWatch → Container Insights → Performance monitoring"
echo ""
echo "Next steps:"
echo "  1. Install Dapr: npm run dapr:install"
echo "  2. Build services: npm run build:all"
echo "  3. Build Docker images: npm run docker:build"
echo "  4. Push to ECR: npm run docker:push"
echo "  5. Deploy services: npm run k8s:deploy"
