import { createHash } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { formatAddress } from '../addresses/address.dto.js';
import { AddressesService } from '../addresses/addresses.service.js';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { pageArgs, type Page } from '../common/pagination.js';
import { toDbDate } from '../common/time.js';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import {
  Events,
  type OffersClosedEvent,
  type OrderCreatedEvent,
  type OrderRef,
  type OrderStatusChangedEvent,
  type OrderUpdatedEvent,
} from '../events.js';
import { Prisma, type Address, type Order, type User } from '../generated/prisma/client.js';
import { DispatchLeg, OfferStatus, OrderSource, OrderStatus, PaymentMethod, Role } from '../generated/prisma/enums.js';
import { PrismaService, type Tx } from '../prisma/prisma.service.js';
import { checkDelivery, checkPickup, SCHEDULE_ERROR_MESSAGES } from '../scheduling/schedule-rules.js';
import { checkServiceArea } from '../settings/service-area.js';
import { SettingsService } from '../settings/settings.service.js';
import type { AdminOrdersQuery, OrderLineInput, OrderScope, OrderWithRelations, PlaceOrderDto, QuoteDto } from './order.dto.js';
import { canTransition, FINAL_STATUSES, ITEMS_EDITABLE, type ActorKind } from './order-state.js';
import { computeQuote, paymentStatusFor, type PricingLine, type PricingPromotion, type Quote } from './pricing.js';

export const ORDER_INCLUDE = {
  items: true,
  customer: true,
  pickupDriver: true,
  deliveryDriver: true,
  refunds: { orderBy: { createdAt: 'asc' }, include: { createdBy: { select: { id: true, name: true } } } },
} as const satisfies Prisma.OrderInclude;

export interface TransitionActor {
  id: string | null;
  role: Role | null;
  kind: ActorKind;
}

export const SYSTEM_ACTOR: TransitionActor = { id: null, role: null, kind: 'SYSTEM' };

export function actorFor(user: User, kind: ActorKind): TransitionActor {
  return { id: user.id, role: user.role, kind };
}

export interface TransitionOptions {
  note?: string;
  cancelReason?: string;
  /** Required when moving to PICKUP_ASSIGNED / DELIVERY_ASSIGNED. */
  driverId?: string;
  /** For driver actions: the order's current leg must belong to this driver. */
  expectDriverId?: string;
  /** Extra writes that must commit atomically with the status change. */
  inTx?: (tx: Tx, before: Order) => Promise<void>;
}

type PromoError = 'PROMO_NOT_FOUND' | 'PROMO_EXPIRED' | 'PROMO_LIMIT_REACHED' | 'PROMO_MIN_ORDER';

const ASSIGNED_TO_DRIVER: Partial<Record<OrderStatus, 'pickupDriverId' | 'deliveryDriverId'>> = {
  [OrderStatus.PICKUP_ASSIGNED]: 'pickupDriverId',
  [OrderStatus.DELIVERY_ASSIGNED]: 'deliveryDriverId',
  [OrderStatus.OUT_FOR_DELIVERY]: 'deliveryDriverId',
};

