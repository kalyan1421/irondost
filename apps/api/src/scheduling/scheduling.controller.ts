import { Controller, Get, Query } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Matches, Max, Min } from 'class-validator';
import { Public } from '../auth/decorators.js';
import { Clock } from '../common/clock.js';
import { addDays, istDate } from '../common/time.js';
import { TimeSlot } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { SettingsService } from '../settings/settings.service.js';
import { fullPickupWindows } from './pickup-capacity.js';
import { deliveryOptions, pickupOptions, SLOT_UNAVAILABLE_REASONS, type SlotUnavailableReason } from './schedule-rules.js';

export class SlotOptionDto {
  @ApiProperty({ example: '2026-10-05' }) date!: string;
  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' }) slot!: TimeSlot;
  @ApiProperty({ example: '07:00–11:00' }) label!: string;
  @ApiProperty() startsAt!: Date;
  @ApiProperty() endsAt!: Date;
  @ApiProperty() available!: boolean;
  @ApiProperty({
    enum: SLOT_UNAVAILABLE_REASONS,
    enumName: 'SlotUnavailableReason',
    nullable: true,
    description: '`FULL` when the pickup window is open but has no place left; `available` is false then. Null otherwise.',
  })
  reason!: SlotUnavailableReason | null;
}

class PickupSlotsQuery {
  @ApiPropertyOptional({ default: 7, minimum: 1, maximum: 31 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(31)
  days: number = 7;
}

class DeliverySlotsQuery extends PickupSlotsQuery {
  @ApiProperty({ example: '2026-10-05' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  pickupDate!: string;

  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' })
  @IsEnum(TimeSlot)
  pickupSlot!: TimeSlot;
}

@ApiTags('schedule')
@Public()
@Controller('schedule')
export class SchedulingController {
  constructor(
    private readonly settings: SettingsService,
    private readonly clock: Clock,
    private readonly prisma: PrismaService,
  ) {}

  @Get('pickup-slots')
  async pickupSlots(@Query() q: PickupSlotsQuery): Promise<SlotOptionDto[]> {
    const now = this.clock.now();
    const settings = await this.settings.get();
    const today = istDate(now);
    const full = await fullPickupWindows(this.prisma, today, addDays(today, q.days - 1), settings.pickupCapacityPerSlot);
    return pickupOptions(now, settings, q.days, full);
  }

  @Get('delivery-slots')
  async deliverySlots(@Query() q: DeliverySlotsQuery): Promise<SlotOptionDto[]> {
    return deliveryOptions(q.pickupDate, q.pickupSlot, await this.settings.get(), q.days);
  }
}
