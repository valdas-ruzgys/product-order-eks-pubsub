import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import * as fs from 'fs';
import * as path from 'path';

const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const MODEL_ID = 'amazon.titan-text-lite-v1';

const client = new BedrockRuntimeClient({ region: AWS_REGION });

async function analyzeArchitecture() {
  console.log('🔍 Analyzing architecture with Amazon Bedrock...\n');

  // Read architecture files
  const projectRoot = path.join(__dirname, '..');

  const dockerfile = fs.readFileSync(
    path.join(projectRoot, 'services/product-service/Dockerfile'),
    'utf-8',
  );

  const k8sDeployment = fs.readFileSync(
    path.join(projectRoot, 'infrastructure/kubernetes/product-service/deployment.yaml'),
    'utf-8',
  );

  const daprComponent = fs.readFileSync(
    path.join(projectRoot, 'infrastructure/dapr/components/pubsub-sns-sqs.yaml'),
    'utf-8',
  );

  const prompt = `You are an expert cloud architect reviewing a microservices architecture on AWS EKS with Dapr.

Please analyze the following components and provide detailed recommendations:

1. DOCKERFILE:
\`\`\`dockerfile
${dockerfile}
\`\`\`

2. KUBERNETES DEPLOYMENT:
\`\`\`yaml
${k8sDeployment}
\`\`\`

3. DAPR COMPONENT CONFIGURATION:
\`\`\`yaml
${daprComponent}
\`\`\`

Please provide analysis in the following categories:

## Security
- Identify security vulnerabilities
- Recommend security best practices
- Suggest improvements for secrets management

## Performance
- Analyze resource allocation
- Recommend optimization strategies
- Identify potential bottlenecks

## Scalability
- Assess horizontal scaling readiness
- Recommend autoscaling configurations
- Identify limitations

## Reliability
- Review health checks and probes
- Suggest resilience patterns
- Recommend monitoring strategies

## Cost Optimization
- Identify cost-saving opportunities
- Recommend right-sizing
- Suggest alternative architectures

Format your response with clear sections, bullet points, and actionable recommendations.`;

  // Build request payload for Titan Text model
  let body: string;
  let contentType = 'application/json';
  let accept = 'application/json';

  const titanPayload = {
    inputText: prompt,
    textGenerationConfig: {
      maxTokenCount: 2048,
      temperature: 0.7,
      topP: 0.9,
      stopSequences: [],
    },
  };
  body = JSON.stringify(titanPayload);

  try {
    const command = new InvokeModelCommand({
      modelId: MODEL_ID,
      contentType,
      accept,
      body,
    });

    console.log('⏳ Querying Amazon Bedrock...\n');
    const response = await client.send(command);

    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const analysis = responseBody.results?.[0]?.outputText ?? JSON.stringify(responseBody, null, 2);

    console.log('📊 Analysis Results:\n');
    console.log(analysis);

    // Save to file
    const outputPath = path.join(__dirname, 'output', 'architecture-analysis.txt');
    fs.writeFileSync(outputPath, analysis);
    console.log(`\n💾 Analysis saved to: ${outputPath}`);
  } catch (error: any) {
    console.error('❌ Error calling Bedrock:', error.message);

    if (error.name === 'AccessDeniedException') {
      console.error('\n💡 Please ensure:');
      console.error('  1. You have Bedrock access in your AWS account');
      console.error('  2. Model access is granted for the selected model');
      console.error('  3. Your AWS credentials have the correct permissions');
    }

    process.exit(1);
  }
}

analyzeArchitecture();
