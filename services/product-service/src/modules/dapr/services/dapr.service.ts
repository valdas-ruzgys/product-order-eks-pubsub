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

  async publishEvent<T extends object = Record<string, unknown>>(
    topic: string,
    data: T,
  ): Promise<void> {
    try {
      this.logger.log(`Publishing event to topic: ${topic}`);
      this.logger.debug(`Event data: ${JSON.stringify(data)}`);

      await this.daprClient.pubsub.publish(this.pubsubName, topic, data);

      this.logger.log(`Event published successfully to topic: ${topic}`);
    } catch (error) {
      this.logger.error(`Failed to publish event to topic: ${topic}`, error);
      throw error;
    }
  }

  async saveState<T = Record<string, unknown>>(
    storeName: string,
    key: string,
    value: T,
  ): Promise<void> {
    try {
      this.logger.log(`Saving state: ${key} to store: ${storeName}`);
      await this.daprClient.state.save(storeName, [{ key, value }]);
      this.logger.log(`State saved successfully: ${key}`);
    } catch (error) {
      this.logger.error(`Failed to save state: ${key}`, error);
      throw error;
    }
  }

  async getState<T = Record<string, unknown>>(storeName: string, key: string): Promise<T | null> {
    try {
      this.logger.log(`Getting state: ${key} from store: ${storeName}`);
      const result = await this.daprClient.state.get(storeName, key);
      return result as T;
    } catch (error) {
      this.logger.error(`Failed to get state: ${key}`, error);
      throw error;
    }
  }

  getClient(): DaprClient {
    return this.daprClient;
  }
}
