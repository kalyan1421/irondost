import type { OrderWindows } from '../events.js';
import { OrderStatus, TimeSlot } from '../generated/prisma/enums.js';
import {
  canReschedule,
  MAX_RESCHEDULES,
  rescheduleBlock,
  rescheduleError,
  rescheduleNote,
  rescheduleRequestHash,
  reschedulesRemaining,
  slotHoursText,
  windowsOf,
  windowText,
} from './reschedule.js';

const settings = { bookingCutoffMinutes: 60, maxAdvanceDays: 30, minTurnaroundHours: 20 };
// 2026-10-05 09:30 IST
const now = new Date('2026-10-05T04:00:00Z');

/** Booked for Tue 6 Oct morning, delivery Wed 7 Oct morning. */
const booked: OrderWindows = { pickupDate: '2026-10-06', pickupSlot: TimeSlot.MORNING, deliveryDate: '2026-10-07', deliverySlot: TimeSlot.MORNING };
const order = (over: Partial<{ status: OrderStatus; rescheduleCount: number }> = {}) => ({ status: OrderStatus.PENDING, rescheduleCount: 0, ...over });

describe('reschedule limits', () => {
  it('allows two moves per order', () => {
    expect(MAX_RESCHEDULES).toBe(2);
    expect([0, 1, 2, 3].map(reschedulesRemaining)).toEqual([2, 1, 0, 0]);
  });

  it('is open only before pickup', () => {
    const open = Object.values(OrderStatus).filter((s) => canReschedule(s, 0));
    expect(open).toEqual([OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED]);
  });

  it('closes once the moves are used up', () => {
    expect(rescheduleBlock(OrderStatus.PENDING, 1)).toBeNull();
    expect(rescheduleBlock(OrderStatus.PICKUP_ASSIGNED, 2)).toBe('RESCHEDULE_LIMIT');
  });

  it('judges the status before the limit', () => {
    expect(rescheduleBlock(OrderStatus.PICKED_UP, 2)).toBe('RESCHEDULE_NOT_ALLOWED');
    expect(rescheduleBlock(OrderStatus.CANCELLED, 0)).toBe('RESCHEDULE_NOT_ALLOWED');
  });
});

describe('rescheduleError', () => {
  it('accepts a later pickup with the delivery kept while it is still valid', () => {
    const next = { ...booked, pickupDate: '2026-10-06', pickupSlot: TimeSlot.NOON };
    // Pickup 11:00 + 20 h = 07:00 next day, so Wed 7 Oct morning still follows it.
    expect(rescheduleError(order(), booked, next, now, settings)).toBeNull();
  });

  it('refuses a kept delivery that no longer follows the new pickup by the minimum turnaround', () => {
    const next = { ...booked, pickupDate: '2026-10-06', pickupSlot: TimeSlot.EVENING };
    // Pickup 16:00 + 20 h = 12:00 next day: Wed morning (07:00) is too soon.
    expect(rescheduleError(order(), booked, next, now, settings)).toBe('DELIVERY_TOO_SOON');
    expect(rescheduleError(order(), booked, { ...next, deliverySlot: TimeSlot.EVENING }, now, settings)).toBeNull();
  });

  it('applies the booking rules to a new pickup', () => {
    expect(rescheduleError(order(), booked, { ...booked, pickupDate: '2026-10-04', deliveryDate: '2026-10-07' }, now, settings)).toBe('PICKUP_SLOT_CLOSED');
    // Today's morning slot ends 11:00; the cutoff is an hour earlier, and it is 09:30 now: still open.
    expect(rescheduleError(order(), booked, { ...booked, pickupDate: '2026-10-05', pickupSlot: TimeSlot.MORNING }, now, settings)).toBeNull();
    expect(
      rescheduleError(order(), booked, { ...booked, pickupDate: '2026-10-05', pickupSlot: TimeSlot.MORNING }, new Date('2026-10-05T04:45:00Z'), settings),
    ).toBe('PICKUP_SLOT_CLOSED');
    expect(rescheduleError(order(), booked, { ...booked, pickupDate: '2026-12-01', deliveryDate: '2026-12-02' }, now, settings)).toBe('PICKUP_TOO_FAR_AHEAD');
    expect(rescheduleError(order(), booked, { ...booked, pickupDate: '2026-02-30' }, now, settings)).toBe('INVALID_DATE');
  });

  it('says nothing changed rather than using up a move', () => {
    expect(rescheduleError(order(), booked, { ...booked }, now, settings)).toBe('RESCHEDULE_UNCHANGED');
  });

  it('does not re-check a pickup that is not moving, so only the delivery can change after its slot closed', () => {
    const closedPickup: OrderWindows = { pickupDate: '2026-10-05', pickupSlot: TimeSlot.MORNING, deliveryDate: '2026-10-06', deliverySlot: TimeSlot.MORNING };
    const late = new Date('2026-10-05T04:45:00Z'); // 10:15 IST, inside the cutoff
    expect(rescheduleError(order(), closedPickup, { ...closedPickup, deliverySlot: TimeSlot.EVENING }, late, settings)).toBeNull();
    // The delivery is still held to the turnaround.
    expect(rescheduleError(order(), closedPickup, { ...closedPickup, deliveryDate: '2026-10-05', deliverySlot: TimeSlot.EVENING }, late, settings)).toBe('DELIVERY_TOO_SOON');
  });

  it('reports state problems before schedule problems', () => {
    const impossible = { ...booked, pickupDate: '2026-02-30' };
    expect(rescheduleError(order({ status: OrderStatus.PICKED_UP }), booked, impossible, now, settings)).toBe('RESCHEDULE_NOT_ALLOWED');
    expect(rescheduleError(order({ rescheduleCount: 2 }), booked, impossible, now, settings)).toBe('RESCHEDULE_LIMIT');
    expect(rescheduleError(order({ rescheduleCount: 2 }), booked, { ...booked }, now, settings)).toBe('RESCHEDULE_LIMIT');
  });
});

