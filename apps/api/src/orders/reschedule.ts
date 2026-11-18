import { createHash } from 'node:crypto';
import { fromDbDate, SLOT_HOURS } from '../common/time.js';
import type { OrderWindows } from '../events.js';
import { OrderStatus, type TimeSlot } from '../generated/prisma/enums.js';
import { checkDelivery, checkPickup, SCHEDULE_ERROR_MESSAGES, type ScheduleError, type ScheduleSettings } from '../scheduling/schedule-rules.js';

/** A customer may move an order's pickup and delivery times this many times. The database CHECK allows up to 10. */
export const MAX_RESCHEDULES = 2;

/** Until the clothes are picked up, the same point up to which a customer can cancel. */
export const RESCHEDULABLE_STATUSES: readonly OrderStatus[] = [OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED];

export type RescheduleBlock = 'RESCHEDULE_NOT_ALLOWED' | 'RESCHEDULE_LIMIT';
export type RescheduleError = RescheduleBlock | 'RESCHEDULE_UNCHANGED' | ScheduleError;

export const RESCHEDULE_ERROR_MESSAGES: Record<RescheduleError, string> = {
  ...SCHEDULE_ERROR_MESSAGES,
  RESCHEDULE_NOT_ALLOWED: 'The time can only be changed before your clothes are picked up',
  RESCHEDULE_LIMIT: `You have already changed the time ${MAX_RESCHEDULES} times for this order. Call us if you need another change.`,
  RESCHEDULE_UNCHANGED: 'That is already the time booked for this order',
};

/** How many more times the customer may move this order. */
export function reschedulesRemaining(rescheduleCount: number): number {
  return Math.max(0, MAX_RESCHEDULES - rescheduleCount);
}

/** Why an order cannot be moved right now, or null when it can. The status is judged first. */
export function rescheduleBlock(status: OrderStatus, rescheduleCount: number): RescheduleBlock | null {
  if (!RESCHEDULABLE_STATUSES.includes(status)) return 'RESCHEDULE_NOT_ALLOWED';
  if (reschedulesRemaining(rescheduleCount) === 0) return 'RESCHEDULE_LIMIT';
  return null;
}

export function canReschedule(status: OrderStatus, rescheduleCount: number): boolean {
  return rescheduleBlock(status, rescheduleCount) === null;
}

/** The booked times of an order row. */
export function windowsOf(o: { pickupDate: Date; pickupSlot: TimeSlot; deliveryDate: Date; deliverySlot: TimeSlot }): OrderWindows {
  return { pickupDate: fromDbDate(o.pickupDate), pickupSlot: o.pickupSlot, deliveryDate: fromDbDate(o.deliveryDate), deliverySlot: o.deliverySlot };
}

export const pickupChanged = (a: OrderWindows, b: OrderWindows): boolean => a.pickupDate !== b.pickupDate || a.pickupSlot !== b.pickupSlot;
export const deliveryChanged = (a: OrderWindows, b: OrderWindows): boolean => a.deliveryDate !== b.deliveryDate || a.deliverySlot !== b.deliverySlot;

/**
 * Everything that decides whether the move is allowed, in the order the customer should hear about it: the order's
 * state first, then whether anything changes, then the same schedule rules as booking. A pickup that is not being
 * moved is not checked again (its slot may already be closed while the customer only changes the delivery); the
 * delivery is always checked against the pickup it will follow, so it is kept only if it is still valid.
 */
export function rescheduleError(
  order: { status: OrderStatus; rescheduleCount: number },
  current: OrderWindows,
  next: OrderWindows,
  now: Date,
  settings: ScheduleSettings,
): RescheduleError | null {
  const block = rescheduleBlock(order.status, order.rescheduleCount);
  if (block) return block;
  const movesPickup = pickupChanged(current, next);
  if (!movesPickup && !deliveryChanged(current, next)) return 'RESCHEDULE_UNCHANGED';
  return (
    (movesPickup ? checkPickup(next.pickupDate, next.pickupSlot, now, settings) : null) ??
    checkDelivery(next.pickupDate, next.pickupSlot, next.deliveryDate, next.deliverySlot, settings)
  );
}

/** Fingerprint of a reschedule request, so a reused Idempotency-Key with different times is refused. */
export function rescheduleRequestHash(orderId: string, next: OrderWindows): string {
  return createHash('sha256').update(JSON.stringify([orderId, next.pickupDate, next.pickupSlot, next.deliveryDate, next.deliverySlot])).digest('hex');
}

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const;
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'] as const;
const hour12 = (h: number) => (h % 12 === 0 ? 12 : h % 12);
const meridiem = (h: number) => (h < 12 ? 'AM' : 'PM');

/** A slot's hours as people say them: "7–11 AM", "11 AM–4 PM", "4–8 PM". */
export function slotHoursText(slot: TimeSlot): string {
  const [from, to] = SLOT_HOURS[slot];
  return meridiem(from) === meridiem(to)
    ? `${hour12(from)}–${hour12(to)} ${meridiem(to)}`
    : `${hour12(from)} ${meridiem(from)}–${hour12(to)} ${meridiem(to)}`;
}

/** "Sat 3 Oct 4–8 PM" for an IST date (YYYY-MM-DD) and slot. */
export function windowText(date: string, slot: TimeSlot): string {
  const d = new Date(`${date}T00:00:00.000Z`);
  return `${WEEKDAYS[d.getUTCDay()]} ${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]} ${slotHoursText(slot)}`;
}

/** The order-history line: "Rescheduled by customer: pickup Sat 3 Oct 4–8 PM to Sun 4 Oct 7–11 AM". */
export function rescheduleNote(previous: OrderWindows, next: OrderWindows): string {
  const parts: string[] = [];
  if (pickupChanged(previous, next)) {
    parts.push(`pickup ${windowText(previous.pickupDate, previous.pickupSlot)} to ${windowText(next.pickupDate, next.pickupSlot)}`);
  }
  if (deliveryChanged(previous, next)) {
    parts.push(`delivery ${windowText(previous.deliveryDate, previous.deliverySlot)} to ${windowText(next.deliveryDate, next.deliverySlot)}`);
  }
  return `Rescheduled by customer: ${parts.join('; ')}`;
}
