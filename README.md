# EKS Microservices with Dapr Pub/Sub - Introspect Lab

## 🎯 Objective

Deploy containerized microservices using Amazon EKS with Dapr sidecars to implement pub/sub messaging and observe real-time event-driven interactions between microservices running on Kubernetes.

## 🏗️ Architecture Overview

This project demonstrates a production-ready microservices architecture on AWS:

- **ProductService**: Publishes product events (created, updated) to Dapr pub/sub
- **OrderService**: Subscribes to product events and processes orders
- **Infrastructure**: Amazon EKS, ECR, SNS/SQS, CloudWatch, VPC
- **Service Mesh**: Dapr for service-to-service communication and pub/sub

```
┌─────────────────────────────────────────────────────────────┐
│                        Amazon EKS Cluster                   │
│  ┌──────────────────────┐       ┌──────────────────────┐    │
│  │  ProductService Pod  │       │  OrderService Pod    │    │
│  │  ┌────────────────┐  │       │  ┌────────────────┐  │    │
│  │  │  TypeScript    │  │       │  │  TypeScript    │  │    │
│  │  │  Service       │  │       │  │  Service       │  │    │
│  │  └────────┬───────┘  │       │  └────────▲───────┘  │    │
│  │  ┌────────▼───────┐  │       │  ┌────────┴───────┐  │    │
│  │  │  Dapr Sidecar  │  │       │  │  Dapr Sidecar  │  │    │
│  │  └────────┬───────┘  │       │  └────────▲───────┘  │    │
│  └───────────┼──────────┘       └───────────┼──────────┘    │
│              │                              │               │
└──────────────┼──────────────────────────────┼───────────────┘
               │                              │
               └──────────┬───────────────────┘
                          │
                   ┌──────▼────────┐
                   │  AWS SNS/SQS  │
                   │  (Pub/Sub)    │
                   └───────────────┘
```

More about architecture can be found at: `docs/architecture.md` and `docs/architecture-diagram.pdf`

## 📋 Prerequisites

### Required Tools

- **AWS CLI** (v2.x): `aws --version`
- **Docker** (20.x+): `docker --version`
- **kubectl** (1.31+): `kubectl version --client`
- **eksctl** (0.165+): `eksctl version`
- **Helm** (3.x+): `helm version`
- **Node.js** (20.x LTS): `node --version`
- **TypeScript** (5.x+): `tsc --version`

### AWS Permissions Required

- EKS (cluster creation and management)
- ECR (repository creation and image push)
- IAM (role and policy management)
- VPC (network configuration)
- CloudWatch (logging and monitoring)
- SNS/SQS (pub/sub messaging)
- CloudFormation (stack deployment)

### Install Prerequisites (macOS)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install awscli kubectl eksctl helm node@20

# Verify installations
aws --version
kubectl version --client
node --version
```

## 🚀 Quick Start

Prepare each service:

- Product Service: `services/product-service/README.md`
- Order Service: `services/order-service/README.md`

### Auto deploy of full infrastructure

```bash
npm run deploy:full
```

### Manual deployment (step-by-step)

#### 1. Clone and Setup

```bash
npm install
```

#### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region (e.g., us-east-1)
```

#### 3. Deploy Infrastructure (CloudFormation)

```bash
npm run infra:deploy
```

This creates:

- VPC with public/private subnets
- EKS cluster with managed node group
- ECR repositories for both services
- SNS topic and SQS queues
- IAM roles and policies

#### 4. Build and Push Docker Images

```bash
npm run build:all
npm run docker:build
npm run docker:push
```

#### 5. Install Dapr on EKS

```bash
npm run dapr:install
```

#### 6. Deploy Microservices

```bash
npm run k8s:deploy
```

#### 7. Monitor and Test

```bash
npm run logs:product
npm run logs:order
npm run test:publish
```

## 📜 Available NPM Scripts

### Infrastructure

```bash
npm run infra:deploy          # Deploy CloudFormation stacks
npm run infra:destroy         # Delete all infrastructure
```

### Build

```bash
npm run build:all             # Build all TypeScript services
npm run build:product         # Build ProductService only
npm run build:order           # Build OrderService only
npm run clean                 # Clean build artifacts
```

### Docker

```bash
npm run docker:build          # Build all Docker images
npm run docker:push           # Push images to ECR
npm run docker:login          # Login to ECR
```

### Kubernetes & Dapr

```bash
npm run dapr:install          # Install Dapr on EKS
npm run dapr:uninstall        # Remove Dapr
npm run k8s:deploy            # Deploy services to EKS
npm run k8s:delete            # Delete deployments
npm run k8s:status            # Check pod status
```

### Testing & Monitoring

```bash
npm run test:publish          # Test event publishing
npm run logs:product          # View ProductService logs
npm run logs:order            # View OrderService logs
npm run logs:dapr             # View Dapr logs
npm run port-forward:product  # Port forward ProductService
npm run port-forward:order    # Port forward OrderService
```

## 🧪 Testing the System

### Automated test of all the workflow

```bash
npm run test:workflow
```

### Manual test (step-by-step)

#### 1. Create a Product (triggers event)

```bash
curl -X POST http://localhost:4000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 1299.99,
    "stock": 50
  }'
```

#### 2. Check ProductService Logs

```bash
npm run logs:product
```

#### 3. Check OrderService Logs

```bash
npm run logs:order
```

#### 4. View Dapr Pub/Sub Flow

```bash
kubectl logs -l app=product-service -c daprd -n microservices
kubectl logs -l app=order-service -c daprd -n microservices
```

## 🤖 GenAI-Assisted Tasks (Amazon Bedrock)

This project includes Bedrock integration for:

1. **Telemetry Analysis**: Suggests missing observability points
2. **Resilience Patterns**: Recommends retry and circuit breaker strategies
3. **Architecture Review**: Analyzes Dockerfiles, K8s manifests, Dapr configs
4. **Scaling Recommendations**: Optimizes SNS/SQS pub/sub patterns

See `bedrock/README.md` for detailed usage.

## 🧹 Cleanup

Remove all resources to avoid AWS charges:

```bash
npm run cleanup
```
