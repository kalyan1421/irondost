import type { Prisma } from '../generated/prisma/client.js';
import { PushDeliveryStatus } from '../generated/prisma/enums.js';

/** What happened to the push on one device: delivered to FCM, or refused with an error code. */
export interface DeviceResult {
  success: boolean;
  errorCode?: string | null;
}

/** How one person's push went, derived from the result of each of their devices. */
export interface DeliveryOutcome {
  status: PushDeliveryStatus;
  deviceCount: number;
  failedCount: number;
  /** First failure's code; null when nothing failed. */
  errorCode: string | null;
}

/**
 * Turns the per-device results into one status. No devices at all is NO_DEVICE (the person never allowed
 * notifications, or signed out); every device refusing is FAILED; some refusing is PARTIAL. The numbers always agree
 * with the status (the push_deliveries_status_counts CHECK enforces it).
 */
export function deriveDelivery(results: readonly DeviceResult[]): DeliveryOutcome {
  const deviceCount = results.length;
  const failures = results.filter((r) => !r.success);
  const failedCount = failures.length;
  const errorCode = failures.length === 0 ? null : (failures[0].errorCode ?? 'unknown');
  const status =
    deviceCount === 0
      ? PushDeliveryStatus.NO_DEVICE
      : failedCount === 0
        ? PushDeliveryStatus.SENT
        : failedCount === deviceCount
          ? PushDeliveryStatus.FAILED
          : PushDeliveryStatus.PARTIAL;
  return { status, deviceCount, failedCount, errorCode };
}

/** The error code to record when the whole send call threw (network, credentials) instead of answering per device. */
export function thrownErrorCode(err: unknown): string {
  const code = typeof err === 'object' && err !== null ? (err as { code?: unknown }).code : undefined;
  return typeof code === 'string' && code.length > 0 ? code : 'unknown';
}

/** Statuses that mean the person may not have seen the alert. */
export const PROBLEM_STATUSES: readonly PushDeliveryStatus[] = [
  PushDeliveryStatus.PARTIAL,
  PushDeliveryStatus.FAILED,
  PushDeliveryStatus.NO_DEVICE,
];

/** The alerts the dashboard counts: not delivered, nobody followed up, and recent enough to still matter. */
export const UNDELIVERED_WINDOW_DAYS = 14;

export function undeliveredWhere(now: Date): Prisma.PushDeliveryWhereInput {
  return {
    status: { in: [...PROBLEM_STATUSES] },
    handledAt: null,
    createdAt: { gte: new Date(now.getTime() - UNDELIVERED_WINDOW_DAYS * 24 * 60 * 60 * 1000) },
  };
}

const DEAD_TOKEN: ReadonlySet<string> = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);
const BUSY: ReadonlySet<string> = new Set([
  'messaging/message-rate-exceeded',
  'messaging/device-message-rate-exceeded',
  'messaging/topics-message-rate-exceeded',
  'messaging/quota-exceeded',
]);
const UNAVAILABLE: ReadonlySet<string> = new Set([
  'messaging/server-unavailable',
  'messaging/internal-error',
  'messaging/unavailable',
]);
const CREDENTIALS: ReadonlySet<string> = new Set([
  'messaging/third-party-auth-error',
  'messaging/mismatched-credential',
  'messaging/authentication-error',
  'messaging/sender-id-mismatch',
  'messaging/invalid-apns-credentials',
  'messaging/invalid-package-name',
]);

/** Why an alert did not arrive, in words the owner can read and act on. */
export function deliveryReason(status: PushDeliveryStatus, errorCode: string | null): string {
  if (status === PushDeliveryStatus.SENT) return 'Delivered';
  if (status === PushDeliveryStatus.NO_DEVICE) return 'Has not allowed notifications on the app yet';
  const some = status === PushDeliveryStatus.PARTIAL;
  if (errorCode && DEAD_TOKEN.has(errorCode)) {
    return some
      ? 'Reached some of their phones, but another no longer accepts alerts (app removed or notifications turned off)'
      : 'Their phone no longer accepts alerts (app removed or notifications turned off)';
  }
  if (errorCode && BUSY.has(errorCode)) {
    return 'Firebase slowed sending down for a moment. Try again in a few minutes';
  }
  if (errorCode && UNAVAILABLE.has(errorCode)) {
    return 'Firebase was briefly unavailable. Try again';
  }
  if (errorCode && CREDENTIALS.has(errorCode)) {
    return 'Apple or Google refused the alert because of how push is set up for the app. The developer needs to fix this';
  }
  return some
    ? 'Reached some of their phones, but not all. Firebase gave no clear reason'
    : 'Firebase could not deliver it and gave no clear reason';
}

export type RetryBlock = 'ALREADY_DELIVERED' | 'NOTIFICATION_GONE' | 'ALREADY_RETRIED' | 'RETRY_LIMIT';

/** At most this many extra sends per notification, so a person's phone is never spammed from the admin. */
export const MAX_RETRIES = 3;

export interface AttemptSummary {
  id: string;
  status: PushDeliveryStatus;
  createdAt: Date;
}

/**
 * Whether this delivery may be retried, and if not why. Only the latest attempt for a notification can be retried,
 * so two admins (or a double click) never send the same alert twice.
 * `attempts` is every delivery recorded for the same notification, this one included.
 */
export function retryBlock(
  delivery: { id: string; status: PushDeliveryStatus; notificationId: string | null; createdAt: Date },
  attempts: readonly AttemptSummary[],
): RetryBlock | null {
  if (delivery.status === PushDeliveryStatus.SENT) return 'ALREADY_DELIVERED';
  if (!delivery.notificationId) return 'NOTIFICATION_GONE';
  if (attempts.some((a) => a.status === PushDeliveryStatus.SENT)) return 'ALREADY_DELIVERED';
  if (attempts.some((a) => a.id !== delivery.id && a.createdAt.getTime() >= delivery.createdAt.getTime())) {
    return 'ALREADY_RETRIED';
  }
  if (attempts.length > MAX_RETRIES) return 'RETRY_LIMIT';
  return null;
}

export const RETRY_BLOCK_MESSAGE: Record<RetryBlock, string> = {
  ALREADY_DELIVERED: 'This alert already reached the person.',
  NOTIFICATION_GONE: 'The notification was deleted, so there is nothing to resend.',
  ALREADY_RETRIED: 'This alert was already retried. Use the latest attempt.',
  RETRY_LIMIT: 'This alert has been retried the most times allowed. Call the person instead.',
};
