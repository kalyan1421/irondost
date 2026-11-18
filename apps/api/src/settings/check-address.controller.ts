import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsLatitude, IsLongitude, IsOptional, Matches } from 'class-validator';
import { Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import { Role } from '../generated/prisma/enums.js';
import { checkStaffArea, distanceFromCentre, NOT_SERVICEABLE_REASONS, type NotServiceableReason } from './service-area.js';
import { SettingsService } from './settings.service.js';

export class CheckAddressDto {
  @ApiPropertyOptional({ type: Number, example: 17.4126, description: 'Send with longitude' })
  @IsOptional()
  @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional({ type: Number, example: 78.4482, description: 'Send with latitude' })
  @IsOptional()
  @IsLongitude()
  longitude?: number;

  @ApiPropertyOptional({ example: '500034' })
  @IsOptional()
  @Matches(/^[1-9]\d{5}$/, { message: 'pincode must be a 6-digit Indian PIN code' })
  pincode?: string;
}

export class CheckAddressResultDto {
  @ApiProperty({ description: 'Whether a pickup can be booked here under the saved settings' }) served!: boolean;
  @ApiProperty({ enum: NOT_SERVICEABLE_REASONS, enumName: 'NotServiceableReason', nullable: true }) reason!: NotServiceableReason | null;
  @ApiProperty({ nullable: true, type: Number, description: 'Straight-line km from the centre; null without a centre or a map position' })
  distanceKm!: number | null;
  @ApiProperty({
    description:
      'Whether the answer rests on a map position or a PIN code on the served list. False means "served" only because there was nothing to check: a phone order needs a map pin or a served PIN code.',
  })
  verified!: boolean;
}

@ApiTags('admin · settings')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/settings')
export class CheckAddressController {
  constructor(private readonly settings: SettingsService) {}

  /** Tests an address against the saved service area before customers meet the edge: type a map position, a PIN code, or both. */
  @Post('check-address')
  @HttpCode(200)
  async check(@Body() dto: CheckAddressDto): Promise<CheckAddressResultDto> {
    if ((dto.latitude === undefined) !== (dto.longitude === undefined)) {
      throw AppError.badRequest('INVALID_LOCATION', 'Send latitude and longitude together');
    }
    if (dto.latitude === undefined && dto.pincode === undefined) {
      throw AppError.badRequest('INVALID_LOCATION', 'Send a map position, a PIN code or both');
    }
    const settings = await this.settings.getFresh();
    const area = checkStaffArea(dto, settings);
    return {
      served: area.serviceable,
      reason: area.reason,
      // Even a place refused for its PIN code has a distance worth showing next to the reason.
      distanceKm: area.distanceKm ?? distanceFromCentre(dto, settings),
      verified: area.verified,
    };
  }
}
