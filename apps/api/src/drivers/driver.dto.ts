import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsEnum, IsIn, IsLatitude, IsLongitude, IsOptional, IsString, IsUUID, Length, MaxLength, ValidateIf } from 'class-validator';
import { blankToNull } from '../common/transforms.js';
import { fromDbDate } from '../common/time.js';
import type { DispatchOffer, Order, OrderItem } from '../generated/prisma/client.js';
import { DispatchLeg, PaymentMethod, TimeSlot } from '../generated/prisma/enums.js';
import type { OrderAddressDto } from '../orders/order.dto.js';
import { slotLabel } from '../scheduling/schedule-rules.js';

export class SetOnlineDto {
  @ApiProperty()
  @IsBoolean()
  isOnline!: boolean;
}

export class LocationDto {
  @ApiProperty({ example: 17.4126 })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 78.4482 })
  @IsLongitude()
  longitude!: number;
}

export class DeliverDto {
  @ApiPropertyOptional({ description: 'Set true when cash for the amount due was collected' })
  @IsOptional()
  @IsBoolean()
  collectedCash?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}

export class TasksQuery {
  @ApiPropertyOptional({ enum: ['active', 'history'], default: 'active' })
  @IsOptional()
  @IsIn(['active', 'history'])
  scope: 'active' | 'history' = 'active';
}

export class AssignDto {
  @ApiProperty({ enum: DispatchLeg, enumName: 'DispatchLeg' })
  @IsEnum(DispatchLeg)
  leg!: DispatchLeg;

  @ApiProperty()
  @IsUUID()
  driverId!: string;
}

export class UnassignDto {
  @ApiProperty({ enum: DispatchLeg, enumName: 'DispatchLeg' })
  @IsEnum(DispatchLeg)
  leg!: DispatchLeg;
}

const phoneTransform = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class CreateDriverDto {
  @ApiProperty({ example: '9876543210' })
  @Transform(phoneTransform)
  @IsString()
  @Length(10, 16)
  phone!: string;

  @ApiProperty({ example: 'Ravi Kumar' })
  @IsString()
  @Length(2, 80)
  name!: string;

  @ApiPropertyOptional({ example: 'TS09AB1234', nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(20)
  vehicleNumber?: string | null;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(30)
  licenseNumber?: string | null;
}

export class UpdateDriverDto extends PartialType(CreateDriverDto) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** What a driver sees before accepting: the area, not the exact address or phone. */
export class OfferDto {
  @ApiProperty() offerId!: string;
  @ApiProperty() orderId!: string;
  @ApiProperty() orderNumber!: string;
  @ApiProperty({ enum: DispatchLeg, enumName: 'DispatchLeg' }) leg!: DispatchLeg;
  @ApiProperty() expiresAt!: Date;
  @ApiProperty({ nullable: true, type: Number }) distanceKm!: number | null;
  @ApiProperty() area!: string;
  @ApiProperty() pincode!: string;
  @ApiProperty() date!: string;
  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' }) slot!: TimeSlot;
  @ApiProperty() slotLabel!: string;
  @ApiProperty() itemCount!: number;
  @ApiProperty() totalPaise!: number;
  @ApiProperty({ enum: PaymentMethod, enumName: 'PaymentMethod' }) paymentMethod!: PaymentMethod;
}

export function toOfferDto(o: DispatchOffer & { order: Order & { items: OrderItem[] } }): OfferDto {
  const pickup = o.leg === DispatchLeg.PICKUP;
  const address = (pickup ? o.order.pickupAddress : o.order.deliveryAddress) as unknown as OrderAddressDto;
  const slot = pickup ? o.order.pickupSlot : o.order.deliverySlot;
  return {
    offerId: o.id,
    orderId: o.orderId,
    orderNumber: o.order.orderNumber,
    leg: o.leg,
    expiresAt: o.expiresAt,
    distanceKm: o.distanceKm === null ? null : Math.round(o.distanceKm * 10) / 10,
    area: [address.area, address.city].filter(Boolean).join(', '),
    pincode: address.pincode,
    date: fromDbDate(pickup ? o.order.pickupDate : o.order.deliveryDate),
    slot,
    slotLabel: slotLabel(slot),
    itemCount: o.order.items.reduce((n, i) => n + i.quantity, 0),
    totalPaise: o.order.totalPaise,
    paymentMethod: o.order.paymentMethod,
  };
}

export class DriverListItemDto {
  @ApiProperty() id!: string;
  @ApiProperty() phone!: string;
  @ApiProperty({ nullable: true, type: String }) name!: string | null;
  @ApiProperty() isActive!: boolean;
  @ApiProperty() isOnline!: boolean;
  @ApiProperty({ nullable: true, type: String }) vehicleNumber!: string | null;
  @ApiProperty({ nullable: true, type: String }) licenseNumber!: string | null;
  @ApiProperty({ nullable: true, type: Number }) latitude!: number | null;
  @ApiProperty({ nullable: true, type: Number }) longitude!: number | null;
  @ApiProperty({ nullable: true, type: Date }) locationUpdatedAt!: Date | null;
  @ApiProperty({ nullable: true, type: Date }) lastLoginAt!: Date | null;
  @ApiProperty() activeLegs!: number;
}
