import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import * as fs from 'fs';
import * as path from 'path';

const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const MODEL_ID = 'amazon.titan-text-lite-v1';

const client = new BedrockRuntimeClient({ region: AWS_REGION });

async function suggestTelemetry() {
  console.log('📈 Analyzing telemetry requirements with Amazon Bedrock...\n');

  // Read source code
  const projectRoot = path.join(__dirname, '..');

  const productController = fs.readFileSync(
    path.join(
      projectRoot,
      'services/product-service/src/modules/product/controllers/product.controller.ts',
    ),
    'utf-8',
  );

  const orderController = fs.readFileSync(
    path.join(
      projectRoot,
      'services/order-service/src/modules/order/controllers/order.controller.ts',
    ),
    'utf-8',
  );

  const prompt = `You are an expert in observability and monitoring for microservices.

Analyze the following TypeScript microservice code and suggest comprehensive telemetry improvements:

PRODUCT SERVICE CONTROLLER:
\`\`\`typescript
${productController}
\`\`\`

ORDER SERVICE CONTROLLER:
\`\`\`typescript
${orderController}
\`\`\`

Please provide detailed recommendations in these categories:

## Metrics
- Application metrics (counters, gauges, histograms)
- Business metrics (KPIs, SLIs)
- Custom CloudWatch metrics
- Prometheus-compatible metrics for Kubernetes

## Logging
- Structured logging improvements
- Log levels and when to use them
- Correlation IDs and trace context
- Error logging best practices
- Business event logging

## Distributed Tracing
- OpenTelemetry instrumentation points
- Trace context propagation
- Critical paths to trace
- Sampling strategies

## Alerting
- CloudWatch alarms to configure
- SLO-based alerting
- Error rate thresholds
- Latency percentiles (p50, p95, p99)

## Dashboards
- Key metrics to visualize
- CloudWatch dashboard layout
- Grafana dashboard recommendations

Provide specific code examples where applicable. Focus on production-ready, actionable recommendations.`;

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
    const suggestions =
      responseBody.results?.[0]?.outputText ?? JSON.stringify(responseBody, null, 2);

    console.log('📊 Telemetry Recommendations:\n');
    console.log(suggestions);

    // Save to file
    const outputPath = path.join(__dirname, 'output', 'telemetry-suggestions.txt');
    fs.writeFileSync(outputPath, suggestions);
    console.log(`\n💾 Suggestions saved to: ${outputPath}`);
  } catch (error: any) {
    console.error('❌ Error calling Bedrock:', error.message);
    process.exit(1);
  }
}

suggestTelemetry();
