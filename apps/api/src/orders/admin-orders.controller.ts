import { Body, Controller, Get, Headers, HttpCode, Param, ParseUUIDPipe, Post, Put, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ApiBearerAuth, ApiHeader, ApiTags } from '@nestjs/swagger';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import { Events, type PaymentCapturedEvent } from '../events.js';
import type { User } from '../generated/prisma/client.js';
import { OrderSource, OrderStatus, Role } from '../generated/prisma/enums.js';
import {
  AdminOrdersQuery,
  AdminPlaceOrderDto,
  ChangeStatusDto,
  OrderDto,
  OrderPageDto,
  QuoteDto,
  QuoteRequestDto,
  toOrderDto,
  UpdateItemsDto,
  ItemEditPreviewDto,
} from './order.dto.js';
import { PaymentsService } from '../payments/payments.service.js';
import { actorFor, orderRef, OrdersService } from './orders.service.js';

@ApiTags('admin · orders')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/orders')
export class AdminOrdersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly audit: AuditService,
    private readonly payments: PaymentsService,
    private readonly events: EventEmitter2,
  ) {}

  @Get()
  async list(@Query() q: AdminOrdersQuery): Promise<OrderPageDto> {
    const page = await this.orders.adminList(q);
    return { ...page, items: page.items.map((o) => toOrderDto(o, 'ADMIN')) };
  }

  @Get(':id')
  async get(@Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto(await this.orders.getById(id), 'ADMIN');
  }

  @Post('quote/:customerId')
  @HttpCode(200)
  quote(@Param('customerId', ParseUUIDPipe) customerId: string, @Body() dto: QuoteRequestDto): Promise<QuoteDto> {
    return this.orders.quote(customerId, dto.items, dto.promoCode);
  }

  /** Place an order on a customer's behalf (phone orders). */
  @Post()
  @ApiHeader({ name: 'Idempotency-Key', required: false, description: 'Reuse the same key when retrying one phone-order draft.' })
  async place(@CurrentUser() actor: User, @Body() dto: AdminPlaceOrderDto,
    @Headers('idempotency-key') key: string | undefined, @Res({ passthrough: true }) res: Response): Promise<OrderDto> {
    if (key !== undefined && !/^[A-Za-z0-9_-]{8,100}$/.test(key)) {
      throw AppError.badRequest('INVALID_IDEMPOTENCY_KEY', 'Idempotency-Key must be 8–100 letters, digits, "-" or "_"');
    }
    const { order, replayed } = await this.orders.place(dto.customerId, dto, OrderSource.ADMIN, actor, key ? `admin_${actor.id}_${key}` : undefined, {
      outsideAreaReason: dto.outsideAreaReason,
      capacityOverrideReason: dto.capacityOverrideReason,
    });
    if (replayed) res.setHeader('Idempotent-Replayed', 'true');
    // The reasons are on the order only when they were needed, so the log shows exactly which rules staff went past.
    else {
      this.audit.log(actor.id, 'order.placed_for_customer', 'order', order.id, {
        orderNumber: order.orderNumber,
        ...(order.areaOverrideReason ? { outsideAreaReason: order.areaOverrideReason } : {}),
        ...(order.capacityOverrideReason ? { capacityOverrideReason: order.capacityOverrideReason } : {}),
      });
    }
    return toOrderDto(order, 'ADMIN');
  }

  /** Move an order along its lifecycle. Driver assignment uses the assign endpoint instead. */
  @Post(':id/status')
  @HttpCode(200)
  async changeStatus(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ChangeStatusDto,
  ): Promise<OrderDto> {
    if (dto.status === OrderStatus.PICKUP_ASSIGNED || dto.status === OrderStatus.DELIVERY_ASSIGNED) {
      throw AppError.badRequest('USE_ASSIGN_ENDPOINT', 'Use POST /v1/admin/orders/:id/assign to assign a driver');
    }
    if (dto.collectedCash && dto.status !== OrderStatus.DELIVERED) {
      throw AppError.badRequest('CASH_ONLY_WITH_DELIVERY', 'collectedCash only applies when marking an order delivered');
    }
    if (dto.keepTravelCharge && dto.status !== OrderStatus.CANCELLED) {
      throw AppError.badRequest('KEEP_ONLY_WITH_CANCEL', 'keepTravelCharge only applies when cancelling an order');
    }
    // Cash taken at the door is recorded in the same transaction as the delivery, as the partner app does.
    let cashPaise = 0;
    const order = await this.orders.transition(id, dto.status, actorFor(actor, 'ADMIN'), {
      note: dto.note,
      cancelReason: dto.status === OrderStatus.CANCELLED ? (dto.note ?? 'Cancelled by admin') : undefined,
      keepTravelCharge: dto.keepTravelCharge,
      inTx: dto.collectedCash
        ? async (tx) => {
            cashPaise = await this.payments.recordCashInTx(tx, id, actor.id);
          }
        : undefined,
    });
    if (cashPaise > 0) {
      this.events.emit(Events.PaymentCaptured, {
        ...orderRef(order),
        amountPaise: cashPaise,
        provider: 'CASH',
      } satisfies PaymentCapturedEvent);
    }
    this.audit.log(actor.id, 'order.status_changed', 'order', id, {
      to: dto.status,
      note: dto.note,
      ...(cashPaise > 0 ? { cashCollectedPaise: cashPaise } : {}),
      ...(order.travelChargeKept ? { travelChargeKeptPaise: order.deliveryFeePaise } : {}),
    });
    return toOrderDto(order, 'ADMIN');
  }

  @Put(':id/items')
  async updateItems(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateItemsDto,
  ): Promise<OrderDto> {
    const order = await this.orders.updateItems(id, dto.items, actorFor(actor, 'ADMIN'), dto.note, dto.expectedRevision);
    this.audit.log(actor.id, 'order.items_updated', 'order', id, dto);
    return toOrderDto(order, 'ADMIN');
  }

  @Post(':id/items/quote')
  @HttpCode(200)
  previewItems(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateItemsDto): Promise<ItemEditPreviewDto> {
    return this.orders.previewItems(id, dto.items, dto.expectedRevision);
  }
}
