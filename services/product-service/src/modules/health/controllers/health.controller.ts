import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('health')
@Controller()
export class HealthController {
  private readonly serviceName: string;
  private readonly serviceVersion: string;

  constructor(private configService: ConfigService) {
    this.serviceName = this.configService.get<string>('SERVICE_NAME', 'product-service');
    this.serviceVersion = this.configService.get<string>('SERVICE_VERSION', '2.0.0');
  }

  @Get('health')
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  health() {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: this.serviceName,
    };
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is ready' })
  ready() {
    return {
      status: 'ready',
      timestamp: new Date().toISOString(),
      service: this.serviceName,
    };
  }

  @Get()
  @ApiOperation({ summary: 'Service info endpoint' })
  @ApiResponse({ status: 200, description: 'Service information' })
  info() {
    return {
      service: this.serviceName,
      version: this.serviceVersion,
      description: 'Product microservice with Dapr pub/sub publisher using NestJS',
      framework: 'NestJS',
      timestamp: new Date().toISOString(),
      environment: this.configService.get<string>('NODE_ENV', 'development'),
    };
  }
}
