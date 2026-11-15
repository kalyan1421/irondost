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
