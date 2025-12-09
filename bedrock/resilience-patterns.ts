import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import * as fs from 'fs';
import * as path from 'path';

const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const MODEL_ID = 'amazon.titan-text-lite-v1';

const client = new BedrockRuntimeClient({ region: AWS_REGION });

async function analyzeResilience() {
  console.log('🛡️  Analyzing resilience patterns with Amazon Bedrock...\n');

  const projectRoot = path.join(__dirname, '..');

  const productController = fs.readFileSync(
    path.join(
      projectRoot,
      'services/product-service/src/modules/product/controllers/product.controller.ts',
    ),
    'utf-8',
  );

  const daprClient = fs.readFileSync(
    path.join(projectRoot, 'services/product-service/src/modules/dapr/services/dapr.service.ts'),
    'utf-8',
  );

  const prompt = `You are an expert in distributed systems resilience, fault tolerance, and chaos engineering.

Analyze this microservices code and recommend resilience patterns:

PRODUCT CONTROLLER:
\`\`\`typescript
${productController}
\`\`\`

DAPR CLIENT:
\`\`\`typescript
${daprClient}
\`\`\`

Provide comprehensive recommendations in these areas:

## Retry Patterns
- Exponential backoff implementation
- Maximum retry attempts
- Jitter to prevent thundering herd
- Idempotency considerations
- When NOT to retry

## Circuit Breaker
- Circuit breaker states (closed, open, half-open)
- Failure threshold configuration
- Timeout settings
- Fallback strategies
- Health check integration

## Bulkhead Pattern
- Resource isolation
- Thread pool segregation
- Queue limits
- Preventing cascading failures

## Timeout Management
- Request timeouts
- Connection timeouts
- Graceful degradation
- Deadline propagation

## Error Handling
- Error classification (transient vs permanent)
- Error logging and monitoring
- Graceful error responses
- Dead letter queue usage

## Dapr Resilience
- Dapr resiliency policies
- Retry policies for pub/sub
- Circuit breakers for service invocation
- Timeout configurations

## Chaos Engineering
- Fault injection scenarios
- Latency injection
- Error rate simulation
- Service dependency failures
- Recommended chaos experiments

## Observability for Resilience
- Error rate monitoring
- Circuit breaker state tracking
- Retry attempt metrics
- Timeout occurrence tracking

Provide specific code examples using TypeScript and Dapr where applicable.`;

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
    const patterns = responseBody.results?.[0]?.outputText ?? JSON.stringify(responseBody, null, 2);

    console.log('📊 Resilience Pattern Recommendations:\n');
    console.log(patterns);

    // Save to file
    const outputPath = path.join(__dirname, 'output', 'resilience-patterns.txt');
    fs.writeFileSync(outputPath, patterns);
    console.log(`\n💾 Patterns saved to: ${outputPath}`);
  } catch (error: any) {
    console.error('❌ Error calling Bedrock:', error.message);
    process.exit(1);
  }
}

analyzeResilience();
