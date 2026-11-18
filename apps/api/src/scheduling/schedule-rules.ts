import { TimeSlot } from '../generated/prisma/enums.js';
import {
  addDays,
  daysBetween,
  isIsoDate,
  istDate,
  SLOT_HOURS,
  SLOT_ORDER,
  slotEnd,
  slotStart,
} from '../common/time.js';

export interface ScheduleSettings {
  bookingCutoffMinutes: number;
  maxAdvanceDays: number;
  minTurnaroundHours: number;
}

/** Why a window that is otherwise open cannot be booked. A closed or too-far window has no reason: `available` says it all. */
export const SLOT_UNAVAILABLE_REASONS = ['FULL'] as const;
export type SlotUnavailableReason = (typeof SLOT_UNAVAILABLE_REASONS)[number];

export interface SlotOption {
  date: string;
  slot: TimeSlot;
  /** Human label in IST, e.g. "07:00–11:00" */
  label: string;
  startsAt: Date;
  endsAt: Date;
  available: boolean;
  /** `FULL` when the window is open but has no place left. Null otherwise. */
  reason: SlotUnavailableReason | null;
}

/** A pickup window as one key, "2026-10-05|MORNING". */
export const windowKey = (date: string, slot: TimeSlot): string => `${date}|${slot}`;

export type ScheduleError =
  | 'INVALID_DATE'
  | 'PICKUP_SLOT_CLOSED'
  | 'PICKUP_TOO_FAR_AHEAD'
  | 'DELIVERY_TOO_SOON'
  | 'DELIVERY_TOO_FAR_AHEAD';

const pad = (n: number) => String(n).padStart(2, '0');

export function slotLabel(slot: TimeSlot): string {
  const [from, to] = SLOT_HOURS[slot];
  return `${pad(from)}:00–${pad(to)}:00`;
}

/** A pickup slot can be booked until `bookingCutoffMinutes` before it ends, up to `maxAdvanceDays` ahead. */
export function checkPickup(
  date: string,
  slot: TimeSlot,
  now: Date,
  s: ScheduleSettings,
): ScheduleError | null {
  if (!isIsoDate(date)) return 'INVALID_DATE';
  if (daysBetween(istDate(now), date) > s.maxAdvanceDays) return 'PICKUP_TOO_FAR_AHEAD';
  const cutoff = slotEnd(date, slot).getTime() - s.bookingCutoffMinutes * 60_000;
  if (now.getTime() >= cutoff) return 'PICKUP_SLOT_CLOSED';
  return null;
}

/** Delivery must start at least `minTurnaroundHours` after the pickup slot starts. */
export function checkDelivery(
  pickupDate: string,
  pickupSlot: TimeSlot,
  deliveryDate: string,
  deliverySlot: TimeSlot,
  s: ScheduleSettings,
): ScheduleError | null {
  if (!isIsoDate(pickupDate) || !isIsoDate(deliveryDate)) return 'INVALID_DATE';
  if (daysBetween(pickupDate, deliveryDate) > s.maxAdvanceDays) return 'DELIVERY_TOO_FAR_AHEAD';
  const earliest = slotStart(pickupDate, pickupSlot).getTime() + s.minTurnaroundHours * 3_600_000;
  if (slotStart(deliveryDate, deliverySlot).getTime() < earliest) return 'DELIVERY_TOO_SOON';
  return null;
}

/** Pickup slots for the next `days` days, starting today (IST). `fullWindows` are the open windows with no place left. */
export function pickupOptions(
  now: Date,
  s: ScheduleSettings,
  days: number,
  fullWindows: ReadonlySet<string> = new Set(),
): SlotOption[] {
  const today = istDate(now);
  const out: SlotOption[] = [];
  for (let d = 0; d < Math.min(days, s.maxAdvanceDays + 1); d++) {
    const date = addDays(today, d);
    for (const slot of SLOT_ORDER) {
      const open = checkPickup(date, slot, now, s) === null;
      // Only a window that could otherwise be booked is called full: a closed one is simply closed.
      const full = open && fullWindows.has(windowKey(date, slot));
      out.push({
        date,
        slot,
        label: slotLabel(slot),
        startsAt: slotStart(date, slot),
        endsAt: slotEnd(date, slot),
        available: open && !full,
        reason: full ? 'FULL' : null,
      });
    }
  }
  return out;
}

/** Delivery slots for `days` days starting on the pickup date. */
export function deliveryOptions(
  pickupDate: string,
  pickupSlot: TimeSlot,
  s: ScheduleSettings,
  days: number,
): SlotOption[] {
  const out: SlotOption[] = [];
  for (let d = 0; d < days; d++) {
    const date = addDays(pickupDate, d);
    for (const slot of SLOT_ORDER) {
      out.push({
        date,
        slot,
        label: slotLabel(slot),
        startsAt: slotStart(date, slot),
        endsAt: slotEnd(date, slot),
        available: checkDelivery(pickupDate, pickupSlot, date, slot, s) === null,
        reason: null,
      });
    }
  }
  return out;
}

export const SCHEDULE_ERROR_MESSAGES: Record<ScheduleError, string> = {
  INVALID_DATE: 'Dates must be real calendar dates in YYYY-MM-DD format',
  PICKUP_SLOT_CLOSED: 'This pickup slot is no longer available',
  PICKUP_TOO_FAR_AHEAD: 'Pickup is too far in the future',
  DELIVERY_TOO_SOON: 'Delivery is too soon after pickup',
  DELIVERY_TOO_FAR_AHEAD: 'Delivery is too far after pickup',
};
