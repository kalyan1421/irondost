import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { EventEmitter2, OnEvent } from '@nestjs/event-emitter';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { fromDbDate, slotEnd, slotStart } from '../common/time.js';
import {
  Events,
  type DispatchFailedEvent,
  type OffersClosedEvent,
  type OffersCreatedEvent,
  type OrderCreatedEvent,
  type OrderStatusChangedEvent,
} from '../events.js';
import { Prisma, type BusinessSettings, type DispatchOffer, type Order, type User } from '../generated/prisma/client.js';
import { DispatchLeg, OfferStatus, OrderStatus, Role } from '../generated/prisma/enums.js';
import { JobScheduler } from '../jobs/job-scheduler.js';
import type { OrderWithRelations } from '../orders/order.dto.js';
import { ASSIGNED_STATUS, AWAITING_DRIVER } from '../orders/order-state.js';
import { actorFor, OrdersService } from '../orders/orders.service.js';
import { PrismaService, type Tx } from '../prisma/prisma.service.js';
import { SettingsService } from '../settings/settings.service.js';

export const QUEUE_ROUND = 'dispatch-round';
export const QUEUE_EXPIRE = 'dispatch-expire';

interface RoundJob {
  orderId: string;
  leg: DispatchLeg;
}
interface ExpireJob extends RoundJob {
  round: number;
}

/** A driver who offered recently but did not respond is skipped for this long. */
const IGNORE_WINDOW_MS = 30 * 60_000;

type RoundOutcome =
  | { kind: 'skip' }
  | { kind: 'none'; order: Order; firstFailure: boolean }
  | { kind: 'offered'; order: Order; round: number; offers: DispatchOffer[] };

interface Candidate {
  id: string;
  distanceKm: number | null;
}

const ACTIVE_LEG_SQL = Prisma.sql`(
  SELECT count(*) FROM orders o
  WHERE (o.pickup_driver_id = u.id AND o.status = 'PICKUP_ASSIGNED')
     OR (o.delivery_driver_id = u.id AND o.status IN ('DELIVERY_ASSIGNED', 'OUT_FOR_DELIVERY'))
)`;

/**
 * Automatic driver assignment.
 *
 * Each round offers the order leg to the nearest N available drivers at once;
 * the first to accept gets it (the database decides the race). A round ends
 * when every offer is declined or the timeout passes, and the next round
 * skips drivers who already declined. When nobody is available the order is
 * flagged for admins and retried every few minutes until its slot ends.
 */
@Injectable()
export class DispatchService implements OnModuleInit {
  private readonly logger = new Logger(DispatchService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly orders: OrdersService,
    private readonly settings: SettingsService,
    private readonly jobs: JobScheduler,
    private readonly events: EventEmitter2,
    private readonly clock: Clock,
  ) {}

  onModuleInit(): void {
    this.jobs.register<RoundJob>(QUEUE_ROUND, (j) => this.runRound(j.orderId, j.leg));
    this.jobs.register<ExpireJob>(QUEUE_EXPIRE, (j) => this.expireRound(j.orderId, j.leg, j.round));
  }

  // ───────────── Triggers ─────────────

  @OnEvent(Events.OrderCreated, { async: true, suppressErrors: true })
  async onOrderCreated(e: OrderCreatedEvent): Promise<void> {
    await this.scheduleLeg(e.orderId, DispatchLeg.PICKUP).catch((err) => this.logger.error(err));
  }

  @OnEvent(Events.OrderStatusChanged, { async: true, suppressErrors: true })
  async onStatusChanged(e: OrderStatusChangedEvent): Promise<void> {
    try {
      if (e.to === OrderStatus.READY_FOR_DELIVERY) {
        // Ready from the workshop: wait for the delivery slot. Unassigned: look again now.
        await this.scheduleLeg(e.orderId, DispatchLeg.DELIVERY, e.from !== OrderStatus.PROCESSING);
      } else if (e.to === OrderStatus.PENDING && e.from === OrderStatus.PICKUP_ASSIGNED) {
        await this.scheduleLeg(e.orderId, DispatchLeg.PICKUP, true);
      }
    } catch (err) {
      this.logger.error(err);
    }
  }

