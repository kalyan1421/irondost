import { Body, Controller, Get, Headers, HttpCode, Param, ParseUUIDPipe, Post, Query, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { AuditService } from '../audit/audit.service.js';
import { AppError } from '../common/errors.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import type { User } from '../generated/prisma/client.js';
import { OrderSource, OrderStatus, Role } from '../generated/prisma/enums.js';
import { CancelOrderDto, CustomerOrdersQuery, OrderDto, OrderPageDto, PlaceOrderDto, QuoteDto, QuoteRequestDto, RescheduleOrderDto, toOrderDto } from './order.dto.js';
import { actorFor, OrdersService } from './orders.service.js';

const IDEMPOTENCY_KEY = /^[A-Za-z0-9_-]{8,100}$/;

@ApiTags('orders')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly audit: AuditService,
  ) {}

  /** Server-side price for a basket, including promo validation. Call before placing. */
  @Post('quote')
  @HttpCode(200)
  quote(@CurrentUser() user: User, @Body() dto: QuoteRequestDto): Promise<QuoteDto> {
    return this.orders.quote(user.id, dto.items, dto.promoCode);
  }

  @Post()
  @ApiHeader({
    name: 'Idempotency-Key',
    required: false,
    description:
      'One value per checkout attempt (a UUID). Retrying with the same key returns the order the first attempt placed, ' +
      'with the Idempotent-Replayed: true header, instead of placing another.',
  })
  async place(
    @CurrentUser() user: User,
    @Body() dto: PlaceOrderDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ): Promise<OrderDto> {
    if (idempotencyKey !== undefined && !IDEMPOTENCY_KEY.test(idempotencyKey)) {
      throw AppError.badRequest('INVALID_IDEMPOTENCY_KEY', 'Idempotency-Key must be 8–100 letters, digits, "-" or "_"');
    }
    const { order, replayed } = await this.orders.place(user.id, dto, OrderSource.CUSTOMER_APP, user, idempotencyKey);
    if (replayed) res.setHeader('Idempotent-Replayed', 'true');
    return toOrderDto(order, 'CUSTOMER');
  }

  @Get()
  async list(@CurrentUser() user: User, @Query() q: CustomerOrdersQuery): Promise<OrderPageDto> {
    const page = await this.orders.listForCustomer(user.id, q.page, q.pageSize, q.scope);
    return { ...page, items: page.items.map((o) => toOrderDto(o, 'CUSTOMER')) };
  }

  @Get(':id')
  async get(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto(await this.orders.getForCustomer(user.id, id), 'CUSTOMER');
  }

  @Post(':id/adjustments/:adjustmentId/approve')
  @HttpCode(200)
  async approve(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string, @Param('adjustmentId', ParseUUIDPipe) adjustmentId: string): Promise<OrderDto> {
    return toOrderDto(await this.orders.decideAdjustment(user, id, adjustmentId, true), 'CUSTOMER');
  }

  @Post(':id/adjustments/:adjustmentId/decline')
  @HttpCode(200)
  async decline(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string, @Param('adjustmentId', ParseUUIDPipe) adjustmentId: string): Promise<OrderDto> {
    return toOrderDto(await this.orders.decideAdjustment(user, id, adjustmentId, false), 'CUSTOMER');
  }

  /** For an online order that has not been paid (a failed or abandoned payment): the partner collects the amount at delivery. */
  @Post(':id/pay-on-delivery')
  @HttpCode(200)
  async payOnDelivery(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto(await this.orders.switchToCashOnDelivery(user, id), 'CUSTOMER');
  }

  /**
   * Moves the pickup and delivery time. Allowed until the clothes are picked up, twice per order. Prices do not change.
   * When a partner had accepted the pickup, they are released and the order is offered again for the new time.
   */
  @Post(':id/reschedule')
  @HttpCode(200)
  @ApiHeader({
    name: 'Idempotency-Key',
    required: false,
    description:
      'One value per change (a UUID). Retrying the same change with the same key returns the order as it is now, with the ' +
      'Idempotent-Replayed: true header, and does not use up another reschedule.',
  })
  async reschedule(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RescheduleOrderDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ): Promise<OrderDto> {
    if (idempotencyKey !== undefined && !IDEMPOTENCY_KEY.test(idempotencyKey)) {
      throw AppError.badRequest('INVALID_IDEMPOTENCY_KEY', 'Idempotency-Key must be 8–100 letters, digits, "-" or "_"');
    }
    const { order, replayed, previous, next } = await this.orders.reschedule(user, id, dto, idempotencyKey);
    if (replayed) res.setHeader('Idempotent-Replayed', 'true');
    else this.audit.log(user.id, 'order.rescheduled', 'order', id, { orderNumber: order.orderNumber, previous, next, rescheduleCount: order.rescheduleCount });
    return toOrderDto(order, 'CUSTOMER');
  }

  /** Allowed until the clothes are picked up. */
  @Post(':id/cancel')
  @HttpCode(200)
  async cancel(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelOrderDto,
  ): Promise<OrderDto> {
    await this.orders.getForCustomer(user.id, id); // ownership check
    const order = await this.orders.transition(id, OrderStatus.CANCELLED, actorFor(user, 'CUSTOMER'), {
      cancelReason: dto.reason ?? 'Cancelled by customer',
    });
    return toOrderDto(order, 'CUSTOMER');
  }
}
