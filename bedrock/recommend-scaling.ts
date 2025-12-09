import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import * as fs from 'fs';
import * as path from 'path';

const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const MODEL_ID = 'amazon.titan-text-lite-v1';

const client = new BedrockRuntimeClient({ region: AWS_REGION });

async function recommendScaling() {
  console.log('📊 Generating scaling recommendations with Amazon Bedrock...\n');

  const projectRoot = path.join(__dirname, '..');

  const k8sProductDeployment = fs.readFileSync(
    path.join(projectRoot, 'infrastructure/kubernetes/product-service/deployment.yaml'),
    'utf-8',
  );

  const daprPubSub = fs.readFileSync(
    path.join(projectRoot, 'infrastructure/dapr/components/pubsub-sns-sqs.yaml'),
    'utf-8',
  );

  const prompt = `You are an expert in Kubernetes scaling, AWS SNS/SQS optimization, and cost-efficient cloud architecture.

Analyze these configurations and provide comprehensive scaling recommendations:

KUBERNETES DEPLOYMENT:
\`\`\`yaml
${k8sProductDeployment}
\`\`\`

DAPR PUB/SUB COMPONENT:
\`\`\`yaml
${daprPubSub}
\`\`\`

Provide detailed recommendations in these areas:

## Horizontal Pod Autoscaling (HPA)
- HPA configuration with metrics
- Target CPU/Memory utilization
- Custom metrics (requests per second, queue depth)
- Min/Max replicas based on traffic patterns

## Vertical Pod Autoscaling (VPA)
- Resource request/limit recommendations
- Memory and CPU right-sizing
- VPA policy suggestions

## SNS/SQS Optimization
- Message batching strategies
- Visibility timeout tuning
- Long polling configuration
- Dead letter queue policies
- Throughput optimization

## EKS Node Scaling
- Cluster Autoscaler configuration
- Node group sizing recommendations
- Spot instance usage
- Multi-AZ considerations

## Cost Optimization
- Reserved capacity vs on-demand
- Savings Plans recommendations
- Resource utilization analysis
- Cost-performance tradeoffs

## Traffic Patterns
- Expected load patterns
- Burst handling strategies
- Gradual scale-up/scale-down
- Pre-warming strategies

Provide specific YAML configurations and numeric recommendations where possible.`;

  // Titan Text request payload
  const titanPayload = {
    inputText: prompt,
    textGenerationConfig: {
      maxTokenCount: 2048,
      temperature: 0.7,
      topP: 0.9,
      stopSequences: [],
    },
  };

  try {
    const command = new InvokeModelCommand({
      modelId: MODEL_ID,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(titanPayload),
    });

    console.log('⏳ Querying Amazon Bedrock...\n');
    const response = await client.send(command);

    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const recommendations =
      responseBody.results?.[0]?.outputText ?? JSON.stringify(responseBody, null, 2);

    console.log('📊 Scaling Recommendations:\n');
    console.log(recommendations);

    // Save to file
    const outputPath = path.join(__dirname, 'output', 'scaling-recommendations.txt');
    fs.writeFileSync(outputPath, recommendations);
    console.log(`\n💾 Recommendations saved to: ${outputPath}`);
  } catch (error: any) {
    console.error('❌ Error calling Bedrock:', error.message);
    process.exit(1);
  }
}

recommendScaling();
