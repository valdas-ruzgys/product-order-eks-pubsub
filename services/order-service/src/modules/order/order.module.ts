import { Module } from '@nestjs/common';
import { OrderController } from './controllers/order.controller';
import { EventController } from './controllers/event.controller';
import { OrderService } from './services/order.service';
import { ProductCacheService } from './services/product-cache.service';
import { OrderRepositoryService } from './services/order-repository.service';
import { ProductEventHandlerService } from './services/product-event-handler.service';
import { DaprModule } from '../dapr/dapr.module';

@Module({
  imports: [DaprModule],
  controllers: [OrderController, EventController],
  providers: [
    OrderService,
    ProductCacheService,
    OrderRepositoryService,
    ProductEventHandlerService,
  ],
  exports: [OrderService, ProductCacheService, OrderRepositoryService, ProductEventHandlerService],
})
export class OrderModule {}
