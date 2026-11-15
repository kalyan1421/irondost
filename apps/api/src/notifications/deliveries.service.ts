import { HttpStatus, Injectable } from '@nestjs/common';
import { AuditService } from '../audit/audit.service.js';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { pageArgs } from '../common/pagination.js';
import { addDays, istInstant } from '../common/time.js';
import type { Prisma, User } from '../generated/prisma/client.js';
import { PushDeliveryStatus } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { DeliveriesQuery, DeliveryDto, DeliveryPageDto } from './deliveries.dto.js';
import {
  PROBLEM_STATUSES,
  RETRY_BLOCK_MESSAGE,
  deliveryReason,
  retryBlock,
  type AttemptSummary,
} from './push-delivery.js';
import { PushService } from './push.service.js';

const INCLUDE = {
  user: { select: { id: true, name: true, phone: true, contactPhone: true } },
  order: { select: { orderNumber: true } },
  handledBy: { select: { name: true, phone: true } },
} satisfies Prisma.PushDeliveryInclude;

type Row = Prisma.PushDeliveryGetPayload<{ include: typeof INCLUDE }>;

/** Admin view of pushes that did not arrive: the list, one more try, and "I followed up". */
@Injectable()
export class NotificationDeliveriesService {
  /** Notifications being retried right now, so a double click cannot push the same alert twice. */
  private readonly retrying = new Set<string>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
    private readonly clock: Clock,
    private readonly audit: AuditService,
  ) {}

  async list(q: DeliveriesQuery): Promise<DeliveryPageDto> {
    const orderNumber = q.orderNumber?.trim();
    const followUp = q.followUp ?? 'OPEN';
    const where: Prisma.PushDeliveryWhereInput = {
      status: q.status ?? { in: [...PROBLEM_STATUSES] },
      ...(q.app ? { app: q.app } : {}),
      ...(followUp === 'OPEN' ? { handledAt: null } : followUp === 'DONE' ? { handledAt: { not: null } } : {}),
      ...(q.from || q.to
        ? {
            createdAt: {
              ...(q.from ? { gte: istInstant(q.from, 0) } : {}),
              ...(q.to ? { lt: istInstant(addDays(q.to, 1), 0) } : {}),
            },
          }
        : {}),
      ...(orderNumber ? { order: { orderNumber: { contains: orderNumber, mode: 'insensitive' } } } : {}),
    };
    const [rows, total] = await Promise.all([
      this.prisma.pushDelivery.findMany({
        where,
        include: INCLUDE,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        ...pageArgs(q),
      }),
      this.prisma.pushDelivery.count({ where }),
    ]);
    const attempts = await this.attemptsFor(rows.map((r) => r.notificationId));
    return {
      items: rows.map((r) => this.toDto(r, attempts.get(r.notificationId ?? '') ?? [])),
      page: q.page,
      pageSize: q.pageSize,
      total,
    };
  }

  /**
   * Sends the same alert again and records it as a new delivery. The attempt it replaces is marked followed up, so
   * the open list shows one row per alert: the latest. Only the latest attempt can be retried, and only a few times.
   */
  async retry(actor: User, id: string): Promise<DeliveryDto> {
    const delivery = await this.prisma.pushDelivery.findUnique({ where: { id }, include: { notification: true } });
    if (!delivery) throw AppError.notFound('Delivery');
    const notificationId = delivery.notificationId;
    // Take the lock before reading the attempts: whoever gets here second sees the first one's new row, or the lock.
    if (notificationId && this.retrying.has(notificationId)) {
      throw AppError.conflict('RETRY_IN_PROGRESS', 'This alert is being resent right now. Check again in a moment.');
    }
    if (notificationId) this.retrying.add(notificationId);
    try {
      const attempts = notificationId ? ((await this.attemptsFor([notificationId])).get(notificationId) ?? []) : [];
      const block = retryBlock(delivery, attempts);
      if (block) throw AppError.conflict(block, RETRY_BLOCK_MESSAGE[block]);
      if (!delivery.notification) throw AppError.conflict('NOTIFICATION_GONE', RETRY_BLOCK_MESSAGE.NOTIFICATION_GONE);
      const created = this.push.configured ? await this.push.resend(delivery.notification, delivery.app) : null;
      if (!created) {
        throw new AppError(
          HttpStatus.SERVICE_UNAVAILABLE,
          'PUSH_NOT_CONFIGURED',
          'Push notifications are not set up on this server, so nothing can be resent.',
        );
      }
      await this.prisma.pushDelivery.updateMany({
        where: { id, handledAt: null },
        data: { handledAt: this.clock.now(), handledById: actor.id },
      });
      this.audit.log(actor.id, 'notification_delivery.retried', 'push_delivery', id, {
        newDeliveryId: created.id,
        result: created.status,
        userId: delivery.userId,
        orderId: delivery.orderId,
      });
      return await this.one(created.id);
    } finally {
      if (notificationId) this.retrying.delete(notificationId);
    }
  }

  /** Marks an alert as followed up (for example the person was phoned). Doing it twice changes nothing. */
  async handled(actor: User, id: string): Promise<DeliveryDto> {
    const delivery = await this.prisma.pushDelivery.findUnique({ where: { id } });
    if (!delivery) throw AppError.notFound('Delivery');
    if (delivery.status === PushDeliveryStatus.SENT) {
      throw AppError.conflict('ALREADY_DELIVERED', 'This alert reached the person, so there is nothing to follow up.');
    }
    const { count } = await this.prisma.pushDelivery.updateMany({
      where: { id, handledAt: null },
      data: { handledAt: this.clock.now(), handledById: actor.id },
    });
    if (count > 0) {
      this.audit.log(actor.id, 'notification_delivery.handled', 'push_delivery', id, {
        userId: delivery.userId,
        orderId: delivery.orderId,
      });
    }
    return this.one(id);
  }

  private async one(id: string): Promise<DeliveryDto> {
    const row = await this.prisma.pushDelivery.findUniqueOrThrow({ where: { id }, include: INCLUDE });
    const attempts = await this.attemptsFor([row.notificationId]);
    return this.toDto(row, attempts.get(row.notificationId ?? '') ?? []);
  }

  /** Every recorded attempt for each notification, to decide which one can still be retried. */
  private async attemptsFor(notificationIds: (string | null)[]): Promise<Map<string, AttemptSummary[]>> {
    const ids = [...new Set(notificationIds.filter((n): n is string => n !== null))];
    const map = new Map<string, AttemptSummary[]>();
    if (ids.length === 0) return map;
    const rows = await this.prisma.pushDelivery.findMany({
      where: { notificationId: { in: ids } },
      select: { id: true, status: true, createdAt: true, notificationId: true },
    });
    for (const r of rows) {
      const list = map.get(r.notificationId ?? '') ?? [];
      list.push({ id: r.id, status: r.status, createdAt: r.createdAt });
      map.set(r.notificationId ?? '', list);
    }
    return map;
  }

  private toDto(r: Row, attempts: readonly AttemptSummary[]): DeliveryDto {
    const block = retryBlock(r, attempts);
    // A deleted account keeps no name or number ("deleted:<id>" is a placeholder, not a phone).
    const phone = r.user.phone ?? r.user.contactPhone;
    return {
      id: r.id,
      status: r.status,
      app: r.app,
      type: r.type,
      title: r.title,
      deviceCount: r.deviceCount,
      failedCount: r.failedCount,
      errorCode: r.errorCode,
      reason: deliveryReason(r.status, r.errorCode),
      recipient: { id: r.user.id, name: r.user.name, phone: phone?.startsWith('+') ? phone : null },
      orderId: r.orderId,
      orderNumber: r.order?.orderNumber ?? null,
      createdAt: r.createdAt,
      handledAt: r.handledAt,
      handledByName: r.handledBy ? (r.handledBy.name ?? r.handledBy.phone) : null,
      canRetry: block === null,
      retryBlockedReason: block ? RETRY_BLOCK_MESSAGE[block] : null,
    };
  }
}
