import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { blankToNull } from '../common/transforms.js';
import { IsImageUrl } from '../common/validators.js';
import type { CatalogCategory, CatalogItem } from '../generated/prisma/client.js';
import { ItemUnit } from '../generated/prisma/enums.js';

export class CreateCategoryDto {
  @ApiProperty({ example: 'Ironing' })
  @IsString()
  @Length(2, 60)
  name!: string;

  @ApiProperty({ example: 'ironing' })
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, { message: 'slug must be lowercase words separated by hyphens' })
  @Length(2, 60)
  slug!: string;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsImageUrl()
  imageUrl?: string | null;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateCategoryDto extends PartialType(CreateCategoryDto) {}

export class CreateItemDto {
  @ApiProperty()
  @IsUUID()
  categoryId!: string;

  @ApiProperty({ example: 'Shirt' })
  @IsString()
  @Length(2, 80)
  name!: string;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(300)
  description?: string | null;

  @ApiPropertyOptional({ enum: ItemUnit, enumName: 'ItemUnit', default: ItemUnit.PIECE })
  @IsOptional()
  @IsEnum(ItemUnit)
  unit?: ItemUnit;

  @ApiProperty({ example: 1500, description: 'Price in paise (₹15.00 = 1500)' })
  @IsInt()
  @Min(1)
  @Max(10_000_000)
  pricePaise!: number;

  @ApiPropertyOptional({ nullable: true, type: Number, example: 1200, description: 'Discounted price in paise; must be below pricePaise' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  @Min(1)
  offerPricePaise?: number | null;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsImageUrl()
  imageUrl?: string | null;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateItemDto extends PartialType(CreateItemDto) {}

export class CatalogItemDto {
  @ApiProperty() id!: string;
  @ApiProperty() categoryId!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ nullable: true, type: String }) description!: string | null;
  @ApiProperty({ enum: ItemUnit, enumName: 'ItemUnit' }) unit!: ItemUnit;
  @ApiProperty() pricePaise!: number;
  @ApiProperty({ nullable: true, type: Number }) offerPricePaise!: number | null;
  /** What the customer pays per unit. */
  @ApiProperty() effectivePricePaise!: number;
  @ApiProperty({ nullable: true, type: String }) imageUrl!: string | null;
  @ApiProperty() sortOrder!: number;
  @ApiProperty() isActive!: boolean;
}

export class CatalogCategoryDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() slug!: string;
  @ApiProperty({ nullable: true, type: String }) imageUrl!: string | null;
  @ApiProperty() sortOrder!: number;
  @ApiProperty() isActive!: boolean;
  @ApiProperty({ type: [CatalogItemDto] }) items!: CatalogItemDto[];
}

export function toItemDto(i: CatalogItem): CatalogItemDto {
  return {
    id: i.id,
    categoryId: i.categoryId,
    name: i.name,
    description: i.description,
    unit: i.unit,
    pricePaise: i.pricePaise,
    offerPricePaise: i.offerPricePaise,
    effectivePricePaise: i.offerPricePaise ?? i.pricePaise,
    imageUrl: i.imageUrl,
    sortOrder: i.sortOrder,
    isActive: i.isActive,
  };
}

export function toCategoryDto(c: CatalogCategory & { items: CatalogItem[] }): CatalogCategoryDto {
  return {
    id: c.id,
    name: c.name,
    slug: c.slug,
    imageUrl: c.imageUrl,
    sortOrder: c.sortOrder,
    isActive: c.isActive,
    items: c.items.map(toItemDto),
  };
}
