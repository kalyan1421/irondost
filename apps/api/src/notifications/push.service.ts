import { Injectable, Logger } from '@nestjs/common';
import { FirebaseService } from '../auth/firebase.service.js';
import type { PushDelivery } from '../generated/prisma/client.js';
import { ClientApp } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { deriveDelivery, thrownErrorCode, type DeliveryOutcome, type DeviceResult } from './push-delivery.js';

export interface PushMessage {
  title: string;
  body: string;
  /** String values only (FCM requirement). */
  data?: Record<string, string>;
  /** Urgent pushes (driver offers) wake the device and use the offers channel. */
  urgent?: boolean;
}

/**
 * Asks the push service to write down how each person's push went, so staff can follow up on the ones that did not
 * arrive. Only pushes that have an inbox row (and so can be retried) are recorded: offers are not.
 */
export interface PushRecord {
  type: string;
  orderId: string | null;
  /** The inbox row each recipient got. People missing from here are not recorded. */
  notificationIds: ReadonlyMap<string, string>;
}

const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** The inbox row fields a retry needs to push the same alert again. */
export interface ResendableNotification {
  id: string;
  userId: string;
  type: string;
  title: string;
  body: string;
  data: unknown;
}

/** Only string values can travel in an FCM data payload. */
function stringData(data: unknown): Record<string, string> {
  if (typeof data !== 'object' || data === null || Array.isArray(data)) return {};
  return Object.fromEntries(Object.entries(data).filter((e): e is [string, string] => typeof e[1] === 'string'));
}

/** Sends FCM pushes to a user's registered devices, prunes dead tokens and records how each person's push went. */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
  ) {}

  /** False in local development and tests (no Firebase service account): nothing is sent or recorded. */
  get configured(): boolean {
    return this.firebase.messaging !== null;
  }

  async send(userIds: string[], message: PushMessage, app?: ClientApp, record?: PushRecord): Promise<void> {
    const outcomes = await this.dispatch(userIds, message, app);
    if (!outcomes || !record || !app) return;
    // The push already went out; a failure to write it down must never look like a failure to send.
    await this.recordOutcomes(outcomes, message, app, record).catch((err: unknown) =>
      this.logger.error(`Could not record push deliveries: ${String(err)}`),
    );
  }

  /**
   * One more push of an inbox notification to its owner, recorded as a new delivery.
   * Returns null when push is not configured (nothing was sent).
   */
  async resend(n: ResendableNotification, app: ClientApp): Promise<PushDelivery | null> {
    const data = stringData(n.data);
    const message: PushMessage = { title: n.title, body: n.body, data: { type: n.type, ...data } };
    const outcomes = await this.dispatch([n.userId], message, app);
    const outcome = outcomes?.get(n.userId);
    if (!outcome) return null;
    return this.prisma.pushDelivery.create({
      data: {
        notificationId: n.id,
        userId: n.userId,
        app,
        type: n.type,
        title: n.title,
        orderId: data.orderId ?? null,
        ...outcome,
      },
    });
  }

  /**
   * Sends to every device of `userIds` (in `app` when given) and works out how it went for each person.
   * Null when push is not configured, which is not a failure. Prunes tokens that FCM says are dead.
   */
  private async dispatch(
    userIds: string[],
    message: PushMessage,
    app?: ClientApp,
  ): Promise<Map<string, DeliveryOutcome> | null> {
    const messaging = this.firebase.messaging;
    if (!messaging || userIds.length === 0) return null;
    const devices = await this.prisma.device.findMany({
      where: { userId: { in: userIds }, ...(app ? { app } : {}) },
      select: { userId: true, fcmToken: true },
    });
    const results = new Map<string, DeviceResult[]>([...new Set(userIds)].map((id) => [id, []]));
    if (devices.length > 0) {
      const tokens = devices.map((d) => d.fcmToken);
      try {
        const res = await messaging.sendEachForMulticast({
          tokens,
          notification: { title: message.title, body: message.body },
          data: message.data,
          android: {
            priority: 'high',
            notification: {
              channelId: message.urgent ? 'order_offers' : 'order_updates',
              sound: 'default',
              ...(message.urgent ? { priority: 'max' as const, visibility: 'public' as const } : {}),
            },
          },
          apns: {
            headers: { 'apns-priority': '10', ...(message.urgent ? { 'apns-push-type': 'alert' } : {}) },
            payload: { aps: { sound: 'default', ...(message.urgent ? { 'interruption-level': 'time-sensitive' } : {}) } },
          },
        });
        devices.forEach((d, i) => {
          const r = res.responses[i];
          results.get(d.userId)?.push({ success: r?.success ?? false, errorCode: r?.success === false ? (r.error?.code ?? null) : null });
        });
        const dead = res.responses
          .map((r, i) => (!r.success && r.error && DEAD_TOKEN_CODES.has(r.error.code) ? tokens[i] : null))
          .filter((t): t is string => t !== null);
        if (dead.length) {
          await this.prisma.device.deleteMany({ where: { fcmToken: { in: dead } } }).catch((err: unknown) =>
            this.logger.error(`Could not remove dead push tokens: ${String(err)}`),
          );
        }
      } catch (err) {
        this.logger.error(`Push failed: ${String(err)}`);
        const code = thrownErrorCode(err);
        for (const d of devices) results.get(d.userId)?.push({ success: false, errorCode: code });
      }
    }
    return new Map([...results].map(([userId, r]) => [userId, deriveDelivery(r)]));
  }

  private async recordOutcomes(
    outcomes: Map<string, DeliveryOutcome>,
    message: PushMessage,
    app: ClientApp,
    record: PushRecord,
  ): Promise<void> {
    const data = [...outcomes].flatMap(([userId, outcome]) => {
      const notificationId = record.notificationIds.get(userId);
      if (!notificationId) return [];
      return [{ notificationId, userId, app, type: record.type, title: message.title, orderId: record.orderId, ...outcome }];
    });
    if (data.length) await this.prisma.pushDelivery.createMany({ data });
  }
}
