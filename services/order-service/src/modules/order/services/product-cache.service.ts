import { Injectable, Logger } from '@nestjs/common';
import { Product } from '../../../entities/order.entity';

@Injectable()
export class ProductCacheService {
  private readonly logger = new Logger(ProductCacheService.name);
  private readonly productCache: Map<string, Product> = new Map();

  get(productId: string): Product | undefined {
    return this.productCache.get(productId);
  }

  set(productId: string, product: Product): void {
    this.productCache.set(productId, product);
    this.logger.log(`💾 Cached product: ${product.name} (ID: ${productId})`);
  }

  delete(productId: string): boolean {
    const product = this.productCache.get(productId);
    const deleted = this.productCache.delete(productId);

    if (deleted && product) {
      this.logger.log(`🗑️ Removed product from cache: ${product.name} (ID: ${productId})`);
    }

    return deleted;
  }

  has(productId: string): boolean {
    return this.productCache.has(productId);
  }

  getAll(): Product[] {
    return Array.from(this.productCache.values());
  }

  size(): number {
    return this.productCache.size;
  }

  clear(): void {
    const size = this.productCache.size;
    this.productCache.clear();
    this.logger.log(`🗑️ Cleared product cache (${size} products removed)`);
  }
}
