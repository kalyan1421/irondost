import { onlineRefundable, splitRefund, type RefundablePayment } from './refund-split.js';

const pay = (id: string, amountPaise: number, refundedPaise: number, day: number): RefundablePayment => ({
  id,
  razorpayPaymentId: `pay_${id}`,
  amountPaise,
  refundedPaise,
  createdAt: new Date(Date.UTC(2026, 9, day)),
});

describe('splitRefund', () => {
  const first = pay('a', 4000, 0, 1);
  const second = pay('b', 2500, 0, 2);

  it('takes everything from the newest payment when it covers the amount', () => {
    expect(splitRefund(1000, [first, second])).toEqual([{ paymentId: 'b', razorpayPaymentId: 'pay_b', amountPaise: 1000 }]);
  });

  it('spills over to older payments, newest first, whatever order they arrive in', () => {
    expect(splitRefund(5000, [first, second])).toEqual([
      { paymentId: 'b', razorpayPaymentId: 'pay_b', amountPaise: 2500 },
      { paymentId: 'a', razorpayPaymentId: 'pay_a', amountPaise: 2500 },
    ]);
    expect(splitRefund(5000, [second, first])).toEqual(splitRefund(5000, [first, second]));
  });

  it('skips what earlier refunds already returned', () => {
    const partly = pay('b', 2500, 2000, 2);
    const done = pay('c', 1000, 1000, 3);
    expect(splitRefund(1500, [first, partly, done])).toEqual([
      { paymentId: 'b', razorpayPaymentId: 'pay_b', amountPaise: 500 },
      { paymentId: 'a', razorpayPaymentId: 'pay_a', amountPaise: 1000 },
    ]);
  });

  it('refunds every payment in full when asked for the lot', () => {
    const parts = splitRefund(6500, [first, second])!;
    expect(parts.map((p) => p.amountPaise)).toEqual([2500, 4000]);
  });

  it('returns null when the payments cannot cover the amount', () => {
    expect(splitRefund(6501, [first, second])).toBeNull();
    expect(splitRefund(1, [])).toBeNull();
    expect(splitRefund(100, [pay('x', 500, 500, 1)])).toBeNull();
  });

  it('refuses amounts that are not positive whole paise', () => {
    expect(splitRefund(0, [first])).toBeNull();
    expect(splitRefund(-5, [first])).toBeNull();
    expect(splitRefund(10.5, [first])).toBeNull();
  });
});

describe('onlineRefundable', () => {
  it('adds up what is left on each payment', () => {
    expect(onlineRefundable([pay('a', 4000, 1000, 1), pay('b', 2500, 0, 2)])).toBe(5500);
    expect(onlineRefundable([])).toBe(0);
  });
});
