import { DiscountType, ItemUnit, PaymentStatus } from '../generated/prisma/enums.js';
import { computeQuote, discountFor, orderTravelRule, paymentStatusFor, travelCharge, type PricingPromotion } from './pricing.js';

const shirt = { catalogItemId: 'a', name: 'Shirt', unit: ItemUnit.PIECE, unitPricePaise: 1500, quantity: 4 };
const saree = { catalogItemId: 'b', name: 'Saree', unit: ItemUnit.PIECE, unitPricePaise: 5000, quantity: 1 };
const noFees = { minOrderPaise: 0, deliveryFeePaise: 0, freeDeliveryAbovePaise: null };

const promo = (over: Partial<PricingPromotion>): PricingPromotion => ({
  id: 'p',
  code: 'TEST',
  discountType: DiscountType.PERCENT,
  discountValue: 10,
  minOrderPaise: 0,
  maxDiscountPaise: null,
  ...over,
});

describe('computeQuote', () => {
  it('adds up line totals in paise', () => {
    const q = computeQuote([shirt, saree], noFees, null);
    expect(q.lines.map((l) => l.lineTotalPaise)).toEqual([6000, 5000]);
    expect(q.subtotalPaise).toBe(11000);
    expect(q.totalPaise).toBe(11000);
  });

  it('applies a percentage discount, rounding down to the paisa', () => {
    const q = computeQuote([{ ...shirt, quantity: 1, unitPricePaise: 999 }], noFees, promo({ discountValue: 15 }));
    expect(q.discountPaise).toBe(149); // 149.85 → 149
    expect(q.totalPaise).toBe(850);
  });

  it('caps percentage discounts at maxDiscountPaise', () => {
    const q = computeQuote([shirt, saree], noFees, promo({ discountValue: 50, maxDiscountPaise: 2000 }));
    expect(q.discountPaise).toBe(2000);
  });

  it('never discounts more than the subtotal', () => {
    const q = computeQuote([{ ...shirt, quantity: 1 }], noFees, promo({ discountType: DiscountType.FLAT, discountValue: 10_000 }));
    expect(q.discountPaise).toBe(1500);
    expect(q.totalPaise).toBe(0);
  });

  it('reports a promo minimum shortfall instead of applying it', () => {
    const q = computeQuote([{ ...shirt, quantity: 1 }], noFees, promo({ minOrderPaise: 2000 }));
    expect(q.appliedPromotion).toBeNull();
    expect(q.discountPaise).toBe(0);
    expect(q.promoShortfallPaise).toBe(500);
  });

  it('charges the flat travel charge unless the items total reaches the free-from amount', () => {
    const fees = { minOrderPaise: 0, deliveryFeePaise: 3000, freeDeliveryAbovePaise: 10_000 };
    expect(computeQuote([shirt], fees, null).deliveryFeePaise).toBe(3000); // 6000
    expect(computeQuote([shirt, saree], fees, null).deliveryFeePaise).toBe(0); // 11000
    expect(computeQuote([shirt, saree], fees, null).totalPaise).toBe(11000);
    expect(computeQuote([shirt], fees, null).totalPaise).toBe(9000);
  });

  describe('the Rs 200 rule (travel charge Rs 30, free from Rs 200)', () => {
    const rule = { minOrderPaise: 0, deliveryFeePaise: 3000, freeDeliveryAbovePaise: 20_000 };
    const worth = (paise: number) => [{ ...shirt, unitPricePaise: paise, quantity: 1 }];

    it('is free at exactly Rs 200 and charged at Rs 199.99', () => {
      expect(computeQuote(worth(20_000), rule, null)).toMatchObject({ deliveryFeePaise: 0, totalPaise: 20_000, freeTravelShortfallPaise: null });
      expect(computeQuote(worth(19_999), rule, null)).toMatchObject({ deliveryFeePaise: 3000, totalPaise: 22_999, freeTravelShortfallPaise: 1 });
    });

    it('charges a Rs 190 order and says how much more makes travel free', () => {
      expect(computeQuote(worth(19_000), rule, null)).toMatchObject({ deliveryFeePaise: 3000, totalPaise: 22_000, freeTravelShortfallPaise: 1000 });
    });

    it('counts the items total BEFORE a coupon: Rs 210 stays free when the coupon takes it under Rs 200', () => {
      const q = computeQuote(worth(21_000), rule, promo({ discountValue: 10 })); // 21000 - 2100 = 18900 after the coupon
      expect(q.subtotalPaise).toBe(21_000);
      expect(q.discountPaise).toBe(2100);
      expect(q.deliveryFeePaise).toBe(0);
      expect(q.freeTravelShortfallPaise).toBeNull();
      expect(q.totalPaise).toBe(18_900);
    });

    it('still charges a Rs 190 order with a coupon, and the shortfall ignores the coupon', () => {
      const q = computeQuote(worth(19_000), rule, promo({ discountValue: 10 })); // 19000 - 1900 = 17100, plus 3000
      expect(q.deliveryFeePaise).toBe(3000);
      expect(q.freeTravelShortfallPaise).toBe(1000);
      expect(q.totalPaise).toBe(20_100);
    });

    it('does not let a coupon minimum change the travel rule', () => {
      const q = computeQuote(worth(19_000), rule, promo({ minOrderPaise: 25_000 }));
      expect(q.appliedPromotion).toBeNull();
      expect(q.promoShortfallPaise).toBe(6000);
      expect(q.freeTravelShortfallPaise).toBe(1000);
    });

    it('has no shortfall when there is no threshold, or when travel costs nothing anyway', () => {
      expect(computeQuote(worth(5000), { ...rule, freeDeliveryAbovePaise: null }, null)).toMatchObject({ deliveryFeePaise: 3000, freeTravelShortfallPaise: null });
      expect(computeQuote(worth(5000), { ...rule, deliveryFeePaise: 0 }, null)).toMatchObject({ deliveryFeePaise: 0, freeTravelShortfallPaise: null });
    });

    it('keeps the hard minimum separate from the travel charge', () => {
      const q = computeQuote(worth(19_000), { ...rule, minOrderPaise: 20_000 }, null);
      expect(q.minOrderShortfallPaise).toBe(1000);
      expect(q.deliveryFeePaise).toBe(3000);
    });
  });

  it('flags orders under the store minimum', () => {
    const q = computeQuote([{ ...shirt, quantity: 1 }], { ...noFees, minOrderPaise: 10_000 }, null);
    expect(q.minOrderShortfallPaise).toBe(8500);
  });
});

