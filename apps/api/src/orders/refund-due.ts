import type { PrismaService } from '../prisma/prisma.service.js';

/**
 * Orders that hold more of the customer's money than they should: cancelled after paying, or paid more than a
 * total that staff later reduced. Comparing two columns is not something Prisma's `where` can express, hence the SQL.
 */
export async function refundDueOrderIds(prisma: Pick<PrismaService, '$queryRaw'>): Promise<string[]> {
  const rows = await prisma.$queryRaw<{ id: string }[]>`
    SELECT id FROM orders
    WHERE paid_paise > refunded_paise
      AND (status = 'CANCELLED' OR paid_paise - refunded_paise > total_paise)`;
  return rows.map((r) => r.id);
}
