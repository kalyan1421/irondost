import { Controller, Get, Inject } from '@nestjs/common';
import { ApiProperty, ApiTags } from '@nestjs/swagger';
import { Public } from '../auth/decorators.js';
import { SLOT_ORDER } from '../common/time.js';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import { TimeSlot } from '../generated/prisma/enums.js';
import { slotLabel } from '../scheduling/schedule-rules.js';
import { SettingsService } from './settings.service.js';

export class SlotDefinitionDto {
  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' }) slot!: TimeSlot;
  @ApiProperty({ example: '07:00–11:00' }) label!: string;
}

/** What the apps need to know before sign-in: brand, support contact and order rules. */
export class PublicConfigDto {
  @ApiProperty({ example: 'IronDost' }) appName!: string;
  @ApiProperty({ nullable: true, type: String }) supportPhone!: string | null;
  @ApiProperty({ nullable: true, type: String }) supportEmail!: string | null;
  @ApiProperty() minOrderPaise!: number;
  @ApiProperty({ description: 'The flat travel charge for a small order, in paise.' }) deliveryFeePaise!: number;
  @ApiProperty({ nullable: true, type: Number, description: 'Travel is free from this items total (before any coupon), in paise. Null = never free.' }) freeDeliveryAbovePaise!: number | null;
  @ApiProperty() minTurnaroundHours!: number;
  @ApiProperty() maxAdvanceDays!: number;
  @ApiProperty({ type: [SlotDefinitionDto] }) slots!: SlotDefinitionDto[];
}

@ApiTags('config')
@Public()
@Controller('config')
export class PublicConfigController {
  constructor(
    private readonly settings: SettingsService,
    @Inject(APP_ENV) private readonly env: Env,
  ) {}

  @Get()
  async get(): Promise<PublicConfigDto> {
    const s = await this.settings.get();
    return {
      appName: this.env.APP_NAME,
      supportPhone: s.supportPhone,
      supportEmail: s.supportEmail,
      minOrderPaise: s.minOrderPaise,
      deliveryFeePaise: s.deliveryFeePaise,
      freeDeliveryAbovePaise: s.freeDeliveryAbovePaise,
      minTurnaroundHours: s.minTurnaroundHours,
      maxAdvanceDays: s.maxAdvanceDays,
      slots: SLOT_ORDER.map((slot) => ({ slot, label: slotLabel(slot) })),
    };
  }
}
