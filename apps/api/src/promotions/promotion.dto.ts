import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { blankToNull } from '../common/transforms.js';
import { IsImageUrl } from '../common/validators.js';
import type { Promotion } from '../generated/prisma/client.js';
import { DiscountType } from '../generated/prisma/enums.js';

export class CreatePromotionDto {
  @ApiProperty({ example: 'FIRST50' })
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @Matches(/^[A-Z0-9]{3,20}$/, { message: 'code must be 3–20 letters or digits' })
  code!: string;

  @ApiProperty({ example: '50% off your first order' })
  @IsString()
  @Length(3, 80)
  title!: string;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(500)
  description?: string | null;

  @ApiProperty({ enum: DiscountType, enumName: 'DiscountType' })
  @IsEnum(DiscountType)
  discountType!: DiscountType;

  @ApiProperty({ description: 'PERCENT: 1–100. FLAT: amount in paise.' })
  @IsInt()
  @Min(1)
  discountValue!: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  minOrderPaise?: number;

  @ApiPropertyOptional({ nullable: true, type: Number })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  @Min(1)
  maxDiscountPaise?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number, description: 'How many times one customer can use it' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  @Min(1)
  perCustomerLimit?: number | null;

  @ApiProperty()
  @Type(() => Date)
  @IsDate()
  validFrom!: Date;

  @ApiProperty()
  @Type(() => Date)
  @IsDate()
  validTo!: Date;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsImageUrl()
  imageUrl?: string | null;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdatePromotionDto extends PartialType(CreatePromotionDto) {}

export class PromotionDto {
  @ApiProperty() id!: string;
  @ApiProperty() code!: string;
  @ApiProperty() title!: string;
  @ApiProperty({ nullable: true, type: String }) description!: string | null;
  @ApiProperty({ enum: DiscountType, enumName: 'DiscountType' }) discountType!: DiscountType;
  @ApiProperty() discountValue!: number;
  @ApiProperty() minOrderPaise!: number;
  @ApiProperty({ nullable: true, type: Number }) maxDiscountPaise!: number | null;
  @ApiProperty({ nullable: true, type: Number }) perCustomerLimit!: number | null;
  @ApiProperty() validFrom!: Date;
  @ApiProperty() validTo!: Date;
  @ApiProperty({ nullable: true, type: String }) imageUrl!: string | null;
  @ApiProperty() isActive!: boolean;
}

export function toPromotionDto(p: Promotion): PromotionDto {
  return {
    id: p.id,
    code: p.code,
    title: p.title,
    description: p.description,
    discountType: p.discountType,
    discountValue: p.discountValue,
    minOrderPaise: p.minOrderPaise,
    maxDiscountPaise: p.maxDiscountPaise,
    perCustomerLimit: p.perCustomerLimit,
    validFrom: p.validFrom,
    validTo: p.validTo,
    imageUrl: p.imageUrl,
    isActive: p.isActive,
  };
}
