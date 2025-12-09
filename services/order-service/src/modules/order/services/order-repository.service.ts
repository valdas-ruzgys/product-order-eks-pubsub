import { Injectable, Logger } from '@nestjs/common';
import { Order, OrderStatus } from '../../../entities/order.entity';

@Injectable()
export class OrderRepositoryService {
  private readonly logger = new Logger(OrderRepositoryService.name);
  private readonly orders: Map<string, Order> = new Map();

  find(status?: OrderStatus): Order[] {
    if (!status) {
      return Array.from(this.orders.values());
    }

    return Array.from(this.orders.values()).filter((order) => order.status === status);
  }

  findById(id: string): Order | undefined {
    return this.orders.get(id);
  }

  findByProductId(productId: string, status?: OrderStatus): Order[] {
    return Array.from(this.orders.values()).filter((order) => {
      const matchesProduct = order.productId === productId;
      const matchesStatus = status ? order.status === status : true;

      return matchesProduct && matchesStatus;
    });
  }

  save(order: Order): Order {
    const isNew = !this.orders.has(order.id);
    this.orders.set(order.id, order);

    if (isNew) {
      this.logger.log(`💾 Created order: ${order.id}`);
    } else {
      this.logger.log(`💾 Updated order: ${order.id}`);
    }

    return order;
  }

  delete(id: string): boolean {
    const deleted = this.orders.delete(id);

    if (deleted) {
      this.logger.log(`🗑️ Deleted order: ${id}`);
    }

    return deleted;
  }

  exists(id: string): boolean {
    return this.orders.has(id);
  }

  count(): number {
    return this.orders.size;
  }

  countByStatus(status: OrderStatus): number {
    return this.find(status).length;
  }

  clear(): void {
    const size = this.orders.size;
    this.orders.clear();
    this.logger.warn(`🗑️ Cleared all orders (${size} orders removed)`);
  }
}
