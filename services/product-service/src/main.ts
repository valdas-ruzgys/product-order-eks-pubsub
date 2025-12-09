import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Get configuration from environment
  const serviceName = process.env.SERVICE_NAME || 'product-service';
  const serviceVersion = process.env.SERVICE_VERSION || '2.0.0';
  const port = process.env.PORT || 3000;

  // Enable CORS
  app.enableCors();

  // Enable validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Swagger configuration
  const config = new DocumentBuilder()
    .setTitle(`${serviceName} API`)
    .setDescription('Product microservice with Dapr pub/sub publisher using NestJS')
    .setVersion(serviceVersion)
    .addTag('products')
    .addTag('health')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api-docs', app, document);

  await app.listen(port);

  logger.log(`🚀 ${serviceName} v${serviceVersion} is running on http://localhost:${port}`);
  logger.log(`📚 Swagger UI available at http://localhost:${port}/api-docs`);
  logger.log(
    `🔗 Dapr sidecar: ${process.env.DAPR_HOST || '127.0.0.1'}:${process.env.DAPR_HTTP_PORT || '3500'}`,
  );
  logger.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
}

bootstrap().catch((error) => {
  console.error('Failed to start application:', error);
  process.exit(1);
});
