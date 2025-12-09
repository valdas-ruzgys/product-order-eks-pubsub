import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { Product, ProductEvent } from '../../../entities/product.entity';
import { CreateProductDto, UpdateProductDto } from '../../../dto/product.dto';
import { DaprService } from '../../dapr/services/dapr.service';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class ProductService {
  private readonly logger = new Logger(ProductService.name);
  private readonly products: Map<string, Product> = new Map();
  private readonly topicName: string;

  constructor(
    private readonly daprService: DaprService,
    private readonly configService: ConfigService,
  ) {
    this.topicName = this.configService.get<string>('PRODUCT_TOPIC', 'product-events');
  }

  async findAll(): Promise<Product[]> {
    this.logger.log(`Fetching all products. Total count: ${this.products.size}`);
    return Array.from(this.products.values());
  }

  async findOne(id: string): Promise<Product> {
    this.logger.log(`Fetching product with ID: ${id}`);
    const product = this.products.get(id);

    if (!product) {
      this.logger.warn(`Product not found with ID: ${id}`);
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    return product;
  }

  async create(createProductDto: CreateProductDto): Promise<Product> {
    const productId = uuidv4();
    const now = new Date();

    const product: Product = {
      id: productId,
      ...createProductDto,
      createdAt: now,
      updatedAt: now,
    };

    this.products.set(productId, product);
    this.logger.log(`Product created: ${product.name} (ID: ${productId})`);

    await this.publishProductEvent('product.created', product);

    return product;
  }

  async update(id: string, updateProductDto: UpdateProductDto): Promise<Product> {
    const product = await this.findOne(id);

    const updatedProduct: Product = {
      ...product,
      ...updateProductDto,
      updatedAt: new Date(),
    };

    this.products.set(id, updatedProduct);
    this.logger.log(`Product updated: ${updatedProduct.name} (ID: ${id})`);

    await this.publishProductEvent('product.updated', updatedProduct);

    return updatedProduct;
  }

  async remove(id: string): Promise<Product> {
    const product = await this.findOne(id);

    this.products.delete(id);
    this.logger.log(`Product deleted: ${product.name} (ID: ${id})`);

    await this.publishProductEvent('product.deleted', product);

    return product;
  }

  private async publishProductEvent(
    eventType: 'product.created' | 'product.updated' | 'product.deleted',
    product: Product,
  ): Promise<void> {
    const event: ProductEvent = {
      eventId: uuidv4(),
      eventType,
      timestamp: new Date(),
      productId: product.id,
      product,
    };

    try {
      await this.daprService.publishEvent(this.topicName, event);
      this.logger.log(
        `✅ Event published: ${eventType} for product ${product.name} (ID: ${product.id})`,
      );
    } catch (error) {
      this.logger.error(`❌ Failed to publish ${eventType} event for product ${product.id}`, error);
      throw error;
    }
  }
}
