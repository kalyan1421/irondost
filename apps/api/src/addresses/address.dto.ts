import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  Length,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { blankToNull } from '../common/transforms.js';
import type { Address } from '../generated/prisma/client.js';
import { checkServiceArea, NOT_SERVICEABLE_REASONS, type NotServiceableReason, type ServiceAreaSettings } from '../settings/service-area.js';

export class CreateAddressDto {
  @ApiPropertyOptional({ example: 'Home', default: 'Home' })
  @IsOptional()
  @IsString()
  @Length(1, 30)
  label?: string;

  @ApiProperty({ example: 'Flat 302' })
  @IsString()
  @Length(1, 60)
  houseNo!: string;

  @ApiPropertyOptional({ nullable: true, type: String, example: 'Lake View Apartments' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(100)
  building?: string | null;

  @ApiProperty({ example: 'Road No. 12' })
  @IsString()
  @Length(2, 150)
  street!: string;

  @ApiPropertyOptional({ nullable: true, type: String, example: 'Banjara Hills' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(100)
  area?: string | null;

  @ApiPropertyOptional({ nullable: true, type: String, example: 'Opposite City Centre Mall' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(150)
  landmark?: string | null;

  @ApiProperty({ example: 'Hyderabad' })
  @IsString()
  @Length(2, 60)
  city!: string;

  @ApiProperty({ example: 'Telangana' })
  @IsString()
  @Length(2, 60)
  state!: string;

  @ApiProperty({ example: '500034' })
  @Matches(/^[1-9]\d{5}$/, { message: 'pincode must be a 6-digit Indian PIN code' })
  pincode!: string;

  @ApiPropertyOptional({ nullable: true, type: Number, example: 17.4126 })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsLatitude()
  latitude?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number, example: 78.4482 })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsLongitude()
  longitude?: number | null;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}

export class UpdateAddressDto extends PartialType(CreateAddressDto) {}

export class AddressDto {
  @ApiProperty() id!: string;
  @ApiProperty() label!: string;
  @ApiProperty() houseNo!: string;
  @ApiProperty({ nullable: true, type: String }) building!: string | null;
  @ApiProperty() street!: string;
  @ApiProperty({ nullable: true, type: String }) area!: string | null;
  @ApiProperty({ nullable: true, type: String }) landmark!: string | null;
  @ApiProperty() city!: string;
  @ApiProperty() state!: string;
  @ApiProperty() pincode!: string;
  @ApiProperty({ nullable: true, type: Number }) latitude!: number | null;
  @ApiProperty({ nullable: true, type: Number }) longitude!: number | null;
  @ApiProperty() isPrimary!: boolean;
  /** One-line address for display. */
  @ApiProperty() formatted!: string;
  /** Whether pickups can be booked here under the current service area. */
  @ApiProperty() serviceable!: boolean;
  @ApiProperty({ enum: NOT_SERVICEABLE_REASONS, enumName: 'NotServiceableReason', nullable: true })
  notServiceableReason!: NotServiceableReason | null;
}

export function formatAddress(a: Pick<Address, 'houseNo' | 'building' | 'street' | 'area' | 'landmark' | 'city' | 'pincode'>): string {
  return [a.houseNo, a.building, a.street, a.area, a.landmark && `near ${a.landmark}`, `${a.city} ${a.pincode}`]
    .filter(Boolean)
    .join(', ');
}

export function toAddressDto(a: Address, area: ServiceAreaSettings): AddressDto {
  const { serviceable, reason } = checkServiceArea(a, area);
  return {
    id: a.id,
    label: a.label,
    houseNo: a.houseNo,
    building: a.building,
    street: a.street,
    area: a.area,
    landmark: a.landmark,
    city: a.city,
    state: a.state,
    pincode: a.pincode,
    latitude: a.latitude,
    longitude: a.longitude,
    isPrimary: a.isPrimary,
    formatted: formatAddress(a),
    serviceable,
    notServiceableReason: reason,
  };
}
