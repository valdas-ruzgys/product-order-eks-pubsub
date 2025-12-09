import { IsString, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateProductDto {
  @ApiProperty({ example: 'MacBook Pro 16"', description: 'Product name' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'High-performance laptop', description: 'Product description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ example: 2499.99, description: 'Product price' })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ example: 25, description: 'Stock quantity' })
  @IsNumber()
  @Min(0)
  stock: number;

  @ApiPropertyOptional({ example: 'Electronics', description: 'Product category' })
  @IsString()
  @IsOptional()
  category?: string;
}

export class UpdateProductDto {
  @ApiPropertyOptional({ example: 'MacBook Pro 16"', description: 'Product name' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: 'High-performance laptop', description: 'Product description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ example: 2499.99, description: 'Product price' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  price?: number;

  @ApiPropertyOptional({ example: 25, description: 'Stock quantity' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  stock?: number;

  @ApiPropertyOptional({ example: 'Electronics', description: 'Product category' })
  @IsString()
  @IsOptional()
  category?: string;
}
