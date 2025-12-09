import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { Order, OrderStatus } from '../../../entities/order.entity';
import { CreateOrderDto, UpdateOrderDto } from '../../../dto/order.dto';
import { ProductCacheService } from './product-cache.service';
import { OrderRepositoryService } from './order-repository.service';

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(
    private readonly productCache: ProductCacheService,
    private readonly orderRepository: OrderRepositoryService,
  ) {}

  async findAll(): Promise<Order[]> {
    const orders = this.orderRepository.find();
    this.logger.log(`Fetching all orders. Total count: ${orders.length}`);

    return orders;
  }

  async findOne(id: string): Promise<Order> {
    this.logger.log(`Fetching order with ID: ${id}`);
    const order = this.orderRepository.findById(id);

    if (!order) {
      this.logger.warn(`Order not found with ID: ${id}`);
      throw new NotFoundException(`Order with ID ${id} not found`);
    }

    return order;
  }

  async create(createOrderDto: CreateOrderDto): Promise<Order> {
    const { productId, quantity, customerName } = createOrderDto;

    const product = this.productCache.get(productId);
    if (!product) {
      this.logger.error(`Product not found in cache: ${productId}`);
      throw new BadRequestException(
        `Product with ID ${productId} not found. Please ensure the product exists.`,
      );
    }

    const orderId = uuidv4();
    const now = new Date();
    const totalPrice = product.price * quantity;

    const order: Order = {
      id: orderId,
      productId,
      quantity,
      totalPrice,
      status: OrderStatus.PENDING,
      customerName,
      createdAt: now,
      updatedAt: now,
    };

    this.orderRepository.save(order);
    this.logger.log(
      `✅ Order created: ${orderId} for product ${product.name} (Qty: ${quantity}, Total: $${totalPrice})`,
    );

    return order;
  }

  async update(id: string, updateOrderDto: UpdateOrderDto): Promise<Order> {
    const order = await this.findOne(id);

    const updatedOrder: Order = {
      ...order,
      ...updateOrderDto,
      updatedAt: new Date(),
    };

    this.orderRepository.save(updatedOrder);
    this.logger.log(`Order updated: ${id} (Status: ${updatedOrder.status})`);

    return updatedOrder;
  }

  async remove(id: string): Promise<Order> {
    const order = await this.findOne(id);
    this.orderRepository.delete(id);
    this.logger.log(`Order deleted: ${id}`);
    return order;
  }

  getCacheStats() {
    return {
      totalProducts: this.productCache.size(),
      totalOrders: this.orderRepository.count(),
      products: this.productCache.getAll(),
    };
  }
}
