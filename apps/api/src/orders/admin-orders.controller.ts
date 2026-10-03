import { Body, Controller, Get, HttpCode, Param, ParseUUIDPipe, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
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
} from './order.dto.js';
import { actorFor, OrdersService } from './orders.service.js';

@ApiTags('admin · orders')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/orders')
export class AdminOrdersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly audit: AuditService,
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
  async place(@CurrentUser() actor: User, @Body() dto: AdminPlaceOrderDto): Promise<OrderDto> {
    const { order } = await this.orders.place(dto.customerId, dto, OrderSource.ADMIN, actor);
    this.audit.log(actor.id, 'order.placed_for_customer', 'order', order.id, { orderNumber: order.orderNumber });
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
    const order = await this.orders.transition(id, dto.status, actorFor(actor, 'ADMIN'), {
      note: dto.note,
      cancelReason: dto.status === OrderStatus.CANCELLED ? (dto.note ?? 'Cancelled by admin') : undefined,
    });
    this.audit.log(actor.id, 'order.status_changed', 'order', id, { to: dto.status, note: dto.note });
    return toOrderDto(order, 'ADMIN');
  }

  @Put(':id/items')
  async updateItems(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateItemsDto,
  ): Promise<OrderDto> {
    const order = await this.orders.updateItems(id, dto.items, actorFor(actor, 'ADMIN'), dto.note);
    this.audit.log(actor.id, 'order.items_updated', 'order', id, dto);
    return toOrderDto(order, 'ADMIN');
  }
}
