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

export interface PricingSettings {
  minOrderPaise: number;
  deliveryFeePaise: number;
  freeDeliveryAbovePaise: number | null;
}

export interface Quote {
  lines: (PricingLine & { lineTotalPaise: number })[];
  subtotalPaise: number;
  discountPaise: number;
  deliveryFeePaise: number;
  totalPaise: number;
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
  const freeDelivery =
    settings.freeDeliveryAbovePaise != null && afterDiscount >= settings.freeDeliveryAbovePaise;
  const deliveryFeePaise = freeDelivery ? 0 : settings.deliveryFeePaise;

  return {
    lines: priced,
    subtotalPaise,
    discountPaise,
    deliveryFeePaise,
    totalPaise: afterDiscount + deliveryFeePaise,
    appliedPromotion,
    promoShortfallPaise,
    minOrderShortfallPaise:
      subtotalPaise < settings.minOrderPaise ? settings.minOrderPaise - subtotalPaise : null,
  };
}

/** Everything paid has been refunded (PENDING and PROCESSED refunds count) → REFUNDED. */
export function paymentStatusFor(totalPaise: number, paidPaise: number, refundedPaise = 0): PaymentStatus {
  if (paidPaise > 0 && refundedPaise >= paidPaise) return PaymentStatus.REFUNDED;
  if (paidPaise <= 0) return totalPaise === 0 ? PaymentStatus.PAID : PaymentStatus.UNPAID;
  return paidPaise >= totalPaise ? PaymentStatus.PAID : PaymentStatus.PARTIALLY_PAID;
}
