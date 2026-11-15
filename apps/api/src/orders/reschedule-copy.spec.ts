import type { OrderWindows } from '../events.js';
import { TimeSlot } from '../generated/prisma/enums.js';
import { partnerRescheduleCopy, staffRescheduleCopy } from './reschedule-copy.js';

const previous: OrderWindows = { pickupDate: '2026-10-03', pickupSlot: TimeSlot.EVENING, deliveryDate: '2026-10-05', deliverySlot: TimeSlot.MORNING };

describe('reschedule copy', () => {
  it('tells the released partner the order is no longer theirs', () => {
    expect(partnerRescheduleCopy('ID001046')).toEqual({
      title: 'Pickup time changed',
      body: 'The customer changed the pickup time for order ID001046. It is no longer assigned to you.',
    });
  });

  it('tells staff what moved and that the order is offered again when a partner was released', () => {
    const next = { ...previous, pickupDate: '2026-10-04', pickupSlot: TimeSlot.MORNING };
    expect(staffRescheduleCopy({ orderNumber: 'ID001046', previous, next, partnerReleased: true })).toEqual({
      title: 'Pickup time changed',
      body: 'Order ID001046: the customer moved the pickup from Sat 3 Oct 4–8 PM to Sun 4 Oct 7–11 AM. The assigned partner was released and the order is offered again.',
    });
  });

  it('does not mention a partner when none held the pickup, and names a delivery-only move', () => {
    const pickupOnly = { ...previous, pickupDate: '2026-10-04', pickupSlot: TimeSlot.MORNING };
    expect(staffRescheduleCopy({ orderNumber: 'ID001046', previous, next: pickupOnly, partnerReleased: false }).body).not.toContain('partner');
    const deliveryOnly = { ...previous, deliveryDate: '2026-10-06' };
    expect(staffRescheduleCopy({ orderNumber: 'ID001046', previous, next: deliveryOnly, partnerReleased: false })).toEqual({
      title: 'Delivery time changed',
      body: 'Order ID001046: the customer moved the delivery from Mon 5 Oct 7–11 AM to Tue 6 Oct 7–11 AM.',
    });
  });

  it('lists both moves in one sentence', () => {
    const both = { ...previous, pickupDate: '2026-10-04', deliveryDate: '2026-10-06' };
    expect(staffRescheduleCopy({ orderNumber: 'N1', previous, next: both, partnerReleased: false }).body).toBe(
      'Order N1: the customer moved the pickup from Sat 3 Oct 4–8 PM to Sun 4 Oct 4–8 PM and the delivery from Mon 5 Oct 7–11 AM to Tue 6 Oct 7–11 AM.',
    );
  });
});
