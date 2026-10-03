import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEmail,
  IsIn,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { PageQueryDto } from '../common/pagination.js';
import { blankToNull } from '../common/transforms.js';
import { Role } from '../generated/prisma/enums.js';
import { UserDto } from '../users/user.dto.js';

export class CustomersQuery extends PageQueryDto {
  @ApiPropertyOptional({ description: 'Name or phone' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  search?: string;
}

export class CreateCustomerDto {
  @ApiProperty({ example: '9876543210' })
  @IsString()
  @Length(10, 16)
  phone!: string;

  @ApiProperty({ example: 'Priya Sharma' })
  @IsString()
  @Length(2, 80)
  name!: string;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsEmail()
  email?: string | null;
}

export class UpdateCustomerDto extends PartialType(CreateCustomerDto) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class CustomerListItemDto extends UserDto {
  @ApiProperty() orderCount!: number;
  @ApiProperty({ nullable: true, type: Date }) lastOrderAt!: Date | null;
}

export class CustomerPageDto {
  @ApiProperty({ type: [CustomerListItemDto] }) items!: CustomerListItemDto[];
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty() total!: number;
}

export class CreateStaffDto {
  @ApiProperty({ example: '9876543210' })
  @IsString()
  @Length(10, 16)
  phone!: string;

  @ApiProperty()
  @IsString()
  @Length(2, 80)
  name!: string;

  @ApiProperty({ enum: [Role.ADMIN, Role.SUPER_ADMIN] })
  @IsIn([Role.ADMIN, Role.SUPER_ADMIN])
  role!: Role;
}

export class UpdateStaffDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(2, 80)
  name?: string;

  @ApiPropertyOptional({ enum: [Role.ADMIN, Role.SUPER_ADMIN] })
  @IsOptional()
  @IsIn([Role.ADMIN, Role.SUPER_ADMIN])
  role?: Role;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateSettingsDto {
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(0) minOrderPaise?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(0) deliveryFeePaise?: number;
  @ApiPropertyOptional({ nullable: true, type: Number })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  @Min(0)
  freeDeliveryAbovePaise?: number | null;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) minTurnaroundHours?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(0) bookingCutoffMinutes?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) maxAdvanceDays?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(0) dispatchLeadMinutes?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) dispatchBatchSize?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(5) offerTimeoutSeconds?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) dispatchRetryMinutes?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) driverMaxActiveLegs?: number;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) driverLocationMaxAgeMinutes?: number;
  @ApiPropertyOptional({ nullable: true, type: String, description: 'Send null to clear' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(20)
  supportPhone?: string | null;

  @ApiPropertyOptional({ nullable: true, type: String, description: 'Send null to clear' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsEmail()
  supportEmail?: string | null;

  @ApiPropertyOptional({ nullable: true, type: Number, description: 'Hub latitude. Set with longitude and radius, or clear all three with null.' })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsLatitude()
  serviceCenterLatitude?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsLongitude()
  serviceCenterLongitude?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number, description: 'Kilometres from the hub; null serves any distance' })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(0.5)
  @Max(100)
  serviceRadiusKm?: number | null;

  @ApiPropertyOptional({ type: [String], description: 'Served 6-digit PIN codes; empty serves every PIN code', example: ['500034', '500033'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(1000)
  @Matches(/^[1-9]\d{5}$/, { each: true, message: 'each PIN code must have 6 digits' })
  servicePincodes?: string[];
}

export class DashboardDto {
  @ApiProperty({ description: 'Count of orders per status' }) byStatus!: Record<string, number>;
  @ApiProperty() pickupsToday!: number;
  @ApiProperty() deliveriesToday!: number;
  @ApiProperty() ordersToday!: number;
  @ApiProperty() needsAttention!: number;
  @ApiProperty() driversOnline!: number;
  @ApiProperty() collectedTodayPaise!: number;
  @ApiProperty() collectedLast7DaysPaise!: number;
  @ApiProperty() collectedLast30DaysPaise!: number;
  @ApiProperty({ description: 'Orders placed per IST day, last 14 days' })
  dailyOrders!: { date: string; orders: number; valuePaise: number }[];
}

export class BusinessSettingsDto {
  @ApiProperty() minOrderPaise!: number;
  @ApiProperty() deliveryFeePaise!: number;
  @ApiProperty({ nullable: true, type: Number }) freeDeliveryAbovePaise!: number | null;
  @ApiProperty() minTurnaroundHours!: number;
  @ApiProperty() bookingCutoffMinutes!: number;
  @ApiProperty() maxAdvanceDays!: number;
  @ApiProperty() dispatchLeadMinutes!: number;
  @ApiProperty() dispatchBatchSize!: number;
  @ApiProperty() offerTimeoutSeconds!: number;
  @ApiProperty() dispatchRetryMinutes!: number;
  @ApiProperty() driverMaxActiveLegs!: number;
  @ApiProperty() driverLocationMaxAgeMinutes!: number;
  @ApiProperty({ nullable: true, type: String }) supportPhone!: string | null;
  @ApiProperty({ nullable: true, type: String }) supportEmail!: string | null;
  @ApiProperty({ nullable: true, type: Number }) serviceCenterLatitude!: number | null;
  @ApiProperty({ nullable: true, type: Number }) serviceCenterLongitude!: number | null;
  @ApiProperty({ nullable: true, type: Number }) serviceRadiusKm!: number | null;
  @ApiProperty({ type: [String] }) servicePincodes!: string[];
  @ApiProperty() updatedAt!: Date;
}

export function toSettingsDto(s: BusinessSettingsDto & { id?: number }): BusinessSettingsDto {
  const { id: _id, ...rest } = s;
  return rest;
}