describe('wording', () => {
  it('writes slot hours the way people say them', () => {
    expect([TimeSlot.MORNING, TimeSlot.NOON, TimeSlot.EVENING].map(slotHoursText)).toEqual(['7–11 AM', '11 AM–4 PM', '4–8 PM']);
  });

  it('writes a window with its weekday', () => {
    expect(windowText('2026-10-03', TimeSlot.EVENING)).toBe('Sat 3 Oct 4–8 PM');
    expect(windowText('2026-10-04', TimeSlot.MORNING)).toBe('Sun 4 Oct 7–11 AM');
  });

  it('records a pickup move, a delivery move or both in the order history', () => {
    const previous: OrderWindows = { pickupDate: '2026-10-03', pickupSlot: TimeSlot.EVENING, deliveryDate: '2026-10-05', deliverySlot: TimeSlot.MORNING };
    const pickupOnly = { ...previous, pickupDate: '2026-10-04', pickupSlot: TimeSlot.MORNING };
    expect(rescheduleNote(previous, pickupOnly)).toBe('Rescheduled by customer: pickup Sat 3 Oct 4–8 PM to Sun 4 Oct 7–11 AM');
    const deliveryOnly = { ...previous, deliveryDate: '2026-10-06', deliverySlot: TimeSlot.NOON };
    expect(rescheduleNote(previous, deliveryOnly)).toBe('Rescheduled by customer: delivery Mon 5 Oct 7–11 AM to Tue 6 Oct 11 AM–4 PM');
    expect(rescheduleNote(previous, { ...pickupOnly, ...deliveryOnly, pickupDate: '2026-10-04', pickupSlot: TimeSlot.MORNING })).toBe(
      'Rescheduled by customer: pickup Sat 3 Oct 4–8 PM to Sun 4 Oct 7–11 AM; delivery Mon 5 Oct 7–11 AM to Tue 6 Oct 11 AM–4 PM',
    );
  });
});

describe('request fingerprint and order times', () => {
  it('differs by order and by any time, and repeats for the same request', () => {
    const a = rescheduleRequestHash('o1', booked);
    expect(rescheduleRequestHash('o1', { ...booked })).toBe(a);
    expect(rescheduleRequestHash('o2', booked)).not.toBe(a);
    expect(rescheduleRequestHash('o1', { ...booked, pickupSlot: TimeSlot.NOON })).not.toBe(a);
    expect(rescheduleRequestHash('o1', { ...booked, deliveryDate: '2026-10-08' })).not.toBe(a);
  });

  it('reads the times from an order row', () => {
    expect(
      windowsOf({ pickupDate: new Date('2026-10-06T00:00:00Z'), pickupSlot: TimeSlot.MORNING, deliveryDate: new Date('2026-10-07T00:00:00Z'), deliverySlot: TimeSlot.MORNING }),
    ).toEqual(booked);
  });
});
