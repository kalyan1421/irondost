import { Prisma } from '../generated/prisma/client.js';
import type { LedgerKind, LedgerMethod, LedgerStatus } from './ledger.dto.js';

/**
 * Payments and refunds as one set of rows with the same columns, so the database can filter, count, sort and
 * page them together. Prisma cannot UNION two tables, hence the SQL.
 *
 * Only the columns listed here ever leave the database: `payments.raw` (the gateway's payload) is not among them.
 * Enum columns are cast to text so both tables share one `status` and one `method` column.
 */
const ENTRIES = Prisma.sql`
  SELECT 'PAYMENT'::text AS kind,
         p.id,
         p.order_id,
         p.status::text AS status,
         p.provider::text AS method,
         p.amount_paise,
         coalesce(p.razorpay_payment_id, p.razorpay_order_id) AS reference,
         CASE WHEN p.collected_by_id IS NOT NULL THEN 'Collected by ' || coalesce(c.name, 'staff') END AS note,
         NULL::text AS failure_reason,
         coalesce(p.captured_at, p.created_at) AS occurred_at
  FROM payments p
  LEFT JOIN users c ON c.id = p.collected_by_id
  UNION ALL
  SELECT 'REFUND'::text,
         r.id,
         r.order_id,
         r.status::text,
         r.method::text,
         r.amount_paise,
         r.razorpay_refund_id,
         r.note,
         r.failure_reason,
         coalesce(r.processed_at, r.created_at)
  FROM refunds r`;

/** Entry `e`, its order `o` and the order's customer `u`; what `ledgerWhere` filters on. */
const FROM = Prisma.sql`
  FROM (${ENTRIES}) e
  JOIN orders o ON o.id = e.order_id
  JOIN users u ON u.id = o.customer_id`;

export interface LedgerRow {
  kind: LedgerKind;
  id: string;
  status: LedgerStatus;
  method: LedgerMethod;
  amount_paise: number;
  reference: string | null;
  note: string | null;
  failure_reason: string | null;
  occurred_at: Date;
  order_id: string;
  order_number: string;
  customer_id: string;
  customer_name: string | null;
  phone: string | null;
  contact_phone: string | null;
}

/** One page of entries, newest first. `id` breaks ties so pages never repeat or skip a row. */
export function entriesQuery(where: Prisma.Sql, limit: number, offset: number): Prisma.Sql {
  return Prisma.sql`
    SELECT e.kind, e.id, e.status, e.method, e.amount_paise, e.reference, e.note, e.failure_reason, e.occurred_at,
           o.id AS order_id, o.order_number,
           u.id AS customer_id, u.name AS customer_name, u.phone, u.contact_phone
    ${FROM}
    WHERE ${where}
    ORDER BY e.occurred_at DESC, e.id DESC
    LIMIT ${limit} OFFSET ${offset}`;
}

export interface LedgerSummaryRow {
  total: number;
  captured_count: number;
  captured_paise: number;
  refunded_count: number;
  refunded_paise: number;
  refund_pending_count: number;
  refund_pending_paise: number;
  failed_count: number;
  failed_paise: number;
}

/** How many entries match, and the counts and sums behind the totals row. Sums are float8: exact below 2^53 paise. */
export function summaryQuery(where: Prisma.Sql): Prisma.Sql {
  const bucket = (name: string, condition: Prisma.Sql) => Prisma.sql`
    count(*) FILTER (WHERE ${condition})::int AS ${Prisma.raw(`${name}_count`)},
    coalesce(sum(e.amount_paise) FILTER (WHERE ${condition}), 0)::float8 AS ${Prisma.raw(`${name}_paise`)}`;
  return Prisma.sql`
    SELECT count(*)::int AS total,
           ${bucket('captured', Prisma.sql`e.kind = 'PAYMENT' AND e.status = 'CAPTURED'`)},
           ${bucket('refunded', Prisma.sql`e.kind = 'REFUND' AND e.status = 'PROCESSED'`)},
           ${bucket('refund_pending', Prisma.sql`e.kind = 'REFUND' AND e.status = 'PENDING'`)},
           ${bucket('failed', Prisma.sql`e.status = 'FAILED'`)}
    ${FROM}
    WHERE ${where}`;
}
