import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, IsEnum, IsOptional, IsString, Length, MaxLength, ValidateIf } from 'class-validator';
import { blankToNull } from '../common/transforms.js';
import type { DriverProfile, User } from '../generated/prisma/client.js';
import { ClientApp, DevicePlatform, Role } from '../generated/prisma/enums.js';

export class UserDto {
  @ApiProperty() id!: string;
  @ApiProperty({ example: '+919876543210' }) phone!: string;
  @ApiProperty({ nullable: true, type: String }) name!: string | null;
  @ApiProperty({ nullable: true, type: String }) email!: string | null;
  @ApiProperty({ enum: Role, enumName: 'Role' }) role!: Role;
  @ApiProperty() isActive!: boolean;
  /** False until the customer has entered a name. */
  @ApiProperty() isProfileComplete!: boolean;
  @ApiProperty() createdAt!: Date;
}

export function toUserDto(u: User): UserDto {
  return {
    id: u.id,
    phone: u.phone,
    name: u.name,
    email: u.email,
    role: u.role,
    isActive: u.isActive,
    isProfileComplete: Boolean(u.name),
    createdAt: u.createdAt,
  };
}

export class DriverProfileDto {
  @ApiProperty({ nullable: true, type: String }) vehicleNumber!: string | null;
  @ApiProperty({ nullable: true, type: String }) licenseNumber!: string | null;
  @ApiProperty() isOnline!: boolean;
  @ApiProperty({ nullable: true, type: Number }) latitude!: number | null;
  @ApiProperty({ nullable: true, type: Number }) longitude!: number | null;
  @ApiProperty({ nullable: true, type: Date }) locationUpdatedAt!: Date | null;
}

export function toDriverProfileDto(d: DriverProfile): DriverProfileDto {
  return {
    vehicleNumber: d.vehicleNumber,
    licenseNumber: d.licenseNumber,
    isOnline: d.isOnline,
    latitude: d.latitude,
    longitude: d.longitude,
    locationUpdatedAt: d.locationUpdatedAt,
  };
}

export class MeDto extends UserDto {
  @ApiPropertyOptional({ type: DriverProfileDto, nullable: true }) driver!: DriverProfileDto | null;
}

export class UpdateMeDto {
  @ApiPropertyOptional({ example: 'Priya Sharma' })
  @IsOptional()
  @IsString()
  @Length(2, 80)
  name?: string;

  @ApiPropertyOptional({ nullable: true, type: String, example: 'priya@example.com' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsEmail()
  @MaxLength(120)
  email?: string | null;
}

export class RegisterDeviceDto {
  @ApiProperty()
  @IsString()
  @Length(10, 4096)
  fcmToken!: string;

  @ApiProperty({ enum: DevicePlatform, enumName: 'DevicePlatform' })
  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;

  @ApiProperty({ enum: ClientApp, enumName: 'ClientApp' })
  @IsEnum(ClientApp)
  app!: ClientApp;
}

export class RemoveDeviceDto {
  @ApiProperty()
  @IsString()
  @Length(10, 4096)
  fcmToken!: string;
}
