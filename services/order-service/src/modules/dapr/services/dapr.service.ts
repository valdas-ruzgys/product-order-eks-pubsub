import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { DaprClient } from '@dapr/dapr';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class DaprService implements OnModuleInit {
  private readonly logger = new Logger(DaprService.name);
  private daprClient: DaprClient;
  private readonly daprHost: string;
  private readonly daprPort: string;
  private readonly pubsubName: string;

  constructor(private configService: ConfigService) {
    this.daprHost = this.configService.get<string>('DAPR_HOST', '127.0.0.1');
    this.daprPort = this.configService.get<string>('DAPR_HTTP_PORT', '3500');
    this.pubsubName = this.configService.get<string>('PUBSUB_NAME', 'product-pubsub');

    this.daprClient = new DaprClient({
      daprHost: this.daprHost,
      daprPort: this.daprPort,
    });
  }

  async onModuleInit() {
    await this.initialize();
  }

  private async initialize(): Promise<void> {
    try {
      this.logger.log(`Initializing Dapr client...`);
      this.logger.log(`Dapr Host: ${this.daprHost}, Port: ${this.daprPort}`);
      this.logger.log(`Pub/Sub Name: ${this.pubsubName}`);
      this.logger.log('Dapr client initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize Dapr client', error);
      throw error;
    }
  }

  getClient(): DaprClient {
    return this.daprClient;
  }
}
