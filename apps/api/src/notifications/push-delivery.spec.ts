import { PushDeliveryStatus } from '../generated/prisma/enums.js';
import {
  MAX_RETRIES,
  deliveryReason,
  deriveDelivery,
  retryBlock,
  thrownErrorCode,
  undeliveredWhere,
  type AttemptSummary,
} from './push-delivery.js';

const ok = { success: true };
const dead = { success: false, errorCode: 'messaging/registration-token-not-registered' };

describe('deriveDelivery', () => {
  it('is NO_DEVICE when the person has no registered device', () => {
    expect(deriveDelivery([])).toEqual({ status: 'NO_DEVICE', deviceCount: 0, failedCount: 0, errorCode: null });
  });

  it('is SENT when every device accepted it', () => {
    expect(deriveDelivery([ok, ok])).toEqual({ status: 'SENT', deviceCount: 2, failedCount: 0, errorCode: null });
  });

  it('is FAILED when every device refused it, keeping the first error code', () => {
    const out = deriveDelivery([dead, { success: false, errorCode: 'messaging/internal-error' }]);
    expect(out).toEqual({ status: 'FAILED', deviceCount: 2, failedCount: 2, errorCode: 'messaging/registration-token-not-registered' });
  });

  it('is PARTIAL when some devices accepted it and some refused', () => {
    expect(deriveDelivery([ok, dead, ok])).toEqual({
      status: 'PARTIAL',
      deviceCount: 3,
      failedCount: 1,
      errorCode: 'messaging/registration-token-not-registered',
    });
  });

  it('uses "unknown" when a failure carries no code', () => {
    expect(deriveDelivery([{ success: false }]).errorCode).toBe('unknown');
    expect(deriveDelivery([{ success: false, errorCode: null }]).errorCode).toBe('unknown');
  });

  it('always agrees with the push_deliveries_status_counts CHECK', () => {
    for (let devices = 0; devices <= 4; devices += 1) {
      for (let failed = 0; failed <= devices; failed += 1) {
        const results = Array.from({ length: devices }, (_, i) => (i < failed ? dead : ok));
        const { status, deviceCount, failedCount } = deriveDelivery(results);
        expect(failedCount).toBeLessThanOrEqual(deviceCount);
        if (status === 'SENT') expect(deviceCount > 0 && failedCount === 0).toBe(true);
        if (status === 'PARTIAL') expect(failedCount > 0 && failedCount < deviceCount).toBe(true);
        if (status === 'FAILED') expect(deviceCount > 0 && failedCount === deviceCount).toBe(true);
        if (status === 'NO_DEVICE') expect(deviceCount).toBe(0);
      }
    }
  });
});

describe('thrownErrorCode', () => {
  it('reads the Firebase error code when there is one', () => {
    expect(thrownErrorCode(Object.assign(new Error('x'), { code: 'messaging/server-unavailable' }))).toBe('messaging/server-unavailable');
  });

  it('falls back to "unknown"', () => {
    expect(thrownErrorCode(new Error('socket hang up'))).toBe('unknown');
    expect(thrownErrorCode('boom')).toBe('unknown');
    expect(thrownErrorCode(null)).toBe('unknown');
    expect(thrownErrorCode({ code: 42 })).toBe('unknown');
  });
});

describe('deliveryReason', () => {
  it('explains NO_DEVICE in plain words', () => {
    expect(deliveryReason(PushDeliveryStatus.NO_DEVICE, null)).toBe('Has not allowed notifications on the app yet');
  });

  it('explains a dead phone registration, whole or partial', () => {
    const code = 'messaging/registration-token-not-registered';
    expect(deliveryReason(PushDeliveryStatus.FAILED, code)).toMatch(/no longer accepts alerts/);
    expect(deliveryReason(PushDeliveryStatus.PARTIAL, code)).toMatch(/Reached some of their phones/);
  });

  it('tells staff when waiting and retrying is the fix', () => {
    expect(deliveryReason(PushDeliveryStatus.FAILED, 'messaging/quota-exceeded')).toMatch(/Try again/);
    expect(deliveryReason(PushDeliveryStatus.FAILED, 'messaging/server-unavailable')).toMatch(/Try again/);
  });

  it('flags push set-up problems for the developer', () => {
    expect(deliveryReason(PushDeliveryStatus.FAILED, 'messaging/third-party-auth-error')).toMatch(/developer/);
  });

  it('never shows a raw error code', () => {
    for (const code of ['messaging/whatever', 'unknown', null]) {
      expect(deliveryReason(PushDeliveryStatus.FAILED, code)).not.toMatch(/messaging\//);
    }
  });
});

describe('undeliveredWhere', () => {
  it('counts unhandled problems from the last 14 days only', () => {
    const now = new Date('2026-11-16T10:00:00.000Z');
    const where = undeliveredWhere(now);
    expect(where.status).toEqual({ in: ['PARTIAL', 'FAILED', 'NO_DEVICE'] });
    expect(where.handledAt).toBeNull();
    expect(where.createdAt).toEqual({ gte: new Date('2026-11-02T10:00:00.000Z') });
  });
});

describe('retryBlock', () => {
  const at = (minute: number) => new Date(Date.UTC(2026, 10, 16, 10, minute));
  const failed = { id: 'd1', status: PushDeliveryStatus.FAILED, notificationId: 'n1', createdAt: at(0) };
  const attempt = (id: string, status: PushDeliveryStatus, minute: number): AttemptSummary => ({ id, status, createdAt: at(minute) });

  it('allows the only attempt of a problem alert', () => {
    expect(retryBlock(failed, [attempt('d1', PushDeliveryStatus.FAILED, 0)])).toBeNull();
  });

  it('allows a partial delivery to be retried', () => {
    const partial = { ...failed, status: PushDeliveryStatus.PARTIAL };
    expect(retryBlock(partial, [attempt('d1', PushDeliveryStatus.PARTIAL, 0)])).toBeNull();
  });

  it('refuses an alert that already arrived', () => {
    expect(retryBlock({ ...failed, status: PushDeliveryStatus.SENT }, [attempt('d1', PushDeliveryStatus.SENT, 0)])).toBe('ALREADY_DELIVERED');
  });

  it('refuses when a later retry already got through', () => {
    expect(retryBlock(failed, [attempt('d1', PushDeliveryStatus.FAILED, 0), attempt('d2', PushDeliveryStatus.SENT, 5)])).toBe('ALREADY_DELIVERED');
  });

  it('refuses an attempt that has been replaced by a newer one', () => {
    expect(retryBlock(failed, [attempt('d1', PushDeliveryStatus.FAILED, 0), attempt('d2', PushDeliveryStatus.FAILED, 5)])).toBe('ALREADY_RETRIED');
  });

  it('refuses when the notification is gone', () => {
    expect(retryBlock({ ...failed, notificationId: null }, [])).toBe('NOTIFICATION_GONE');
  });

  it('stops after the retry limit', () => {
    const latest = { ...failed, id: `d${MAX_RETRIES + 1}`, createdAt: at(MAX_RETRIES * 5) };
    const all = Array.from({ length: MAX_RETRIES + 1 }, (_, i) => attempt(`d${i + 1}`, PushDeliveryStatus.FAILED, i * 5));
    expect(retryBlock(latest, all)).toBe('RETRY_LIMIT');
    expect(retryBlock(latest, all.slice(1))).toBeNull();
  });
});
