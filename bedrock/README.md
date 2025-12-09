# Amazon Bedrock Integration for AI-Assisted Analysis

This directory contains TypeScript scripts that use Amazon Bedrock to provide AI-powered insights and recommendations for your microservices architecture.

## Features

1. **Architecture Analysis** (`analyze-architecture.ts`)
   - Reviews Dockerfiles, K8s manifests, and Dapr configurations
   - Identifies security vulnerabilities and best practices
   - Suggests improvements for scalability and reliability

2. **Telemetry Recommendations** (`suggest-telemetry.ts`)
   - Analyzes source code for missing observability points
   - Recommends metrics, logs, and traces to add
   - Suggests CloudWatch dashboards and alarms

3. **Scaling Patterns** (`recommend-scaling.ts`)
   - Analyzes SNS/SQS usage patterns
   - Recommends HPA (Horizontal Pod Autoscaling) configurations
   - Suggests cost optimizations

4. **Resilience Patterns** (`resilience-patterns.ts`)
   - Reviews error handling and retry logic
   - Recommends circuit breaker patterns
   - Suggests chaos engineering experiments

## Prerequisites

```bash
# Install dependencies
npm install

# Configure AWS credentials with Bedrock access
aws configure

# Ensure you have access to Bedrock models
aws bedrock list-foundation-models --region us-east-1
```

## Usage

### 1. Analyze Architecture

```bash
npm run analyze
```

This will analyze:

- Dockerfile best practices
- Kubernetes security and resource limits
- Dapr component configurations
- Infrastructure as Code (CloudFormation)

### 2. Get Telemetry Suggestions

```bash
npm run telemetry
```

Analyzes your microservices code and suggests:

- Missing log statements
- Metrics to track (latency, throughput, errors)
- Distributed tracing points
- Custom CloudWatch metrics

### 3. Get Scaling Recommendations

```bash
npm run scaling
```

Provides recommendations on:

- Kubernetes HPA configurations
- SNS/SQS throughput optimization
- EKS node group sizing
- Cost-performance tradeoffs

### 4. Get Resilience Patterns

```bash
npm run resilience
```

Suggests:

- Retry policies with exponential backoff
- Circuit breaker implementations
- Bulkhead patterns
- Graceful degradation strategies

## Available Models

This project uses:

- **Amazon Titan** (amazon.titan-text-premier-v1:0)

## Example Output

### Architecture Analysis

```
🔍 Analyzing architecture with Amazon Bedrock...

📊 Analysis Results:

Security Findings:
✓ Container runs as non-root user
⚠ Consider using distroless base images
⚠ Add security scanning in CI/CD pipeline

Performance Recommendations:
✓ Multi-stage builds reduce image size
⚠ Consider layer caching optimization
💡 Add Redis for caching product data

Scalability Suggestions:
💡 Implement connection pooling for external services
💡 Add rate limiting middleware
💡 Consider using EKS Fargate for cost optimization
```

### Telemetry Suggestions

```
📈 Telemetry Analysis Results:

Missing Metrics:
- Product creation rate (products_created_total)
- Event publish latency (event_publish_duration_ms)
- Cache hit/miss ratio (cache_hit_ratio)

Recommended Log Points:
- Add structured logging for error scenarios
- Log request correlation IDs
- Track business metrics (revenue, inventory)

Distributed Tracing:
- Instrument HTTP middleware
- Add trace context propagation
- Monitor Dapr sidecar latency
```

## Configuration

Create a `.env` file in the `bedrock/` directory:

```env
AWS_REGION=us-east-1
BEDROCK_MODEL_ID=amazon.titan-text-lite-v1
MAX_TOKENS=4096
TEMPERATURE=0.7
```

## Troubleshooting

### Access Denied Error

```
Error: Access denied to Amazon Bedrock
```

**Solution**: Request model access in AWS Console:

1. Go to Amazon Bedrock Console
2. Navigate to Model access
3. Request access to a model

### Model Not Available

```
Error: Model not found in region
```

**Solution**: Amazon Bedrock is not available in all regions. Use:

- us-east-1 (N. Virginia)
- us-west-2 (Oregon)
- eu-central-1 (Frankfurt)

## Integration with CI/CD

You can integrate these scripts into your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Run Bedrock Analysis
  run: |
    npm run bedrock:analyze > bedrock-report.txt
    cat bedrock-report.txt

- name: Upload Report
  uses: actions/upload-artifact@v3
  with:
    name: bedrock-analysis
    path: bedrock-report.txt
```
