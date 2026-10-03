import { Controller, Get, Query } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude, IsOptional, Matches } from 'class-validator';
import { Public } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import { checkServiceArea, NOT_SERVICEABLE_REASONS, type NotServiceableReason } from './service-area.js';
import { SettingsService } from './settings.service.js';

export class ServiceAreaQuery {
  @ApiPropertyOptional({ type: Number, example: 17.4126 })
  @IsOptional()
  @Type(() => Number)
  @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional({ type: Number, example: 78.4482 })
  @IsOptional()
  @Type(() => Number)
  @IsLongitude()
  longitude?: number;

  @ApiPropertyOptional({ example: '500034' })
  @IsOptional()
  @Matches(/^[1-9]\d{5}$/, { message: 'pincode must be a 6-digit Indian PIN code' })
  pincode?: string;
}

export class ServiceAreaCheckDto {
  @ApiProperty() serviceable!: boolean;
  @ApiProperty({ enum: NOT_SERVICEABLE_REASONS, enumName: 'NotServiceableReason', nullable: true })
  reason!: NotServiceableReason | null;
  @ApiProperty({ nullable: true, type: Number, description: 'Distance from the hub when a radius applies' })
  distanceKm!: number | null;
}

@ApiTags('config')
@Public()
@Controller('service-area')
export class ServiceAreaController {
  constructor(private readonly settings: SettingsService) {}

  /** Whether IronDost serves a map pin and/or PIN code. Public, so the website can ask before sign-up. */
  @Get('check')
  async check(@Query() q: ServiceAreaQuery): Promise<ServiceAreaCheckDto> {
    if ((q.latitude === undefined) !== (q.longitude === undefined)) {
      throw AppError.badRequest('INVALID_LOCATION', 'Send latitude and longitude together');
    }
    if (q.latitude === undefined && q.pincode === undefined) {
      throw AppError.badRequest('INVALID_LOCATION', 'Send a location, a PIN code or both');
    }
    return checkServiceArea(q, await this.settings.get());
  }
}