export function orderRef(o: Order): OrderRef {
  return {
    orderId: o.id,
    orderNumber: o.orderNumber,
    customerId: o.customerId,
    pickupDriverId: o.pickupDriverId,
    deliveryDriverId: o.deliveryDriverId,
  };
}

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly settings: SettingsService,
    private readonly addresses: AddressesService,
    private readonly events: EventEmitter2,
    private readonly clock: Clock,
    @Inject(APP_ENV) private readonly env: Env,
  ) {}

  // ───────────── Pricing ─────────────

  async quote(customerId: string, items: OrderLineInput[], promoCode?: string): Promise<QuoteDto> {
    await this.activeCustomer(customerId);
    const { quote, promoError } = await this.buildQuote(customerId, items, promoCode);
    return {
      lines: quote.lines,
      subtotalPaise: quote.subtotalPaise,
      discountPaise: quote.discountPaise,
      deliveryFeePaise: quote.deliveryFeePaise,
      totalPaise: quote.totalPaise,
      promoCode: quote.appliedPromotion?.code ?? null,
      promoError,
      promoShortfallPaise: quote.promoShortfallPaise,
      minOrderShortfallPaise: quote.minOrderShortfallPaise,
      canPlaceOrder: quote.minOrderShortfallPaise === null && (!promoCode || promoError === null),
    };
  }

  private async pricingLines(items: OrderLineInput[]): Promise<PricingLine[]> {
    // Merge repeated items so each catalogue item appears once.
    const qty = new Map<string, number>();
    for (const i of items) qty.set(i.catalogItemId, (qty.get(i.catalogItemId) ?? 0) + i.quantity);

    const rows = await this.prisma.catalogItem.findMany({
      where: { id: { in: [...qty.keys()] }, isActive: true, category: { isActive: true } },
    });
    const missing = [...qty.keys()].filter((id) => !rows.some((r) => r.id === id));
    if (missing.length) {
      throw AppError.badRequest('ITEM_UNAVAILABLE', 'Some items are no longer available', {
        catalogItemIds: missing,
      });
    }
    return rows.map((r) => ({
      catalogItemId: r.id,
      name: r.name,
      unit: r.unit,
      unitPricePaise: r.offerPricePaise ?? r.pricePaise,
      quantity: qty.get(r.id)!,
    }));
  }

  private async buildQuote(
    customerId: string,
    items: OrderLineInput[],
    promoCode?: string,
  ): Promise<{ quote: Quote; promoError: PromoError | null }> {
    const [lines, settings] = await Promise.all([this.pricingLines(items), this.settings.get()]);

    let promotion: PricingPromotion | null = null;
    let promoError: PromoError | null = null;
    if (promoCode) {
      const now = this.clock.now();
      const p = await this.prisma.promotion.findUnique({ where: { code: promoCode } });
      if (!p) promoError = 'PROMO_NOT_FOUND';
      else if (!p.isActive || now < p.validFrom || now >= p.validTo) promoError = 'PROMO_EXPIRED';
      else if (p.perCustomerLimit != null) {
        const used = await this.prisma.order.count({
          where: { customerId, promotionId: p.id, status: { not: OrderStatus.CANCELLED } },
        });
        if (used >= p.perCustomerLimit) promoError = 'PROMO_LIMIT_REACHED';
      }
      if (p && !promoError) promotion = p;
    }

    const quote = computeQuote(lines, settings, promotion);
    if (promotion && !quote.appliedPromotion) promoError = 'PROMO_MIN_ORDER';
    return { quote, promoError };
  }

  private async activeCustomer(customerId: string): Promise<User> {
    const customer = await this.prisma.user.findUnique({ where: { id: customerId } });
    if (!customer || customer.role !== Role.CUSTOMER || customer.deletedAt) throw AppError.notFound('Customer');
    if (!customer.isActive) throw AppError.forbidden('CUSTOMER_INACTIVE', 'This customer account is deactivated');
    return customer;
  }

  // ───────────── Placing orders ─────────────

  /**
   * Places an order. With an idempotency key, a retry of the same request returns the order the
   * first attempt created (`replayed: true`) instead of placing a second one.
   */
  async place(
    customerId: string,
    dto: PlaceOrderDto,
    source: OrderSource,
    createdBy: User,
    idempotencyKey?: string,
  ): Promise<{ order: OrderWithRelations; replayed: boolean }> {
    const idempotency = idempotencyKey ? { key: idempotencyKey, hash: placeRequestHash(dto) } : null;
    if (idempotency) {
      const prior = await this.priorAttempt(customerId, idempotency);
      if (prior) return { order: prior, replayed: true };
    }

    const customer = await this.activeCustomer(customerId);

    const settings = await this.settings.get();
    const scheduleError =
      checkPickup(dto.pickupDate, dto.pickupSlot, this.clock.now(), settings) ??
      checkDelivery(dto.pickupDate, dto.pickupSlot, dto.deliveryDate, dto.deliverySlot, settings);
    if (scheduleError) throw AppError.badRequest(scheduleError, SCHEDULE_ERROR_MESSAGES[scheduleError]);

    const pickup = await this.addresses.get(customerId, dto.pickupAddressId);
    const delivery = dto.deliveryAddressId ? await this.addresses.get(customerId, dto.deliveryAddressId) : pickup;
    // Staff placing a phone order may knowingly serve an address outside the area.
    if (source === OrderSource.CUSTOMER_APP) {
      for (const address of new Set([pickup, delivery])) {
        const area = checkServiceArea(address, settings);
        if (!area.serviceable) {
          throw AppError.badRequest('ADDRESS_NOT_SERVICEABLE', 'We do not serve this address yet', {
            addressId: address.id,
            reason: area.reason,
          });
        }
      }
    }

    const { quote, promoError } = await this.buildQuote(customerId, dto.items, dto.promoCode);
    if (dto.promoCode && promoError) {
      throw AppError.badRequest('PROMO_INVALID', 'This promo code cannot be applied', { promoError });
    }
    if (quote.minOrderShortfallPaise !== null) {
      throw AppError.badRequest('BELOW_MIN_ORDER', 'Order total is below the minimum', {
        minOrderPaise: settings.minOrderPaise,
        shortfallPaise: quote.minOrderShortfallPaise,
      });
    }

    const create = () => this.prisma.$transaction(async (tx) => {
      const [{ nextval }] = await tx.$queryRaw<{ nextval: bigint }[]>`SELECT nextval('order_number_seq')`;
      const orderNumber = `${this.env.ORDER_NUMBER_PREFIX}${String(nextval).padStart(6, '0')}`;
      return tx.order.create({
        data: {
          orderNumber,
          customerId,
          source,
          createdById: createdBy.id,
          status: OrderStatus.PENDING,
          pickupDate: toDbDate(dto.pickupDate),
          pickupSlot: dto.pickupSlot,
          deliveryDate: toDbDate(dto.deliveryDate),
          deliverySlot: dto.deliverySlot,
          pickupAddressId: pickup.id,
          deliveryAddressId: delivery.id,
          pickupAddress: addressSnapshot(pickup, customer),
          deliveryAddress: addressSnapshot(delivery, customer),
          pickupLatitude: pickup.latitude,
          pickupLongitude: pickup.longitude,
          deliveryLatitude: delivery.latitude,
          deliveryLongitude: delivery.longitude,
          instructions: dto.instructions?.trim() || null,
          subtotalPaise: quote.subtotalPaise,
          discountPaise: quote.discountPaise,
          deliveryFeePaise: quote.deliveryFeePaise,
          totalPaise: quote.totalPaise,
          paymentStatus: paymentStatusFor(quote.totalPaise, 0),
          promotionId: quote.appliedPromotion?.id ?? null,
          promoCode: quote.appliedPromotion?.code ?? null,
          paymentMethod: dto.paymentMethod,
          idempotencyKey: idempotency?.key ?? null,
          idempotencyHash: idempotency?.hash ?? null,
          items: {
            create: quote.lines.map((l) => ({
              catalogItemId: l.catalogItemId,
              name: l.name,
              unit: l.unit,
              unitPricePaise: l.unitPricePaise,
              quantity: l.quantity,
              lineTotalPaise: l.lineTotalPaise,
            })),
          },
          events: {
            create: {
              toStatus: OrderStatus.PENDING,
              actorId: createdBy.id,
              actorRole: createdBy.role,
              note: source === OrderSource.ADMIN ? 'Placed by admin' : null,
            },
          },
        },
        include: ORDER_INCLUDE,
      });
    });

    let order: OrderWithRelations;
    try {
      order = await create();
    } catch (err) {
      // Two attempts with the same key raced; the other one created the order.
      if (idempotency && err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        const prior = await this.priorAttempt(customerId, idempotency);
        if (prior) return { order: prior, replayed: true };
      }
      throw err;
    }

    this.events.emit(Events.OrderCreated, { ...orderRef(order), status: order.status } satisfies OrderCreatedEvent);
    return { order, replayed: false };
  }

  private async priorAttempt(customerId: string, idem: { key: string; hash: string }): Promise<OrderWithRelations | null> {
    const prior = await this.prisma.order.findUnique({
      where: { customerId_idempotencyKey: { customerId, idempotencyKey: idem.key } },
      include: ORDER_INCLUDE,
    });
    if (prior && prior.idempotencyHash !== idem.hash) {
      throw AppError.conflict('IDEMPOTENCY_KEY_REUSED', 'This Idempotency-Key was already used for a different order');
    }
    return prior;
  }

  // ───────────── Reading ─────────────

  async listForCustomer(customerId: string, page: number, pageSize: number, scope?: OrderScope): Promise<Page<OrderWithRelations>> {
    const where: Prisma.OrderWhereInput = {
      customerId,
      ...(scope === 'active' && { status: { notIn: [...FINAL_STATUSES] } }),
      ...(scope === 'past' && { status: { in: [...FINAL_STATUSES] } }),
    };
    const [items, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: ORDER_INCLUDE,
        orderBy: { createdAt: 'desc' },
        ...pageArgs({ page, pageSize }),
      }),
      this.prisma.order.count({ where }),
    ]);
    return { items, page, pageSize, total };
  }

  async getForCustomer(customerId: string, id: string): Promise<OrderWithRelations> {
    const order = await this.prisma.order.findFirst({
      where: { id, customerId },
      include: { ...ORDER_INCLUDE, events: { orderBy: { createdAt: 'asc' } } },
    });
    if (!order) throw AppError.notFound('Order');
    return order;
  }

  /**
   * Switches an online order that has not been paid to cash on delivery: what a customer does after a
   * failed or abandoned online payment. The partner then collects the amount at delivery.
   */
  async switchToCashOnDelivery(customer: User, orderId: string): Promise<OrderWithRelations> {
    const order = await this.getForCustomer(customer.id, orderId);
    if (order.paymentMethod === PaymentMethod.COD) return order;
    if (order.status === OrderStatus.CANCELLED) throw AppError.conflict('ORDER_CANCELLED', 'This order was cancelled');
    if (order.status === OrderStatus.DELIVERED) {
      throw AppError.conflict('ORDER_DELIVERED', 'This order was already delivered. Pay the amount due online instead.');
    }
    if (order.paidPaise > 0) throw AppError.conflict('ALREADY_PAID', 'Part of this order is already paid online');

    await this.prisma.$transaction(async (tx) => {
      const res = await tx.order.updateMany({
        where: { id: orderId, paymentMethod: PaymentMethod.ONLINE, paidPaise: 0, status: order.status },
        data: { paymentMethod: PaymentMethod.COD },
      });
      if (res.count === 0) throw AppError.conflict('ORDER_CHANGED', 'The order was just updated. Refresh and try again.');
      await tx.orderEvent.create({
        data: {
          orderId,
          fromStatus: order.status,
          toStatus: order.status,
          actorId: customer.id,
          actorRole: customer.role,
          note: 'Customer chose to pay cash on delivery',
        },
      });
    });
    return this.getForCustomer(customer.id, orderId);
  }

  async getById(id: string): Promise<OrderWithRelations> {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { ...ORDER_INCLUDE, events: { orderBy: { createdAt: 'asc' } } },
    });
    if (!order) throw AppError.notFound('Order');
    return order;
  }

  async adminList(q: AdminOrdersQuery): Promise<Page<OrderWithRelations>> {
    const search = q.search?.trim();
    const where: Prisma.OrderWhereInput = {
      ...(q.status?.length ? { status: { in: q.status } } : {}),
      ...(q.customerId ? { customerId: q.customerId } : {}),
      ...(q.driverId ? { OR: [{ pickupDriverId: q.driverId }, { deliveryDriverId: q.driverId }] } : {}),
      ...(q.dispatchFailed ? { dispatchFailedAt: { not: null } } : {}),
      ...(q.pickupFrom || q.pickupTo
        ? {
            pickupDate: {
              ...(q.pickupFrom ? { gte: toDbDate(q.pickupFrom) } : {}),
              ...(q.pickupTo ? { lte: toDbDate(q.pickupTo) } : {}),
            },
          }
        : {}),
      ...(search
        ? {
            AND: [
              {
                OR: [
                  { orderNumber: { contains: search, mode: 'insensitive' } },
                  { customer: { phone: { contains: search.replace(/\s/g, '') } } },
                  { customer: { name: { contains: search, mode: 'insensitive' } } },
                ],
              },
            ],
          }
        : {}),
    };
    const [items, total] = await Promise.all([
      this.prisma.order.findMany({ where, include: ORDER_INCLUDE, orderBy: { createdAt: 'desc' }, ...pageArgs(q) }),
      this.prisma.order.count({ where }),
    ]);
    return { items, page: q.page, pageSize: q.pageSize, total };
  }

  // ───────────── Status changes ─────────────

  /**
   * The single way an order changes status. Checks the transition table, then
   * updates only if the status is still what we read (so two people acting at
   * once cannot both succeed), records an event, and emits it after commit.
   */
  async transition(
    orderId: string,
    to: OrderStatus,
    actor: TransitionActor,
    opts: TransitionOptions = {},
  ): Promise<OrderWithRelations> {
    const before = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!before) throw AppError.notFound('Order');
    if (!canTransition(before.status, to, actor.kind)) {
      throw AppError.conflict('INVALID_TRANSITION', `Cannot move an order from ${before.status} to ${to}`, {
        from: before.status,
        to,
      });
    }
    if (opts.expectDriverId) {
      const field = ASSIGNED_TO_DRIVER[before.status];
      if (!field || before[field] !== opts.expectDriverId) {
        throw AppError.forbidden('NOT_YOUR_ORDER', 'This order is not assigned to you');
      }
    }

    const now = this.clock.now();
    const data: Prisma.OrderUncheckedUpdateManyInput = { status: to };
    const where: Prisma.OrderWhereInput = { id: orderId, status: before.status };
    switch (to) {
      case OrderStatus.PICKUP_ASSIGNED:
      case OrderStatus.DELIVERY_ASSIGNED: {
        if (!opts.driverId) throw new Error(`driverId is required to move to ${to}`);
        const field = to === OrderStatus.PICKUP_ASSIGNED ? 'pickupDriverId' : 'deliveryDriverId';
        data[field] = opts.driverId;
        data.dispatchFailedAt = null;
        break;
      }
      case OrderStatus.PENDING:
        data.pickupDriverId = null;
        break;
      case OrderStatus.READY_FOR_DELIVERY:
        data.deliveryDriverId = null;
        break;
      case OrderStatus.PICKED_UP:
        data.pickedUpAt = now;
        break;
      case OrderStatus.DELIVERED:
        data.deliveredAt = now;
        break;
      case OrderStatus.CANCELLED:
        data.cancelledAt = now;
        data.cancelReason = opts.cancelReason?.trim() || null;
        break;
    }

    const { order, closed } = await this.prisma.$transaction(async (tx) => {
      const res = await tx.order.updateMany({ where, data });
      if (res.count === 0) {
        throw AppError.conflict('ORDER_CHANGED', 'The order was just updated by someone else. Refresh and try again.');
      }
      await tx.orderEvent.create({
        data: {
          orderId,
          fromStatus: before.status,
          toStatus: to,
          actorId: actor.id,
          actorRole: actor.role,
          note: opts.note?.trim() || opts.cancelReason?.trim() || null,
        },
      });
      if (opts.inTx) await opts.inTx(tx, before);

      // Once a leg is taken (or the order is cancelled), outstanding offers are void.
      let closed: { driverId: string; leg: DispatchLeg }[] = [];
      if (to === OrderStatus.PICKUP_ASSIGNED || to === OrderStatus.DELIVERY_ASSIGNED || to === OrderStatus.CANCELLED) {
        closed = await tx.dispatchOffer.findMany({
          where: { orderId, status: OfferStatus.PENDING },
          select: { driverId: true, leg: true },
        });
        if (closed.length) {
          await tx.dispatchOffer.updateMany({
            where: { orderId, status: OfferStatus.PENDING },
            data: { status: OfferStatus.CANCELLED, respondedAt: now },
          });
        }
      }
      const order = await tx.order.findUniqueOrThrow({ where: { id: orderId }, include: ORDER_INCLUDE });
      return { order, closed };
    });

    this.events.emit(Events.OrderStatusChanged, {
      ...orderRef(order),
      from: before.status,
      to,
      actorId: actor.id,
      actorRole: actor.role,
      removedDriverId:
        to === OrderStatus.PENDING
          ? before.pickupDriverId
          : to === OrderStatus.READY_FOR_DELIVERY
            ? before.deliveryDriverId
            : null,
    } satisfies OrderStatusChangedEvent);
    if (closed.length) {
      this.events.emit(Events.OffersClosed, {
        orderId,
        leg: closed[0].leg,
        driverIds: closed.map((c) => c.driverId),
      } satisfies OffersClosedEvent);
    }
    return order;
  }

  // ───────────── Editing items ─────────────

  /** Replaces line items (e.g. after counting clothes at pickup) and reprices the order. */
  async updateItems(orderId: string, lines: OrderLineInput[], actor: TransitionActor, note?: string): Promise<OrderWithRelations> {
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, include: { promotion: true } });
    if (!order) throw AppError.notFound('Order');
    if (!ITEMS_EDITABLE.includes(order.status)) {
      throw AppError.conflict('ITEMS_LOCKED', 'Items can no longer be changed for this order');
    }

    // Reprice with today's catalogue prices, the order's original promotion and delivery fee.
    const priced = computeQuote(
      await this.pricingLines(lines),
      { minOrderPaise: 0, deliveryFeePaise: order.deliveryFeePaise, freeDeliveryAbovePaise: null },
      order.promotion,
    );

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.order.updateMany({
        where: { id: orderId, status: order.status },
        data: {
          subtotalPaise: priced.subtotalPaise,
          discountPaise: priced.discountPaise,
          totalPaise: priced.totalPaise,
          paymentStatus: paymentStatusFor(priced.totalPaise, order.paidPaise, order.refundedPaise),
        },
      });
      if (res.count === 0) throw AppError.conflict('ORDER_CHANGED', 'The order was just updated. Refresh and try again.');
      await tx.orderItem.deleteMany({ where: { orderId } });
      await tx.orderItem.createMany({
        data: priced.lines.map((l) => ({
          orderId,
          catalogItemId: l.catalogItemId,
          name: l.name,
          unit: l.unit,
          unitPricePaise: l.unitPricePaise,
          quantity: l.quantity,
          lineTotalPaise: l.lineTotalPaise,
        })),
      });
      await tx.orderEvent.create({
        data: {
          orderId,
          fromStatus: order.status,
          toStatus: order.status,
          actorId: actor.id,
          actorRole: actor.role,
          note: note?.trim() || `Items updated, new total ₹${(priced.totalPaise / 100).toFixed(2)}`,
        },
      });
      return tx.order.findUniqueOrThrow({ where: { id: orderId }, include: ORDER_INCLUDE });
    });

    this.events.emit(Events.OrderUpdated, { ...orderRef(updated), reason: 'items_changed' } satisfies OrderUpdatedEvent);
    return updated;
  }
}

function addressSnapshot(a: Address, customer: User): Prisma.InputJsonObject {
  return {
    label: a.label,
    formatted: formatAddress(a),
    houseNo: a.houseNo,
    building: a.building,
    street: a.street,
    area: a.area,
    landmark: a.landmark,
    city: a.city,
    state: a.state,
    pincode: a.pincode,
    latitude: a.latitude,
    longitude: a.longitude,
    contactName: customer.name,
    contactPhone: customer.phone,
  };
}

/** Fingerprint of a place-order request, so a reused idempotency key with a different basket is refused. */
export function placeRequestHash(dto: PlaceOrderDto): string {
  const canonical = {
    items: dto.items.map((i) => `${i.catalogItemId}:${i.quantity}`).sort(),
    promoCode: dto.promoCode ?? null,
    pickup: [dto.pickupDate, dto.pickupSlot, dto.pickupAddressId],
    delivery: [dto.deliveryDate, dto.deliverySlot, dto.deliveryAddressId ?? null],
    paymentMethod: dto.paymentMethod,
    instructions: dto.instructions?.trim() || null,
  };
  return createHash('sha256').update(JSON.stringify(canonical)).digest('hex');
}
