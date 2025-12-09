import { ApiProperty } from '@nestjs/swagger';

export class Product {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'MacBook Pro 16"' })
  name: string;

  @ApiProperty({ example: 'High-performance laptop', required: false })
  description?: string;

  @ApiProperty({ example: 2499.99 })
  price: number;

  @ApiProperty({ example: 25 })
  stock: number;

  @ApiProperty({ example: 'Electronics', required: false })
  category?: string;

  @ApiProperty({ example: '2025-11-21T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2025-11-21T10:30:00.000Z' })
  updatedAt: Date;
}

export interface ProductEvent {
  eventId: string;
  eventType: 'product.created' | 'product.updated' | 'product.deleted';
  timestamp: Date;
  product?: Product;
  productId: string;
}