  /** Queue the first round for a leg, `dispatchLeadMinutes` before its slot starts (or now). */
  async scheduleLeg(orderId: string, leg: DispatchLeg, immediately = false): Promise<void> {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) return;
    const settings = await this.settings.get();
    const now = this.clock.now().getTime();
    const slotAt = this.legSlotStart(order, leg).getTime();
    const startAfter = immediately ? now : Math.max(now, slotAt - settings.dispatchLeadMinutes * 60_000);
    await this.jobs.schedule<RoundJob>(QUEUE_ROUND, { orderId, leg }, { startAfter: new Date(startAfter) });
  }

  // ───────────── Rounds ─────────────

  async runRound(orderId: string, leg: DispatchLeg): Promise<void> {
    const settings = await this.settings.get();
    const now = this.clock.now();

    const outcome = await this.prisma.$transaction(async (tx): Promise<RoundOutcome> => {
      // One round at a time per order leg, even across API instances.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${`${orderId}:${leg}`}))`;

      const order = await tx.order.findUnique({ where: { id: orderId } });
      if (!order || order.status !== AWAITING_DRIVER[leg]) return { kind: 'skip' };
      const live = await tx.dispatchOffer.count({
        where: { orderId, leg, status: OfferStatus.PENDING, expiresAt: { gt: now } },
      });
      if (live > 0) return { kind: 'skip' };

      const last = await tx.dispatchOffer.aggregate({ where: { orderId, leg }, _max: { round: true } });
      const round = (last._max.round ?? 0) + 1;
      const skip = await tx.dispatchOffer.findMany({
        where: {
          orderId,
          leg,
          OR: [{ status: OfferStatus.REJECTED }, { offeredAt: { gt: new Date(now.getTime() - IGNORE_WINDOW_MS) } }],
        },
        select: { driverId: true },
        distinct: ['driverId'],
      });

      const [lat, lng] =
        leg === DispatchLeg.PICKUP
          ? [order.pickupLatitude, order.pickupLongitude]
          : [order.deliveryLatitude, order.deliveryLongitude];
      const candidates = await this.findCandidates(tx, lat, lng, skip.map((s) => s.driverId), settings, now);

      if (candidates.length === 0) {
        const firstFailure = order.dispatchFailedAt === null;
        const updated = firstFailure
          ? await tx.order.update({ where: { id: orderId }, data: { dispatchFailedAt: now } })
          : order;
        return { kind: 'none', order: updated, firstFailure };
      }

      const expiresAt = new Date(now.getTime() + settings.offerTimeoutSeconds * 1000);
      const offers = await Promise.all(
        candidates.map((c) =>
          tx.dispatchOffer.create({
            data: { orderId, driverId: c.id, leg, round, distanceKm: c.distanceKm, offeredAt: now, expiresAt },
          }),
        ),
      );
      return { kind: 'offered', order, round, offers };
    });

    if (outcome.kind === 'skip') return;

    if (outcome.kind === 'none') {
      if (outcome.firstFailure) {
        this.events.emit(Events.DispatchFailed, {
          orderId,
          orderNumber: outcome.order.orderNumber,
          leg,
        } satisfies DispatchFailedEvent);
      }
      const retryAt = now.getTime() + settings.dispatchRetryMinutes * 60_000;
      if (retryAt < this.legSlotEnd(outcome.order, leg).getTime()) {
        await this.jobs.schedule<RoundJob>(QUEUE_ROUND, { orderId, leg }, { startAfter: new Date(retryAt) });
      }
      return;
    }

    this.events.emit(Events.OffersCreated, {
      orderId,
      orderNumber: outcome.order.orderNumber,
      leg,
      offers: outcome.offers.map((o) => ({ offerId: o.id, driverId: o.driverId, expiresAt: o.expiresAt })),
    } satisfies OffersCreatedEvent);
    await this.jobs.schedule<ExpireJob>(
      QUEUE_EXPIRE,
      { orderId, leg, round: outcome.round },
      { startAfter: new Date(outcome.offers[0].expiresAt.getTime() + 1000) },
    );
  }

  /** Nearest online drivers with fresh locations and spare capacity. */
  private findCandidates(
    tx: Tx,
    lat: number | null,
    lng: number | null,
    skipDriverIds: string[],
    s: BusinessSettings,
    now: Date,
  ): Promise<Candidate[]> {
    const freshSince = new Date(now.getTime() - s.driverLocationMaxAgeMinutes * 60_000);
    const distance =
      lat === null || lng === null
        ? Prisma.sql`NULL::float8`
        : Prisma.sql`CASE WHEN dp.latitude IS NULL OR dp.longitude IS NULL THEN NULL ELSE
            6371 * 2 * asin(sqrt(
              power(sin(radians(dp.latitude - ${lat}) / 2), 2) +
              cos(radians(${lat})) * cos(radians(dp.latitude)) *
              power(sin(radians(dp.longitude - ${lng}) / 2), 2)
            )) END`;
    return tx.$queryRaw<Candidate[]>`
      SELECT u.id, ${distance} AS "distanceKm"
      FROM users u
      JOIN driver_profiles dp ON dp.user_id = u.id
      WHERE u.role = 'DRIVER'
        AND u.is_active
        AND u.deleted_at IS NULL
        AND dp.is_online
        AND dp.location_updated_at >= ${freshSince}
        AND NOT (u.id = ANY(${skipDriverIds}::uuid[]))
        AND ${ACTIVE_LEG_SQL} < ${s.driverMaxActiveLegs}
      ORDER BY "distanceKm" ASC NULLS LAST, dp.location_updated_at DESC
      LIMIT ${s.dispatchBatchSize}`;
  }

  async expireRound(orderId: string, leg: DispatchLeg, round: number): Promise<void> {
    const now = this.clock.now();
    const stale = await this.prisma.dispatchOffer.findMany({
      where: { orderId, leg, round, status: OfferStatus.PENDING },
      select: { id: true, driverId: true },
    });
    if (stale.length) {
      await this.prisma.dispatchOffer.updateMany({
        where: { id: { in: stale.map((s) => s.id) }, status: OfferStatus.PENDING },
        data: { status: OfferStatus.EXPIRED, respondedAt: now },
      });
      this.events.emit(Events.OffersClosed, {
        orderId,
        leg,
        driverIds: stale.map((s) => s.driverId),
      } satisfies OffersClosedEvent);
    }
    await this.runRound(orderId, leg);
  }

  // ───────────── Driver responses ─────────────

  listOffers(driverId: string) {
    return this.prisma.dispatchOffer.findMany({
      where: { driverId, status: OfferStatus.PENDING, expiresAt: { gt: this.clock.now() } },
      include: { order: { include: { items: true } } },
      orderBy: { offeredAt: 'desc' },
    });
  }

  async respond(driver: User, offerId: string, accept: boolean): Promise<OrderWithRelations | null> {
    const now = this.clock.now();
    const offer = await this.prisma.dispatchOffer.findUnique({ where: { id: offerId } });
    if (!offer || offer.driverId !== driver.id) throw AppError.notFound('Offer');
    if (offer.status !== OfferStatus.PENDING) throw AppError.conflict('OFFER_CLOSED', 'This offer is no longer open');
    if (offer.expiresAt <= now) throw AppError.conflict('OFFER_EXPIRED', 'This offer has expired');

    if (!accept) {
      const res = await this.prisma.dispatchOffer.updateMany({
        where: { id: offerId, status: OfferStatus.PENDING },
        data: { status: OfferStatus.REJECTED, respondedAt: now },
      });
      if (res.count === 0) throw AppError.conflict('OFFER_CLOSED', 'This offer is no longer open');
      const open = await this.prisma.dispatchOffer.count({
        where: { orderId: offer.orderId, leg: offer.leg, round: offer.round, status: OfferStatus.PENDING },
      });
      // Everyone in this round said no: move on straight away instead of waiting for the timeout.
      if (open === 0) await this.runRound(offer.orderId, offer.leg);
      return null;
    }

    const settings = await this.settings.get();
    const activeLegs = await this.prisma.order.count({
      where: {
        OR: [
          { pickupDriverId: driver.id, status: OrderStatus.PICKUP_ASSIGNED },
          {
            deliveryDriverId: driver.id,
            status: { in: [OrderStatus.DELIVERY_ASSIGNED, OrderStatus.OUT_FOR_DELIVERY] },
          },
        ],
      },
    });
    if (activeLegs >= settings.driverMaxActiveLegs) {
      throw AppError.conflict('TOO_MANY_ACTIVE', 'Finish your current pickups and deliveries first');
    }

    try {
      return await this.orders.transition(
        offer.orderId,
        ASSIGNED_STATUS[offer.leg],
        { id: driver.id, role: Role.DRIVER, kind: 'SYSTEM' },
        {
          driverId: driver.id,
          note: `Accepted by ${driver.name ?? driver.phone}`,
          inTx: async (tx) => {
            const res = await tx.dispatchOffer.updateMany({
              where: { id: offerId, status: OfferStatus.PENDING, expiresAt: { gt: now } },
              data: { status: OfferStatus.ACCEPTED, respondedAt: now },
            });
            if (res.count === 0) throw AppError.conflict('OFFER_CLOSED', 'This offer is no longer open');
          },
        },
      );
    } catch (err) {
      if (err instanceof AppError && (err.code === 'ORDER_CHANGED' || err.code === 'INVALID_TRANSITION')) {
        throw AppError.conflict('OFFER_TAKEN', 'Another partner accepted this order first');
      }
      throw err;
    }
  }

  // ───────────── Admin overrides ─────────────

  async assign(orderId: string, leg: DispatchLeg, driverId: string, admin: User): Promise<OrderWithRelations> {
    const driver = await this.prisma.user.findUnique({ where: { id: driverId } });
    if (!driver || driver.role !== Role.DRIVER || !driver.isActive || driver.deletedAt) {
      throw AppError.badRequest('INVALID_DRIVER', 'Choose an active delivery partner');
    }
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw AppError.notFound('Order');

    // Reassigning: release the current driver first.
    if (order.status === ASSIGNED_STATUS[leg]) {
      await this.unassign(orderId, leg, admin);
    }
    return this.orders.transition(orderId, ASSIGNED_STATUS[leg], actorFor(admin, 'ADMIN'), {
      driverId,
      note: `Assigned to ${driver.name ?? driver.phone} by admin`,
    });
  }

  async unassign(orderId: string, leg: DispatchLeg, admin: User): Promise<OrderWithRelations> {
    return this.orders.transition(orderId, AWAITING_DRIVER[leg], actorFor(admin, 'ADMIN'), {
      note: 'Driver unassigned by admin',
    });
  }

  private legSlotStart(order: Order, leg: DispatchLeg): Date {
    return leg === DispatchLeg.PICKUP
      ? slotStart(fromDbDate(order.pickupDate), order.pickupSlot)
      : slotStart(fromDbDate(order.deliveryDate), order.deliverySlot);
  }

  private legSlotEnd(order: Order, leg: DispatchLeg): Date {
    return leg === DispatchLeg.PICKUP
      ? slotEnd(fromDbDate(order.pickupDate), order.pickupSlot)
      : slotEnd(fromDbDate(order.deliveryDate), order.deliverySlot);
  }
}
