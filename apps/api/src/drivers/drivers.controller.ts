import { Body, Controller, Get, HttpCode, Param, ParseUUIDPipe, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import { DispatchService } from '../dispatch/dispatch.service.js';
import type { User } from '../generated/prisma/client.js';
import { OrderStatus, Role } from '../generated/prisma/enums.js';
import { OrderDto, toOrderDto, UpdateItemsDto } from '../orders/order.dto.js';
import { actorFor, OrdersService } from '../orders/orders.service.js';
import { toUserDto, UserDto } from '../users/user.dto.js';
import {
  AssignDto,
  CreateDriverDto,
  DeliverDto,
  DriverListItemDto,
  LocationDto,
  OfferDto,
  SetOnlineDto,
  TasksQuery,
  toOfferDto,
  UnassignDto,
  UpdateDriverDto,
} from './driver.dto.js';
import { DriversService } from './drivers.service.js';

@ApiTags('driver')
@ApiBearerAuth()
@Roles(Role.DRIVER)
@Controller('driver')
export class DriverController {
  constructor(
    private readonly drivers: DriversService,
    private readonly dispatch: DispatchService,
    private readonly orders: OrdersService,
  ) {}

  @Put('online')
  @HttpCode(204)
  setOnline(@CurrentUser() user: User, @Body() dto: SetOnlineDto): Promise<void> {
    return this.drivers.setOnline(user, dto.isOnline);
  }

  /** Send every 30–60 s while online. Drivers without a recent location get no offers. */
  @Put('location')
  @HttpCode(204)
  location(@CurrentUser() user: User, @Body() dto: LocationDto): Promise<void> {
    return this.drivers.updateLocation(user, dto.latitude, dto.longitude);
  }

  @Get('offers')
  async offers(@CurrentUser() user: User): Promise<OfferDto[]> {
    return (await this.dispatch.listOffers(user.id)).map(toOfferDto);
  }

  @Post('offers/:id/accept')
  @HttpCode(200)
  async accept(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto((await this.dispatch.respond(user, id, true))!, 'DRIVER');
  }

  @Post('offers/:id/reject')
  @HttpCode(204)
  async reject(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.dispatch.respond(user, id, false);
  }

  @Get('tasks')
  async tasks(@CurrentUser() user: User, @Query() q: TasksQuery): Promise<OrderDto[]> {
    return (await this.drivers.tasks(user.id, q.scope)).map((o) => toOrderDto(o, 'DRIVER'));
  }

  @Get('orders/:id')
  async order(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto(await this.drivers.orderFor(user.id, id), 'DRIVER');
  }

  /** Correct the item count at the doorstep before confirming pickup. */
  @Put('orders/:id/items')
  async updateItems(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateItemsDto,
  ): Promise<OrderDto> {
    const order = await this.drivers.orderFor(user.id, id);
    if (order.pickupDriverId !== user.id || order.status !== OrderStatus.PICKUP_ASSIGNED) {
      throw AppError.conflict('ITEMS_LOCKED', 'Items can only be changed at pickup');
    }
    return toOrderDto(await this.orders.updateItems(id, dto.items, actorFor(user, 'DRIVER'), dto.note), 'DRIVER');
  }

  @Post('orders/:id/picked-up')
  @HttpCode(200)
  async pickedUp(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto(await this.drivers.markPickedUp(user, id), 'DRIVER');
  }

  @Post('orders/:id/out-for-delivery')
  @HttpCode(200)
  async outForDelivery(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<OrderDto> {
    return toOrderDto(await this.drivers.startDelivery(user, id), 'DRIVER');
  }

  @Post('orders/:id/delivered')
  @HttpCode(200)
  async delivered(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DeliverDto,
  ): Promise<OrderDto> {
    return toOrderDto(await this.drivers.markDelivered(user, id, dto.collectedCash ?? false, dto.note), 'DRIVER');
  }
}

@ApiTags('admin · drivers')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin')
export class AdminDriversController {
  constructor(
    private readonly drivers: DriversService,
    private readonly dispatch: DispatchService,
    private readonly audit: AuditService,
  ) {}

  @Get('drivers')
  list(): Promise<DriverListItemDto[]> {
    return this.drivers.list();
  }

  @Post('drivers')
  async create(@CurrentUser() actor: User, @Body() dto: CreateDriverDto): Promise<UserDto> {
    const user = await this.drivers.create(dto);
    this.audit.log(actor.id, 'driver.created', 'user', user.id, { phone: user.phone, name: user.name });
    return toUserDto(user);
  }

  @Patch('drivers/:id')
  async update(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDriverDto,
  ): Promise<UserDto> {
    const user = await this.drivers.update(id, dto);
    this.audit.log(actor.id, 'driver.updated', 'user', id, dto);
    return toUserDto(user);
  }

  /** Assign (or reassign) a driver to the pickup or delivery leg of an order. */
  @Post('orders/:id/assign')
  @HttpCode(200)
  async assign(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignDto,
  ): Promise<OrderDto> {
    const order = await this.dispatch.assign(id, dto.leg, dto.driverId, actor);
    this.audit.log(actor.id, 'order.assigned', 'order', id, dto);
    return toOrderDto(order, 'ADMIN');
  }

  /** Remove the driver from a leg; automatic dispatch starts looking again. */
  @Post('orders/:id/unassign')
  @HttpCode(200)
  async unassign(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UnassignDto,
  ): Promise<OrderDto> {
    const order = await this.dispatch.unassign(id, dto.leg, actor);
    this.audit.log(actor.id, 'order.unassigned', 'order', id, dto);
    return toOrderDto(order, 'ADMIN');
  }
}
