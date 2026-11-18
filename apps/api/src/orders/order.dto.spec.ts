import { toOrderDto, type OrderWithRelations } from './order.dto.js';

describe('customer payment records', () => {
  const date = new Date('2026-11-14T09:00:00Z');
  const order = {
    id: 'order',
    status: 'DELIVERED',
    pickupDate: date,
    deliveryDate: date,
    pickupSlot: 'MORNING',
    deliverySlot: 'EVENING',
    items: [],
    paidPaise: 5000,
    totalPaise: 5000,
    payments: [
      {
        id: 'captured',
        status: 'CAPTURED',
        provider: 'RAZORPAY',
        amountPaise: 5000,
        razorpayPaymentId: 'pay_confirmed',
        raw: { secret: 'private' },
        collectedById: 'staff',
        updatedAt: date,
      },
      { id: 'failed', status: 'FAILED', provider: 'RAZORPAY', amountPaise: 5000, updatedAt: date },
    ],
  } as unknown as OrderWithRelations;

  it('returns only confirmed payment facts, without provider payloads or staff identity', () => {
    expect(toOrderDto(order, 'CUSTOMER').payments).toEqual([
      { id: 'captured', provider: 'RAZORPAY', amountPaise: 5000, reference: 'pay_confirmed', capturedAt: date },
    ]);
  });

  it('does not disclose customer payment references to the delivery partner', () => {
    expect(toOrderDto(order, 'DRIVER').payments).toBeUndefined();
  });
});

describe('reschedule fields', () => {
  const date = new Date('2026-11-14T09:00:00Z');
  const order = (over: Record<string, unknown>) =>
    ({ id: 'order', status: 'PENDING', pickupDate: date, deliveryDate: date, pickupSlot: 'MORNING', deliverySlot: 'EVENING', items: [], rescheduleCount: 0, ...over }) as unknown as OrderWithRelations;

  it('tells the customer whether the time can still be changed, and how many changes are left', () => {
    expect(toOrderDto(order({}), 'CUSTOMER')).toMatchObject({ rescheduleCount: 0, reschedulesRemaining: 2, canReschedule: true });
    expect(toOrderDto(order({ status: 'PICKUP_ASSIGNED', rescheduleCount: 1 }), 'CUSTOMER')).toMatchObject({ rescheduleCount: 1, reschedulesRemaining: 1, canReschedule: true });
    expect(toOrderDto(order({ rescheduleCount: 2 }), 'CUSTOMER')).toMatchObject({ reschedulesRemaining: 0, canReschedule: false });
  });

  it('is closed once the clothes are picked up or the order is over', () => {
    for (const status of ['PICKED_UP', 'PROCESSING', 'READY_FOR_DELIVERY', 'DELIVERY_ASSIGNED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED']) {
      expect(toOrderDto(order({ status }), 'CUSTOMER').canReschedule).toBe(false);
    }
  });

  it('is never offered to staff or partners, but they can see the count', () => {
    for (const viewer of ['ADMIN', 'DRIVER'] as const) {
      expect(toOrderDto(order({ rescheduleCount: 1 }), viewer)).toMatchObject({ canReschedule: false, rescheduleCount: 1 });
    }
  });
});
