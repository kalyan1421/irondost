import { DiscountType, ItemUnit, PaymentStatus } from '../generated/prisma/enums.js';
import { computeQuote, discountFor, paymentStatusFor, type PricingPromotion } from './pricing.js';

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

  it('charges delivery unless the discounted subtotal reaches the free-delivery threshold', () => {
    const fees = { minOrderPaise: 0, deliveryFeePaise: 3000, freeDeliveryAbovePaise: 10_000 };
    expect(computeQuote([shirt], fees, null).deliveryFeePaise).toBe(3000);
    expect(computeQuote([shirt, saree], fees, null).deliveryFeePaise).toBe(0);
    // 11000 − 20% = 8800, below the threshold again
    expect(computeQuote([shirt, saree], fees, promo({ discountValue: 20 })).deliveryFeePaise).toBe(3000);
  });

  it('flags orders under the store minimum', () => {
    const q = computeQuote([{ ...shirt, quantity: 1 }], { ...noFees, minOrderPaise: 10_000 }, null);
    expect(q.minOrderShortfallPaise).toBe(8500);
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
});
