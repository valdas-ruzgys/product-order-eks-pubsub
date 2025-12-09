import { Controller, Post, Get, Logger, HttpCode, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ProductEventHandlerService } from '../services/product-event-handler.service';
import { ProductEvent } from '../../../entities/order.entity';

@ApiTags('events')
@Controller()
export class EventController {
  private readonly logger = new Logger(EventController.name);

  constructor(private readonly productEventHandler: ProductEventHandlerService) {}

  @Get('dapr/subscribe')
  @ApiOperation({ summary: 'Dapr subscription endpoint' })
  @ApiResponse({
    status: 200,
    description: 'Return subscription configuration',
  })
  getDaprSubscriptions() {
    this.logger.log('GET /dapr/subscribe - Returning Dapr subscriptions');
    return [
      {
        pubsubname: 'product-pubsub',
        topic: 'product-events',
        route: '/product-events',
        metadata: { rawPayload: 'true', 'content-type': 'application/json' },
      },
    ];
  }

  @Post('product-events')
  @HttpCode(200)
  @ApiOperation({ summary: 'Handle product events from Dapr' })
  @ApiResponse({ status: 200, description: 'Event processed successfully' })
  @ApiResponse({ status: 500, description: 'Event processing failed' })
  async handleProductEvent(@Body() body: any) {
    try {
      this.logger.log(`📨 Received product event from Dapr`);

      // Dapr sends Cloud Events with base64-encoded data
      if (!body.data_base64) {
        this.logger.error(`Unknown event format. Body keys: ${Object.keys(body)}`);
        throw new Error('Unknown event format');
      }
      // Decode base64 data
      const decodedData = Buffer.from(body.data_base64, 'base64').toString('utf-8');
      const parsedData = JSON.parse(decodedData);

      // The decoded data contains the Cloud Event structure with nested data field
      const event: ProductEvent = parsedData.data;

      this.logger.debug(`Recieved event: ${JSON.stringify(event)}`);

      this.logger.log(`📨 Processing event type: ${event.eventType}`);

      switch (event.eventType) {
        case 'product.created':
          await this.productEventHandler.handleProductCreated(event);
          break;
        case 'product.updated':
          await this.productEventHandler.handleProductUpdated(event);
          break;
        case 'product.deleted':
          await this.productEventHandler.handleProductDeleted(event);
          break;
        default:
          this.logger.warn(`Unknown event type: ${event.eventType}`);
      }

      this.logger.log(`✅ Event processed successfully: ${event.eventType}`);
      return { success: true };
    } catch (error) {
      this.logger.error('❌ Error processing product event');
      this.logger.error(error.stack || error.message || error);
      throw error;
    }
  }
}
