import { Injectable, Logger } from '@nestjs/common';
import { Order, OrderStatus, ProductEvent } from '../../../entities/order.entity';
import { ProductCacheService } from './product-cache.service';
import { OrderRepositoryService } from './order-repository.service';

@Injectable()
export class ProductEventHandlerService {
  private readonly logger = new Logger(ProductEventHandlerService.name);

  constructor(
    private readonly productCache: ProductCacheService,
    private readonly orderRepository: OrderRepositoryService,
  ) {}

  async handleProductCreated(event: ProductEvent): Promise<void> {
    const { product, productId } = event;

    if (product) {
      this.productCache.set(productId, product);
      this.logger.log(`✅ Product created: ${product.name} (ID: ${productId})`);
    }
  }

  async handleProductUpdated(event: ProductEvent): Promise<void> {
    const { product, productId } = event;

    if (!product) {
      return;
    }

    this.productCache.set(productId, product);
    this.logger.log(`✅ Product updated: ${product.name} (ID: ${productId})`);

    const pendingOrders = this.orderRepository.findByProductId(productId, OrderStatus.PENDING);

    if (pendingOrders.length === 0) {
      this.logger.log(`No pending orders found for product ${productId}`);
      return;
    }

    for (const order of pendingOrders) {
      const newTotalPrice = product.price * order.quantity;
      const updatedOrder: Order = {
        ...order,
        totalPrice: newTotalPrice,
        updatedAt: new Date(),
      };
      this.orderRepository.save(updatedOrder);
      this.logger.log(`📝 Updated pending order ${order.id}: New total price: $${newTotalPrice}`);
    }

    this.logger.log(
      `✅ Updated ${pendingOrders.length} pending order(s) for product ${product.name}`,
    );
  }

  async handleProductDeleted(event: ProductEvent): Promise<void> {
    const { productId } = event;

    const product = this.productCache.get(productId);
    if (product) {
      this.productCache.delete(productId);
      this.logger.log(`❌ Product deleted: ${product.name} (ID: ${productId})`);
    }

    const pendingOrders = this.orderRepository.findByProductId(productId, OrderStatus.PENDING);

    if (pendingOrders.length === 0) {
      this.logger.log(`No pending orders to cancel for product ${productId}`);
      return;
    }

    for (const order of pendingOrders) {
      const cancelledOrder: Order = {
        ...order,
        status: OrderStatus.CANCELLED,
        updatedAt: new Date(),
      };
      this.orderRepository.save(cancelledOrder);
      this.logger.log(`🚫 Cancelled pending order ${order.id} due to product deletion`);
    }

    this.logger.log(`✅ Cancelled ${pendingOrders.length} pending order(s) for deleted product`);
  }

  getCacheStats() {
    return {
      totalProducts: this.productCache.size(),
      totalOrders: this.orderRepository.count(),
      pendingOrders: this.orderRepository.find(OrderStatus.PENDING).length,
      completedOrders: this.orderRepository.find(OrderStatus.COMPLETED).length,
      cancelledOrders: this.orderRepository.find(OrderStatus.CANCELLED).length,
      products: this.productCache.getAll(),
    };
  }
}