describe('travelCharge', () => {
  it('re-checks a total against a rule, in both directions', () => {
    const rule = { chargePaise: 3000, freeFromPaise: 20_000 };
    expect(travelCharge(25_000, rule)).toEqual({ deliveryFeePaise: 0, freeTravelShortfallPaise: null });
    expect(travelCharge(15_000, rule)).toEqual({ deliveryFeePaise: 3000, freeTravelShortfallPaise: 5000 });
  });
});

describe('orderTravelRule', () => {
  it('uses the rule frozen on the order, not the current settings', () => {
    expect(orderTravelRule({ deliveryFeePaise: 0, travelChargePaiseRule: 3000, travelFreeFromPaiseRule: 20_000 })).toEqual({ chargePaise: 3000, freeFromPaise: 20_000 });
  });

  it('keeps a frozen charge of zero and a missing threshold', () => {
    expect(orderTravelRule({ deliveryFeePaise: 0, travelChargePaiseRule: 0, travelFreeFromPaiseRule: null })).toEqual({ chargePaise: 0, freeFromPaise: null });
  });

  it('lets an order booked before the rule keep its stored fee with no threshold', () => {
    expect(orderTravelRule({ deliveryFeePaise: 4000, travelChargePaiseRule: null, travelFreeFromPaiseRule: null })).toEqual({ chargePaise: 4000, freeFromPaise: null });
    expect(orderTravelRule({ deliveryFeePaise: 0, travelChargePaiseRule: null, travelFreeFromPaiseRule: null })).toEqual({ chargePaise: 0, freeFromPaise: null });
  });
});

describe('discountFor', () => {
  it('handles flat discounts', () => {
    expect(discountFor(5000, promo({ discountType: DiscountType.FLAT, discountValue: 1000 }))).toBe(1000);
  });
});

describe('paymentStatusFor', () => {
  it.each([
    [1000, 0, PaymentStatus.UNPAID],
    [1000, 400, PaymentStatus.PARTIALLY_PAID],
    [1000, 1000, PaymentStatus.PAID],
    [1000, 1200, PaymentStatus.PAID],
    [0, 0, PaymentStatus.PAID],
  ])('total %i, paid %i → %s', (total, paid, expected) => {
    expect(paymentStatusFor(total, paid)).toBe(expected);
  });

  it.each([
    [1000, 1000, 400, PaymentStatus.PAID], // part refunded: still paid for
    [1000, 400, 100, PaymentStatus.PARTIALLY_PAID],
    [1000, 1000, 1000, PaymentStatus.REFUNDED],
    [1000, 400, 400, PaymentStatus.REFUNDED], // cancelled after a part payment, all of it returned
    [0, 0, 0, PaymentStatus.PAID], // nothing paid means nothing to refund
  ])('total %i, paid %i, refunded %i → %s', (total, paid, refunded, expected) => {
    expect(paymentStatusFor(total, paid, refunded)).toBe(expected);
  });

  it.each([
    [22_000, 22_000, 0, 3000, PaymentStatus.PAID], // cancelled, travel charge kept, refund not made yet
    [22_000, 22_000, 19_000, 3000, PaymentStatus.REFUNDED], // everything but the kept charge went back
    [22_000, 22_000, 10_000, 3000, PaymentStatus.PAID], // part of the refund made
    [22_000, 3000, 0, 3000, PaymentStatus.PARTIALLY_PAID], // paid only the charge, and it is kept: nothing to refund
    [22_000, 22_000, 22_000, 3000, PaymentStatus.REFUNDED], // never more than paid, whatever was kept
  ])('total %i, paid %i, refunded %i, kept %i → %s', (total, paid, refunded, kept, expected) => {
    expect(paymentStatusFor(total, paid, refunded, kept)).toBe(expected);
  });
});
