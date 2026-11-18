import { Controller, Get, HttpCode, Param, ParseUUIDPipe, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser, Roles } from '../auth/decorators.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { DeliveriesQuery, DeliveryDto, DeliveryPageDto } from './deliveries.dto.js';
import { NotificationDeliveriesService } from './deliveries.service.js';

/** Alerts that did not reach the customer (or partner, or staff member), so staff can retry or phone them. */
@ApiTags('admin · notifications')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/notification-deliveries')
export class NotificationDeliveriesController {
  constructor(private readonly deliveries: NotificationDeliveriesService) {}

  /** By default only alerts that did not fully arrive and nobody has followed up on, newest first. */
  @Get()
  list(@Query() q: DeliveriesQuery): Promise<DeliveryPageDto> {
    return this.deliveries.list(q);
  }

  /** Sends the same alert once more. Recorded as a new delivery; refused if it already arrived. */
  @Post(':id/retry')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  retry(@CurrentUser() actor: User, @Param('id', ParseUUIDPipe) id: string): Promise<DeliveryDto> {
    return this.deliveries.retry(actor, id);
  }

  /** Marks the alert as followed up, so it leaves the open list and the dashboard count. */
  @Post(':id/handled')
  @HttpCode(200)
  handled(@CurrentUser() actor: User, @Param('id', ParseUUIDPipe) id: string): Promise<DeliveryDto> {
    return this.deliveries.handled(actor, id);
  }
}
