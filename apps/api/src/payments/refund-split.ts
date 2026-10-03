/** A captured Razorpay payment and how much of it has already gone back (PENDING + PROCESSED refunds). */
export interface RefundablePayment {
  id: string;
  razorpayPaymentId: string;
  amountPaise: number;
  refundedPaise: number;
  createdAt: Date;
}

export interface RefundPart {
  paymentId: string;
  razorpayPaymentId: string;
  amountPaise: number;
}

/** What can still go back through Razorpay across these payments. */
export function onlineRefundable(payments: readonly RefundablePayment[]): number {
  return payments.reduce((sum, p) => sum + Math.max(0, p.amountPaise - p.refundedPaise), 0);
}

/**
 * Splits a Razorpay refund across captured payments, newest payment first,
 * taking from each no more than what is left on it. Returns null when the
 * payments together cannot cover the amount.
 */
export function splitRefund(amountPaise: number, payments: readonly RefundablePayment[]): RefundPart[] | null {
  if (!Number.isInteger(amountPaise) || amountPaise <= 0) return null;
  const newestFirst = [...payments].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  const parts: RefundPart[] = [];
  let remaining = amountPaise;
  for (const p of newestFirst) {
    if (remaining === 0) break;
    const left = p.amountPaise - p.refundedPaise;
    if (left <= 0) continue;
    const take = Math.min(left, remaining);
    parts.push({ paymentId: p.id, razorpayPaymentId: p.razorpayPaymentId, amountPaise: take });
    remaining -= take;
  }
  return remaining === 0 ? parts : null;
}
