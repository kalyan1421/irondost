import { Injectable, Logger } from '@nestjs/common';
import { FirebaseService } from '../auth/firebase.service.js';
import { ClientApp } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';

export interface PushMessage {
  title: string;
  body: string;
  /** String values only (FCM requirement). */
  data?: Record<string, string>;
  /** Urgent pushes (driver offers) wake the device and use the offers channel. */
  urgent?: boolean;
}

const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** Sends FCM pushes to a user's registered devices and prunes dead tokens. */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
  ) {}

  async send(userIds: string[], message: PushMessage, app?: ClientApp): Promise<void> {
    if (!this.firebase.messaging || userIds.length === 0) return;
    const devices = await this.prisma.device.findMany({
      where: { userId: { in: userIds }, ...(app ? { app } : {}) },
      select: { fcmToken: true },
    });
    if (devices.length === 0) return;
    const tokens = devices.map((d) => d.fcmToken);

    try {
      const res = await this.firebase.messaging.sendEachForMulticast({
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
      const dead = res.responses
        .map((r, i) => (!r.success && r.error && DEAD_TOKEN_CODES.has(r.error.code) ? tokens[i] : null))
        .filter((t): t is string => t !== null);
      if (dead.length) await this.prisma.device.deleteMany({ where: { fcmToken: { in: dead } } });
    } catch (err) {
      this.logger.error(`Push failed: ${String(err)}`);
    }
  }
}
