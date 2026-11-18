import type { PrismaService } from '../prisma/prisma.service.js';

/**
 * What an order's customer paid that we are entitled to keep: the travel charge, when staff cancelled after the partner had
 * already travelled. Never more than was paid.
 */
export function keptTravelPaise(o: { paidPaise: number; deliveryFeePaise: number; travelChargeKept: boolean }): number {
  return o.travelChargeKept ? Math.min(o.deliveryFeePaise, o.paidPaise) : 0;
}

/** What can still be refunded: paid, less what went back, less the travel charge when it was kept. */
export function refundablePaise(o: { paidPaise: number; refundedPaise: number; deliveryFeePaise: number; travelChargeKept: boolean }): number {
  return Math.max(0, o.paidPaise - o.refundedPaise - keptTravelPaise(o));
}

/**
 * Orders that hold more of the customer's money than they should: cancelled after paying, or paid more than a
 * total that staff later reduced. A kept travel charge is not owed back. Comparing columns is not something Prisma's
 * `where` can express, hence the SQL (the kept amount mirrors keptTravelPaise above).
 */
export async function refundDueOrderIds(prisma: Pick<PrismaService, '$queryRaw'>): Promise<string[]> {
  const rows = await prisma.$queryRaw<{ id: string }[]>`
    SELECT id FROM orders
    WHERE paid_paise - refunded_paise - (CASE WHEN travel_charge_kept THEN LEAST(delivery_fee_paise, paid_paise) ELSE 0 END) > 0
      AND (status = 'CANCELLED' OR paid_paise - refunded_paise > total_paise)`;
  return rows.map((r) => r.id);
}
