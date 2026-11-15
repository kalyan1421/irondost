import { keptTravelPaise, refundablePaise } from './refund-due.js';

const order = (over: Partial<Parameters<typeof refundablePaise>[0]> = {}) => ({
  paidPaise: 22_000,
  refundedPaise: 0,
  deliveryFeePaise: 3000,
  travelChargeKept: false,
  ...over,
});

describe('keptTravelPaise', () => {
  it('keeps nothing unless staff kept the charge', () => {
    expect(keptTravelPaise(order())).toBe(0);
  });

  it('keeps the order\'s travel charge', () => {
    expect(keptTravelPaise(order({ travelChargeKept: true }))).toBe(3000);
  });

  it('never keeps more than was paid', () => {
    expect(keptTravelPaise(order({ travelChargeKept: true, paidPaise: 1000 }))).toBe(1000);
    expect(keptTravelPaise(order({ travelChargeKept: true, paidPaise: 0 }))).toBe(0);
  });
});

describe('refundablePaise', () => {
  it('is everything paid and not yet refunded, the charge included, by default', () => {
    expect(refundablePaise(order())).toBe(22_000);
    expect(refundablePaise(order({ refundedPaise: 5000 }))).toBe(17_000);
  });

  it('is reduced by the kept travel charge', () => {
    expect(refundablePaise(order({ travelChargeKept: true }))).toBe(19_000);
    expect(refundablePaise(order({ travelChargeKept: true, refundedPaise: 19_000 }))).toBe(0);
  });

  it('is zero when only the kept charge was paid, and never negative', () => {
    expect(refundablePaise(order({ travelChargeKept: true, paidPaise: 3000 }))).toBe(0);
    expect(refundablePaise(order({ travelChargeKept: true, paidPaise: 1000 }))).toBe(0);
    expect(refundablePaise(order({ travelChargeKept: true, refundedPaise: 22_000 }))).toBe(0);
  });
});
