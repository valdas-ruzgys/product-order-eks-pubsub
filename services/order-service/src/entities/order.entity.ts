import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  CANCELLED = 'CANCELLED',
  COMPLETED = 'COMPLETED',
}

export class Order {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  productId: string;

  @ApiProperty({ example: 2 })
  quantity: number;

  @ApiProperty({ example: 2499.99 })
  totalPrice: number;

  @ApiProperty({ enum: OrderStatus, example: OrderStatus.PENDING })
  status: OrderStatus;

  @ApiPropertyOptional({ example: 'John Doe' })
  customerName?: string;

  @ApiProperty({ example: '2025-11-21T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2025-11-21T10:30:00.000Z' })
  updatedAt: Date;
}

export class Product {
  id: string;
  name: string;
  description?: string;
  price: number;
  stock: number;
  category?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ProductEvent {
  eventId: string;
  eventType: 'product.created' | 'product.updated' | 'product.deleted';
  timestamp: Date;
  product?: Product;
  productId: string;
}
