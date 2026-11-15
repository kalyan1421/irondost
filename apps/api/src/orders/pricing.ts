import { DiscountType, ItemUnit, PaymentStatus } from '../generated/prisma/enums.js';

export interface PricingLine {
  catalogItemId: string;
  name: string;
  unit: ItemUnit;
  unitPricePaise: number;
  quantity: number;
}

export interface PricingPromotion {
  id: string;
  code: string;
  discountType: DiscountType;
  discountValue: number;
  minOrderPaise: number;
  maxDiscountPaise: number | null;
}

/**
 * `deliveryFeePaise` is the flat travel charge; `freeDeliveryAbovePaise` is the items total (before any coupon) from
 * which travel is free, or null when there is no such threshold. Both are stored under these names in the settings.
 */
export interface PricingSettings {
  minOrderPaise: number;
  deliveryFeePaise: number;
  freeDeliveryAbovePaise: number | null;
}

/** The travel charge rule an order is priced under: today's settings at booking, then frozen on the order. */
export interface TravelRule {
  chargePaise: number;
  freeFromPaise: number | null;
}

export interface Quote {
  lines: (PricingLine & { lineTotalPaise: number })[];
  subtotalPaise: number;
  discountPaise: number;
  /** The flat travel charge on this basket: the rule's charge, or 0 once the items total reaches the free-from amount. */
  deliveryFeePaise: number;
  totalPaise: number;
  /** How much more of clothes (items total, before any coupon) makes travel free. Null when already free or there is no threshold. */
  freeTravelShortfallPaise: number | null;
  /** The promotion actually applied (null if none, or if it did not qualify). */
  appliedPromotion: PricingPromotion | null;
  /** Set when a promotion was supplied but the order does not meet its minimum. */
  promoShortfallPaise: number | null;
  /** Set when the subtotal is below the store minimum. */
  minOrderShortfallPaise: number | null;
}

export function discountFor(subtotalPaise: number, p: PricingPromotion): number {
  const raw =
    p.discountType === DiscountType.PERCENT
      ? Math.floor((subtotalPaise * p.discountValue) / 100)
      : p.discountValue;
  const capped = p.maxDiscountPaise == null ? raw : Math.min(raw, p.maxDiscountPaise);
  return Math.min(capped, subtotalPaise);
}

/** The travel charge for an items total (before any coupon) under a rule, and how much more makes it free. */
export function travelCharge(itemsTotalPaise: number, rule: TravelRule): { deliveryFeePaise: number; freeTravelShortfallPaise: number | null } {
  const free = rule.freeFromPaise != null && itemsTotalPaise >= rule.freeFromPaise;
  const deliveryFeePaise = free ? 0 : rule.chargePaise;
  const freeTravelShortfallPaise =
    rule.freeFromPaise != null && !free && deliveryFeePaise > 0 ? rule.freeFromPaise - itemsTotalPaise : null;
  return { deliveryFeePaise, freeTravelShortfallPaise };
}

/**
 * The rule an existing order is re-priced under when its items change. Orders booked since the rule was recorded use that
 * snapshot; older ones (no snapshot) keep the delivery fee they were booked with and never become free by the count.
 */
export function orderTravelRule(order: {
  deliveryFeePaise: number;
  travelChargePaiseRule: number | null;
  travelFreeFromPaiseRule: number | null;
}): TravelRule {
  if (order.travelChargePaiseRule == null) return { chargePaise: order.deliveryFeePaise, freeFromPaise: null };
  return { chargePaise: order.travelChargePaiseRule, freeFromPaise: order.travelFreeFromPaiseRule };
}

/** All prices are integers in paise; nothing here touches floating-point money. */
export function computeQuote(
  lines: PricingLine[],
  settings: PricingSettings,
  promotion: PricingPromotion | null,
): Quote {
  const priced = lines.map((l) => ({ ...l, lineTotalPaise: l.unitPricePaise * l.quantity }));
  const subtotalPaise = priced.reduce((sum, l) => sum + l.lineTotalPaise, 0);

  let appliedPromotion: PricingPromotion | null = null;
  let promoShortfallPaise: number | null = null;
  let discountPaise = 0;
  if (promotion) {
    if (subtotalPaise >= promotion.minOrderPaise) {
      appliedPromotion = promotion;
      discountPaise = discountFor(subtotalPaise, promotion);
    } else {
      promoShortfallPaise = promotion.minOrderPaise - subtotalPaise;
    }
  }

  const afterDiscount = subtotalPaise - discountPaise;
  // Travel is free from a threshold on the items total BEFORE the coupon: a coupon never turns a free-travel order into a charged one.
  const { deliveryFeePaise, freeTravelShortfallPaise } = travelCharge(subtotalPaise, {
    chargePaise: settings.deliveryFeePaise,
    freeFromPaise: settings.freeDeliveryAbovePaise,
  });

  return {
    lines: priced,
    subtotalPaise,
    discountPaise,
    deliveryFeePaise,
    totalPaise: afterDiscount + deliveryFeePaise,
    freeTravelShortfallPaise,
    appliedPromotion,
    promoShortfallPaise,
    minOrderShortfallPaise:
      subtotalPaise < settings.minOrderPaise ? settings.minOrderPaise - subtotalPaise : null,
  };
}

/**
 * Everything paid has been refunded (PENDING and PROCESSED refunds count) → REFUNDED. `keptPaise` is money we are entitled
 * to keep out of what was paid (the travel charge on an order cancelled after the partner travelled): once everything
 * else has been refunded the order counts as refunded.
 */
export function paymentStatusFor(totalPaise: number, paidPaise: number, refundedPaise = 0, keptPaise = 0): PaymentStatus {
  if (paidPaise > 0 && refundedPaise > 0 && refundedPaise >= paidPaise - Math.min(keptPaise, paidPaise)) return PaymentStatus.REFUNDED;
  if (paidPaise <= 0) return totalPaise === 0 ? PaymentStatus.PAID : PaymentStatus.UNPAID;
  return paidPaise >= totalPaise ? PaymentStatus.PAID : PaymentStatus.PARTIALLY_PAID;
}
