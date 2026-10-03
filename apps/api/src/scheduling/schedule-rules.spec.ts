import { TimeSlot } from '../generated/prisma/enums.js';
import { checkDelivery, checkPickup, deliveryOptions, pickupOptions } from './schedule-rules.js';

const settings = { bookingCutoffMinutes: 60, maxAdvanceDays: 30, minTurnaroundHours: 20 };
const at = (iso: string) => new Date(iso);

describe('checkPickup', () => {
  // 2026-10-05 09:30 IST = 04:00 UTC
  const now = at('2026-10-05T04:00:00Z');

  it('allows a slot with more than the cutoff left', () => {
    // MORNING ends 11:00 IST; cutoff 10:00 IST; now is 09:30 IST
    expect(checkPickup('2026-10-05', TimeSlot.MORNING, now, settings)).toBeNull();
  });

  it('closes a slot once inside the cutoff', () => {
    const tenFifteen = at('2026-10-05T04:45:00Z'); // 10:15 IST
    expect(checkPickup('2026-10-05', TimeSlot.MORNING, tenFifteen, settings)).toBe('PICKUP_SLOT_CLOSED');
  });

  it('rejects past dates', () => {
    expect(checkPickup('2026-10-04', TimeSlot.EVENING, now, settings)).toBe('PICKUP_SLOT_CLOSED');
  });

  it('limits how far ahead a pickup can be booked', () => {
    expect(checkPickup('2026-11-04', TimeSlot.MORNING, now, settings)).toBeNull(); // 30 days
    expect(checkPickup('2026-11-05', TimeSlot.MORNING, now, settings)).toBe('PICKUP_TOO_FAR_AHEAD');
  });

  it('rejects impossible dates', () => {
    expect(checkPickup('2026-02-30', TimeSlot.MORNING, now, settings)).toBe('INVALID_DATE');
  });
});

describe('checkDelivery', () => {
  it('requires 20 hours from pickup slot start to delivery slot start', () => {
    // Pickup MORNING 07:00 → earliest delivery start is next day 03:00, so next-day MORNING (07:00) works.
    expect(checkDelivery('2026-10-05', TimeSlot.MORNING, '2026-10-06', TimeSlot.MORNING, settings)).toBeNull();
    // Same-day EVENING (16:00) is only 9 hours later.
    expect(checkDelivery('2026-10-05', TimeSlot.MORNING, '2026-10-05', TimeSlot.EVENING, settings)).toBe('DELIVERY_TOO_SOON');
    // Pickup EVENING 16:00 → earliest 12:00 next day: NOON (11:00) is too soon, EVENING is fine.
    expect(checkDelivery('2026-10-05', TimeSlot.EVENING, '2026-10-06', TimeSlot.NOON, settings)).toBe('DELIVERY_TOO_SOON');
    expect(checkDelivery('2026-10-05', TimeSlot.EVENING, '2026-10-06', TimeSlot.EVENING, settings)).toBeNull();
  });

  it('rejects delivery too long after pickup', () => {
    expect(checkDelivery('2026-10-05', TimeSlot.MORNING, '2026-11-05', TimeSlot.MORNING, settings)).toBe('DELIVERY_TOO_FAR_AHEAD');
  });
});

describe('slot listings', () => {
  it('lists three pickup slots per day and marks closed ones', () => {
    const slots = pickupOptions(at('2026-10-05T06:00:00Z'), settings, 2); // 11:30 IST
    expect(slots).toHaveLength(6);
    expect(slots.filter((s) => s.date === '2026-10-05').map((s) => s.available)).toEqual([false, true, true]);
    expect(slots[0].label).toBe('07:00–11:00');
  });

  it('lists delivery slots starting on the pickup date', () => {
    const slots = deliveryOptions('2026-10-05', TimeSlot.MORNING, settings, 2);
    expect(slots.filter((s) => s.available).map((s) => `${s.date} ${s.slot}`)).toEqual([
      '2026-10-06 MORNING',
      '2026-10-06 NOON',
      '2026-10-06 EVENING',
    ]);
  });
});
