import { createHash } from 'node:crypto';
import { Inject, Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { formatAddress } from '../addresses/address.dto.js';
import { AddressesService } from '../addresses/addresses.service.js';
import { JobScheduler } from '../jobs/job-scheduler.js';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { pageArgs, type Page } from '../common/pagination.js';
import { customerPhone } from '../common/phone.js';
import { addDays, istDate, istInstant, slotEnd, SLOT_ORDER, toDbDate } from '../common/time.js';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import {
  Events,
  type OffersClosedEvent,
  type OrderCreatedEvent,
  type OrderRef,
  type OrderRescheduledEvent,
  type OrderStatusChangedEvent,
  type OrderUpdatedEvent,
  type OrderWindows,
} from '../events.js';
import { Prisma, type Address, type Order, type User } from '../generated/prisma/client.js';
import { DispatchLeg, OfferStatus, OrderSource, OrderStatus, PaymentMethod, Role } from '../generated/prisma/enums.js';
import { PrismaService, type Tx } from '../prisma/prisma.service.js';
import { checkDelivery, checkPickup, SCHEDULE_ERROR_MESSAGES } from '../scheduling/schedule-rules.js';
import { checkServiceArea } from '../settings/service-area.js';
import { SettingsService } from '../settings/settings.service.js';
import type { AdminOrdersQuery, OrderLineInput, OrderScope, OrderWithRelations, PlaceOrderDto, QuoteDto, RescheduleOrderDto } from './order.dto.js';
import { canTransition, FINAL_STATUSES, ITEMS_EDITABLE, type ActorKind } from './order-state.js';
import { refundDueOrderIds } from './refund-due.js';
import { computeQuote, paymentStatusFor, type PricingLine, type PricingPromotion, type Quote } from './pricing.js';
import {
  deliveryChanged,
  pickupChanged,
  RESCHEDULE_ERROR_MESSAGES,
  rescheduleError,
  rescheduleNote,
  rescheduleRequestHash,
  windowsOf,
  type RescheduleError,
} from './reschedule.js';

export const ORDER_INCLUDE = {
  items: true,
  customer: true,
  pickupDriver: true,
  deliveryDriver: true,
  adjustments: { orderBy: { createdAt: 'desc' } },
  payments: { where: { status: 'CAPTURED' }, orderBy: { createdAt: 'asc' } },
  refunds: { orderBy: { createdAt: 'asc' }, include: { createdBy: { select: { id: true, name: true } } } },
} as const satisfies Prisma.OrderInclude;

/**
 * For lists: only the newest price request. A pending one is always the newest (a new request waits for the decision), and
 * a list row needs no more than that, so the item snapshots of older requests are not read for every order on the page.
 */
export const ORDER_LIST_INCLUDE = {
  ...ORDER_INCLUDE,
  adjustments: { orderBy: { createdAt: 'desc' }, take: 1 },
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

export interface RescheduleResult {
  order: OrderWithRelations;
  /** A retry of a request that already went through: nothing changed and nothing was counted. */
  replayed: boolean;
  previous: OrderWindows;
  next: OrderWindows;
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
export class OrdersService implements OnModuleInit {
  private readonly logger = new Logger(OrdersService.name);
  constructor(
    private readonly prisma: PrismaService,
    private readonly settings: SettingsService,
    private readonly addresses: AddressesService,
    private readonly events: EventEmitter2,
    private readonly clock: Clock,
    @Inject(APP_ENV) private readonly env: Env,
    @Optional() private readonly jobs?: JobScheduler,
  ) {}

  async onModuleInit(): Promise<void> {
    if (!this.jobs) return;
    this.jobs.register<{ adjustmentId: string }>('adjustments-expire', (data) => this.expireAdjustment(data.adjustmentId));
    const pending = await this.prisma.orderAdjustment.findMany({ where: { status: 'PENDING_CUSTOMER' }, select: { id: true, expiresAt: true } });
    for (const request of pending) await this.jobs.schedule('adjustments-expire', { adjustmentId: request.id }, { startAfter: request.expiresAt, jobId: request.id });
  }

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
    // A customer who signed in with Google has no number until they add one; the pickup partner needs it.
    if (!customerPhone(customer)) {
      throw AppError.badRequest('PHONE_REQUIRED', 'Add your mobile number to place an order');
    }

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
        include: ORDER_LIST_INCLUDE,
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
    if (order.adjustments.some((a) => a.status === 'PENDING_CUSTOMER' && a.expiresAt <= this.clock.now())) {
      return this.getById(id);
    }
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

  // ───────────── Rescheduling ─────────────

  /**
   * The customer moves the pickup and/or delivery time of an order that has not been picked up, at most
   * MAX_RESCHEDULES times. Prices do not change. When the pickup moves and a partner had accepted it, the partner is
   * released and the order goes back to PENDING so dispatch offers the new window; offers still open for the old
   * window are cancelled. The new dates, the count, the history line and the release commit together, and dispatch
   * hears about it only after the commit, so it always reads the new dates. A retry with the same Idempotency-Key
   * and the same times returns the order as it is now (`replayed: true`) and counts nothing.
   */
  async reschedule(customer: User, orderId: string, dto: RescheduleOrderDto, idempotencyKey?: string): Promise<RescheduleResult> {
    const next: OrderWindows = {
      pickupDate: dto.pickupDate,
      pickupSlot: dto.pickupSlot,
      deliveryDate: dto.deliveryDate,
      deliverySlot: dto.deliverySlot,
    };
    const hash = rescheduleRequestHash(orderId, next);
    const settings = await this.settings.get();
    const now = this.clock.now();

    const done = await this.prisma.$transaction(async (tx) => {
      // Lock the customer's own order: a partner accepting or a pickup being recorded at this moment waits for this
      // move to commit, then re-checks the status it expected.
      await tx.$queryRaw`SELECT id FROM orders WHERE id = ${orderId}::uuid AND customer_id = ${customer.id}::uuid FOR UPDATE`;
      const order = await tx.order.findFirst({
        where: { id: orderId, customerId: customer.id },
        include: { ...ORDER_INCLUDE, events: { orderBy: { createdAt: 'asc' } } },
      });
      if (!order) throw AppError.notFound('Order');

      const previous = windowsOf(order);
      if (idempotencyKey && order.rescheduleKey === idempotencyKey) {
        if (order.rescheduleHash !== hash) {
          throw AppError.conflict('IDEMPOTENCY_KEY_REUSED', 'This Idempotency-Key was already used for a different change');
        }
        return { order, replayed: true as const, previous, next };
      }

      const failure = rescheduleError(order, previous, next, now, settings);
      if (failure) throw rescheduleFailure(failure);

      const movesPickup = pickupChanged(previous, next);
      const releasesPartner = movesPickup && order.status === OrderStatus.PICKUP_ASSIGNED;
      const to = releasesPartner ? OrderStatus.PENDING : order.status;
      await tx.order.update({
        where: { id: orderId },
        data: {
          pickupDate: toDbDate(next.pickupDate),
          pickupSlot: next.pickupSlot,
          deliveryDate: toDbDate(next.deliveryDate),
          deliverySlot: next.deliverySlot,
          rescheduleCount: { increment: 1 },
          rescheduleKey: idempotencyKey ?? null,
          rescheduleHash: idempotencyKey ? hash : null,
          // A new pickup window gets a fresh dispatch attempt, so an earlier "no partner found" no longer applies.
          ...(movesPickup ? { dispatchFailedAt: null, pickupRescheduledAt: now } : {}),
          ...(releasesPartner ? { status: OrderStatus.PENDING, pickupDriverId: null } : {}),
        },
      });
      await tx.orderEvent.create({
        data: {
          orderId,
          fromStatus: order.status,
          toStatus: to,
          actorId: customer.id,
          actorRole: customer.role,
          note: rescheduleNote(previous, next),
        },
      });

      // Offers still open were made for the old window: a partner must not accept one and land on the new time.
      let closed: { driverId: string; leg: DispatchLeg }[] = [];
      if (movesPickup) {
        closed = await tx.dispatchOffer.findMany({ where: { orderId, status: OfferStatus.PENDING }, select: { driverId: true, leg: true } });
        if (closed.length) {
          await tx.dispatchOffer.updateMany({ where: { orderId, status: OfferStatus.PENDING }, data: { status: OfferStatus.CANCELLED, respondedAt: now } });
        }
      }
      const updated = await tx.order.findUniqueOrThrow({
        where: { id: orderId },
        include: { ...ORDER_INCLUDE, events: { orderBy: { createdAt: 'asc' } } },
      });
      return { order: updated, replayed: false as const, previous, next, before: order, to, movesPickup, closed };
    });

    if (done.replayed) return { order: done.order, replayed: true, previous: done.previous, next: done.next };

    this.events.emit(Events.OrderRescheduled, {
      ...orderRef(done.order),
      from: done.before.status,
      to: done.to,
      previous: done.previous,
      next: done.next,
      pickupChanged: done.movesPickup,
      deliveryChanged: deliveryChanged(done.previous, done.next),
      removedDriverId: done.to === OrderStatus.PENDING && done.before.status === OrderStatus.PICKUP_ASSIGNED ? done.before.pickupDriverId : null,
    } satisfies OrderRescheduledEvent);
    if (done.closed.length) {
      this.events.emit(Events.OffersClosed, {
        orderId,
        leg: done.closed[0].leg,
        driverIds: done.closed.map((c) => c.driverId),
      } satisfies OffersClosedEvent);
    }
    return { order: done.order, replayed: false, previous: done.previous, next: done.next };
  }

  async getById(id: string): Promise<OrderWithRelations> {
    await this.expireOrderAdjustments(id);
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { ...ORDER_INCLUDE, events: { orderBy: { createdAt: 'asc' } } },
    });
    if (!order) throw AppError.notFound('Order');
    return order;
  }

  async adminList(q: AdminOrdersQuery): Promise<Page<OrderWithRelations>> {
    const search = q.search?.trim();
    const refundDueIds = q.refundDue ? await refundDueOrderIds(this.prisma) : null;
    const where: Prisma.OrderWhereInput = {
      ...(refundDueIds ? { id: { in: refundDueIds } } : {}),
      ...(q.excludeCancelled ? { NOT: { status: OrderStatus.CANCELLED } } : {}),
      ...(q.approvalPending ? { adjustments: { some: { status: 'PENDING_CUSTOMER', expiresAt: { gt: this.clock.now() } } } } : {}),
      ...(q.unpaid ? { paidPaise: { lt: this.prisma.order.fields.totalPaise } } : {}),
      ...(q.createdFrom || q.createdTo ? { createdAt: {
        ...(q.createdFrom ? { gte: istInstant(q.createdFrom, 0) } : {}),
        ...(q.createdTo ? { lt: istInstant(addDays(q.createdTo, 1), 0) } : {}),
      } } : {}),
      ...(q.deliveryFrom || q.deliveryTo ? { deliveryDate: {
        ...(q.deliveryFrom ? { gte: toDbDate(q.deliveryFrom) } : {}), ...(q.deliveryTo ? { lte: toDbDate(q.deliveryTo) } : {}),
      } } : {}),
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
                  { customer: { contactPhone: { contains: search.replace(/\s/g, '') } } },
                  { customer: { name: { contains: search, mode: 'insensitive' } } },
                ],
              },
            ],
          }
        : {}),
    };
    if (q.overdue) {
      const now = this.clock.now(); const today = istDate(now);
      const pickup = q.overdue === 'pickup'; const dateKey = pickup ? 'pickupDate' : 'deliveryDate'; const slotKey = pickup ? 'pickupSlot' : 'deliverySlot';
      const condition: Prisma.OrderWhereInput = { status: { in: pickup ? [OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED]
        : [OrderStatus.PICKED_UP, OrderStatus.PROCESSING, OrderStatus.READY_FOR_DELIVERY, OrderStatus.DELIVERY_ASSIGNED, OrderStatus.OUT_FOR_DELIVERY] },
        OR: [{ [dateKey]: { lt: toDbDate(today) } }, ...SLOT_ORDER.filter((slot) => slotEnd(today, slot) <= now).map((slot) => ({ [dateKey]: toDbDate(today), [slotKey]: slot }))] };
      where.AND = [...(Array.isArray(where.AND) ? where.AND : where.AND ? [where.AND] : []), condition];
    }
    const [items, total] = await Promise.all([
      this.prisma.order.findMany({ where, include: ORDER_LIST_INCLUDE, orderBy: { createdAt: 'desc' }, ...pageArgs(q) }),
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
    // An elapsed price request must not block pickup or delivery just because its expiry job has not run yet.
    await this.expireOrderAdjustments(orderId);
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
      if (['PICKED_UP', 'READY_FOR_DELIVERY', 'OUT_FOR_DELIVERY', 'DELIVERED'].includes(to) &&
        await tx.orderAdjustment.findFirst({ where: { orderId, status: 'PENDING_CUSTOMER' } })) {
        throw AppError.conflict('APPROVAL_PENDING', 'The customer must decide the proposed total before this step.');
      }
      if (to === OrderStatus.CANCELLED) await tx.orderAdjustment.updateMany({ where: { orderId, status: 'PENDING_CUSTOMER' }, data: { status: 'EXPIRED', decidedAt: now } });
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
      paidPaise: order.paidPaise,
      refundedPaise: order.refundedPaise,
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

  // ───────────── Item changes and customer consent ─────────────

  private async editQuote(orderId: string, lines: OrderLineInput[], expectedRevision?: number) {
    await this.expireOrderAdjustments(orderId);
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, include: { ...ORDER_INCLUDE, promotion: true } });
    if (!order) throw AppError.notFound('Order');
    if (!ITEMS_EDITABLE.includes(order.status)) throw AppError.conflict('ITEMS_LOCKED', 'Items can no longer be changed for this order');
    if (expectedRevision !== undefined && expectedRevision !== order.revision) throw AppError.conflict('ORDER_CHANGED', 'This bill changed. Refresh and compare your draft before saving.');
    const quantities = new Map<string, number>();
    for (const line of lines) {
      const quantity = (quantities.get(line.catalogItemId) ?? 0) + line.quantity;
      if (quantity > 500) throw AppError.badRequest('QUANTITY_LIMIT', 'Use no more than 500 of one item');
      quantities.set(line.catalogItemId, quantity);
    }
    const existing = new Map(order.items.filter((i) => i.catalogItemId).map((i) => [i.catalogItemId!, i]));
    const added = await this.pricingLines([...quantities].filter(([id]) => !existing.has(id)).map(([catalogItemId, quantity]) => ({ catalogItemId, quantity })));
    const current = new Map(added.map((i) => [i.catalogItemId, i]));
    const priced = computeQuote([...quantities].map(([id, quantity]) => {
      const item = existing.get(id) ?? current.get(id)!;
      return { catalogItemId: id, name: item.name, unit: item.unit, unitPricePaise: item.unitPricePaise, quantity };
    }), { minOrderPaise: 0, deliveryFeePaise: order.deliveryFeePaise, freeDeliveryAbovePaise: null }, order.promotion);
    return { order, priced };
  }

  async previewItems(orderId: string, lines: OrderLineInput[], expectedRevision?: number) {
    const { order, priced } = await this.editQuote(orderId, lines, expectedRevision);
    return { revision: order.revision, oldTotalPaise: order.totalPaise, newTotalPaise: priced.totalPaise,
      subtotalPaise: priced.subtotalPaise, discountPaise: priced.discountPaise, deliveryFeePaise: priced.deliveryFeePaise,
      lines: priced.lines, requiresApproval: priced.totalPaise > order.totalPaise };
  }

  private async writeItemLines(tx: Tx, order: Pick<Order, 'id' | 'status'>, lines: PricingLine[], actor: TransitionActor, note: string) {
    await tx.orderItem.deleteMany({ where: { orderId: order.id } });
    await tx.orderItem.createMany({ data: lines.map((l) => ({ orderId: order.id, ...l, lineTotalPaise: l.unitPricePaise * l.quantity })) });
    await tx.orderEvent.create({ data: { orderId: order.id, fromStatus: order.status, toStatus: order.status, actorId: actor.id, actorRole: actor.role, note } });
  }

  async updateItems(orderId: string, lines: OrderLineInput[], actor: TransitionActor, note?: string, expectedRevision?: number): Promise<OrderWithRelations> {
    const { order, priced } = await this.editQuote(orderId, lines, expectedRevision);
    const increase = priced.totalPaise > order.totalPaise;
    if (increase && !actor.id) throw AppError.badRequest('ACTOR_REQUIRED', 'A staff member or assigned partner must request the change');
    const settings = increase ? await this.settings.get() : null;
    const now = this.clock.now();
    const result = await this.prisma.$transaction(async (tx) => {
      // Updating the revision locks the row. A second editor cannot replace the same accepted revision.
      const changed = await tx.order.updateMany({ where: { id: orderId, revision: order.revision, status: order.status,
        paidPaise: order.paidPaise, refundedPaise: order.refundedPaise }, data: { revision: { increment: 1 },
        ...(!increase ? { subtotalPaise: priced.subtotalPaise, discountPaise: priced.discountPaise, totalPaise: priced.totalPaise,
          paymentStatus: paymentStatusFor(priced.totalPaise, order.paidPaise, order.refundedPaise) } : {}) } });
      if (changed.count !== 1) throw AppError.conflict('ORDER_CHANGED', 'This order changed. Refresh and compare your draft before saving.');
      if (await tx.orderAdjustment.findFirst({ where: { orderId, status: 'PENDING_CUSTOMER' } })) {
        throw AppError.conflict('APPROVAL_PENDING', 'Wait for the customer to decide the existing price request.');
      }
      let adjustmentId: string | undefined;
      if (increase) {
        const adjustment = await tx.orderAdjustment.create({ data: { orderId, requestedById: actor.id!,
          reason: note?.trim() || 'Item count updated after collection', oldTotalPaise: order.totalPaise, newTotalPaise: priced.totalPaise,
          subtotalPaise: priced.subtotalPaise, discountPaise: priced.discountPaise, deliveryFeePaise: priced.deliveryFeePaise,
          baseRevision: order.revision + 1, itemsBefore: order.items as unknown as Prisma.InputJsonValue,
          itemsAfter: priced.lines as unknown as Prisma.InputJsonValue,
          expiresAt: new Date(now.getTime() + (settings?.adjustmentExpiryHours ?? 12) * 3_600_000) } });
        adjustmentId = adjustment.id;
        await tx.orderEvent.create({ data: { orderId, fromStatus: order.status, toStatus: order.status,
          actorId: actor.id, actorRole: actor.role, note: `Customer approval requested: ${adjustment.reason}` } });
      } else {
        await this.writeItemLines(tx, order, priced.lines, actor, note?.trim() || 'Item count updated; quoted rates preserved');
      }
      return { updated: await tx.order.findUniqueOrThrow({ where: { id: orderId }, include: ORDER_INCLUDE }), adjustmentId };
    });
    if (result.adjustmentId) {
      const adjustment = result.updated.adjustments.find((a) => a.id === result.adjustmentId)!;
      this.events.emit(Events.AdjustmentChanged, { ...orderRef(result.updated), adjustmentId: adjustment.id, status: 'PENDING_CUSTOMER', newTotalPaise: adjustment.newTotalPaise });
      await this.jobs?.schedule('adjustments-expire', { adjustmentId: adjustment.id }, { startAfter: adjustment.expiresAt, jobId: adjustment.id }).catch((err) => this.logger.error('Could not schedule adjustment expiry', err));
    } else {
      this.events.emit(Events.OrderUpdated, { ...orderRef(result.updated), reason: 'items_changed', previousTotalPaise: order.totalPaise,
        totalPaise: result.updated.totalPaise, paidPaise: result.updated.paidPaise, refundedPaise: result.updated.refundedPaise, actorRole: actor.role } satisfies OrderUpdatedEvent);
    }
    this.events.emit(Events.OrderUpdated, { ...orderRef(result.updated), reason: 'details_changed' } satisfies OrderUpdatedEvent);
    return result.updated;
  }

  async decideAdjustment(customer: User, orderId: string, adjustmentId: string, approve: boolean): Promise<OrderWithRelations> {
    await this.expireOrderAdjustments(orderId);
    const result = await this.prisma.$transaction(async (tx) => {
      // All bill mutations lock the order first, then inspect the request.
      await tx.$queryRaw`SELECT id FROM orders WHERE id = ${orderId}::uuid FOR UPDATE`;
      const order = await tx.order.findFirst({ where: { id: orderId, customerId: customer.id }, include: ORDER_INCLUDE });
      if (!order) throw AppError.notFound('Order');
      const adjustment = await tx.orderAdjustment.findFirst({ where: { id: adjustmentId, orderId } });
      if (!adjustment) throw AppError.notFound('Price request');
      const status = approve ? 'APPROVED' : 'DECLINED';
      if (adjustment.status === status) return { order, changed: false };
      if (adjustment.status !== 'PENDING_CUSTOMER') throw AppError.conflict('ADJUSTMENT_DECIDED', 'This price request is no longer waiting for a decision.');
      if (this.clock.now() >= adjustment.expiresAt) throw AppError.conflict('ADJUSTMENT_EXPIRED', 'This price request expired. The original total stands.');
      if (!ITEMS_EDITABLE.includes(order.status) || order.revision !== adjustment.baseRevision || order.totalPaise !== adjustment.oldTotalPaise) {
        throw AppError.conflict('ORDER_CHANGED', 'The order changed. Contact support before approving another total.');
      }
      const decided = await tx.orderAdjustment.updateMany({ where: { id: adjustmentId, status: 'PENDING_CUSTOMER' }, data: { status, decidedAt: this.clock.now() } });
      if (decided.count !== 1) throw AppError.conflict('ADJUSTMENT_DECIDED', 'This price request has already been decided.');
      if (approve) {
        await tx.order.update({ where: { id: orderId }, data: { subtotalPaise: adjustment.subtotalPaise, discountPaise: adjustment.discountPaise,
          deliveryFeePaise: adjustment.deliveryFeePaise, totalPaise: adjustment.newTotalPaise, revision: { increment: 1 },
          paymentStatus: paymentStatusFor(adjustment.newTotalPaise, order.paidPaise, order.refundedPaise) } });
        await this.writeItemLines(tx, order, adjustment.itemsAfter as unknown as PricingLine[], actorFor(customer, 'CUSTOMER'), `Customer approved the new total: ${adjustment.reason}`);
      } else {
        await tx.orderEvent.create({ data: { orderId, fromStatus: order.status, toStatus: order.status, actorId: customer.id, actorRole: customer.role, note: 'Customer declined the proposed total. The original bill stands.' } });
      }
      return { order: await tx.order.findUniqueOrThrow({ where: { id: orderId }, include: ORDER_INCLUDE }), changed: true };
    });
    if (result.changed) {
      this.events.emit(Events.AdjustmentChanged, { ...orderRef(result.order), adjustmentId, status: approve ? 'APPROVED' : 'DECLINED', newTotalPaise: result.order.totalPaise });
      this.events.emit(Events.OrderUpdated, { ...orderRef(result.order), reason: 'details_changed' } satisfies OrderUpdatedEvent);
    }
    return result.order;
  }

  async expireAdjustment(adjustmentId: string): Promise<void> {
    const changed = await this.prisma.orderAdjustment.updateMany({ where: { id: adjustmentId, status: 'PENDING_CUSTOMER', expiresAt: { lte: this.clock.now() } }, data: { status: 'EXPIRED', decidedAt: this.clock.now() } });
    if (changed.count !== 1) return;
    const adjustment = await this.prisma.orderAdjustment.findUniqueOrThrow({ where: { id: adjustmentId }, include: { order: true } });
    this.events.emit(Events.AdjustmentChanged, { ...orderRef(adjustment.order), adjustmentId, status: 'EXPIRED', newTotalPaise: adjustment.newTotalPaise });
    this.events.emit(Events.OrderUpdated, { ...orderRef(adjustment.order), reason: 'details_changed' } satisfies OrderUpdatedEvent);
  }

  private async expireOrderAdjustments(orderId: string): Promise<void> {
    const due = await this.prisma.orderAdjustment.findMany({ where: { orderId, status: 'PENDING_CUSTOMER', expiresAt: { lte: this.clock.now() } }, select: { id: true } });
    for (const request of due) await this.expireAdjustment(request.id);
  }

}

/** Rules about the order's state are conflicts (409); a time that is not allowed is a bad request, as when booking. */
function rescheduleFailure(code: RescheduleError): AppError {
  const message = RESCHEDULE_ERROR_MESSAGES[code];
  return code === 'RESCHEDULE_NOT_ALLOWED' || code === 'RESCHEDULE_LIMIT' ? AppError.conflict(code, message) : AppError.badRequest(code, message);
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
    contactPhone: customerPhone(customer),
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
