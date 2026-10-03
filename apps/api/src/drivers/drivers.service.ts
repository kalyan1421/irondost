import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { normalizeIndianPhone } from '../common/phone.js';
import { Events, type PaymentCapturedEvent } from '../events.js';
import type { User } from '../generated/prisma/client.js';
import { OrderStatus, Role } from '../generated/prisma/enums.js';
import type { OrderWithRelations } from '../orders/order.dto.js';
import { actorFor, ORDER_INCLUDE, orderRef, OrdersService } from '../orders/orders.service.js';
import { PaymentsService } from '../payments/payments.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CreateDriverDto, DriverListItemDto, UpdateDriverDto } from './driver.dto.js';

const ACTIVE_DELIVERY = [OrderStatus.DELIVERY_ASSIGNED, OrderStatus.OUT_FOR_DELIVERY];

@Injectable()
export class DriversService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly orders: OrdersService,
    private readonly payments: PaymentsService,
    private readonly events: EventEmitter2,
    private readonly clock: Clock,
  ) {}

  // ───────────── Driver self-service ─────────────

  async setOnline(driver: User, isOnline: boolean): Promise<void> {
    await this.prisma.driverProfile.upsert({
      where: { userId: driver.id },
      create: { userId: driver.id, isOnline },
      update: { isOnline },
    });
  }

  async updateLocation(driver: User, latitude: number, longitude: number): Promise<void> {
    const at = this.clock.now();
    await this.prisma.driverProfile.upsert({
      where: { userId: driver.id },
      create: { userId: driver.id, latitude, longitude, locationUpdatedAt: at },
      update: { latitude, longitude, locationUpdatedAt: at },
    });
  }

  /** Active: legs to do now. History: legs this driver completed. */
  tasks(driverId: string, scope: 'active' | 'history'): Promise<OrderWithRelations[]> {
    const where =
      scope === 'active'
        ? {
            OR: [
              { pickupDriverId: driverId, status: OrderStatus.PICKUP_ASSIGNED },
              { deliveryDriverId: driverId, status: { in: ACTIVE_DELIVERY } },
            ],
          }
        : {
            OR: [
              { pickupDriverId: driverId, status: { notIn: [OrderStatus.PICKUP_ASSIGNED] } },
              { deliveryDriverId: driverId, status: OrderStatus.DELIVERED },
            ],
          };
    return this.prisma.order.findMany({
      where,
      include: ORDER_INCLUDE,
      orderBy: scope === 'active' ? [{ pickupDate: 'asc' }, { pickupSlot: 'asc' }] : { updatedAt: 'desc' },
      take: scope === 'active' ? 100 : 50,
    });
  }

  /** Full order details, only while this driver holds one of its legs. */
  async orderFor(driverId: string, orderId: string): Promise<OrderWithRelations> {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, OR: [{ pickupDriverId: driverId }, { deliveryDriverId: driverId }] },
      include: ORDER_INCLUDE,
    });
    if (!order) throw AppError.notFound('Order');
    return order;
  }

  markPickedUp(driver: User, orderId: string, note?: string): Promise<OrderWithRelations> {
    return this.orders.transition(orderId, OrderStatus.PICKED_UP, actorFor(driver, 'DRIVER'), {
      expectDriverId: driver.id,
      note,
    });
  }

  startDelivery(driver: User, orderId: string): Promise<OrderWithRelations> {
    return this.orders.transition(orderId, OrderStatus.OUT_FOR_DELIVERY, actorFor(driver, 'DRIVER'), {
      expectDriverId: driver.id,
    });
  }

  /** Marks delivered. If money is still due, the driver must confirm cash was collected. */
  async markDelivered(driver: User, orderId: string, collectedCash: boolean, note?: string): Promise<OrderWithRelations> {
    const order = await this.orderFor(driver.id, orderId);
    const due = order.totalPaise - order.paidPaise;
    if (due > 0 && !collectedCash) {
      throw AppError.badRequest('PAYMENT_DUE', `₹${(due / 100).toFixed(2)} is still due. Collect cash or ask the customer to pay online.`, {
        amountDuePaise: due,
      });
    }
    let cashPaise = 0;
    const delivered = await this.orders.transition(orderId, OrderStatus.DELIVERED, actorFor(driver, 'DRIVER'), {
      expectDriverId: driver.id,
      note,
      inTx: async (tx) => {
        if (collectedCash) cashPaise = await this.payments.recordCashInTx(tx, orderId, driver.id);
      },
    });
    if (cashPaise > 0) {
      this.events.emit(Events.PaymentCaptured, {
        ...orderRef(delivered),
        amountPaise: cashPaise,
        provider: 'CASH',
      } satisfies PaymentCapturedEvent);
    }
    return delivered;
  }

  // ───────────── Admin management ─────────────

  async list(): Promise<DriverListItemDto[]> {
    const drivers = await this.prisma.user.findMany({
      where: { role: Role.DRIVER, deletedAt: null },
      include: { driver: true },
      orderBy: { name: 'asc' },
    });
    const legs = await this.prisma.order.findMany({
      where: {
        OR: [
          { status: OrderStatus.PICKUP_ASSIGNED, pickupDriverId: { not: null } },
          { status: { in: ACTIVE_DELIVERY }, deliveryDriverId: { not: null } },
        ],
      },
      select: { status: true, pickupDriverId: true, deliveryDriverId: true },
    });
    const count = new Map<string, number>();
    for (const l of legs) {
      const id = l.status === OrderStatus.PICKUP_ASSIGNED ? l.pickupDriverId : l.deliveryDriverId;
      if (id) count.set(id, (count.get(id) ?? 0) + 1);
    }
    return drivers.map((d) => ({
      id: d.id,
      phone: d.phone,
      name: d.name,
      isActive: d.isActive,
      isOnline: d.driver?.isOnline ?? false,
      vehicleNumber: d.driver?.vehicleNumber ?? null,
      licenseNumber: d.driver?.licenseNumber ?? null,
      latitude: d.driver?.latitude ?? null,
      longitude: d.driver?.longitude ?? null,
      locationUpdatedAt: d.driver?.locationUpdatedAt ?? null,
      lastLoginAt: d.lastLoginAt,
      activeLegs: count.get(d.id) ?? 0,
    }));
  }

  /** Adds a delivery partner. They sign in to the partner app with phone OTP on this number. */
  async create(dto: CreateDriverDto): Promise<User> {
    const phone = normalizeIndianPhone(dto.phone);
    if (!phone) throw AppError.badRequest('INVALID_PHONE', 'Enter a valid 10-digit Indian mobile number');
    const existing = await this.prisma.user.findUnique({ where: { phone } });
    if (existing) throw AppError.conflict('PHONE_IN_USE', 'This number already belongs to another account');
    return this.prisma.user.create({
      data: {
        phone,
        name: dto.name.trim(),
        role: Role.DRIVER,
        driver: { create: { vehicleNumber: dto.vehicleNumber, licenseNumber: dto.licenseNumber } },
      },
    });
  }

  async update(id: string, dto: UpdateDriverDto): Promise<User> {
    const driver = await this.prisma.user.findFirst({ where: { id, role: Role.DRIVER, deletedAt: null } });
    if (!driver) throw AppError.notFound('Delivery partner');
    let phone: string | undefined;
    if (dto.phone) {
      phone = normalizeIndianPhone(dto.phone) ?? undefined;
      if (!phone) throw AppError.badRequest('INVALID_PHONE', 'Enter a valid 10-digit Indian mobile number');
    }
    return this.prisma.user.update({
      where: { id },
      data: {
        ...(phone && phone !== driver.phone ? { phone, firebaseUid: null } : {}),
        name: dto.name?.trim(),
        isActive: dto.isActive,
        driver: {
          upsert: {
            create: { vehicleNumber: dto.vehicleNumber, licenseNumber: dto.licenseNumber },
            update: {
              vehicleNumber: dto.vehicleNumber,
              licenseNumber: dto.licenseNumber,
              ...(dto.isActive === false ? { isOnline: false } : {}),
            },
          },
        },
      },
    });
  }
}
