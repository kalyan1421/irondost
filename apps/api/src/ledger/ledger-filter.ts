import { AppError } from '../common/errors.js';
import { normalizeIndianPhone } from '../common/phone.js';
import { addDays, isIsoDate, istInstant } from '../common/time.js';
import { Prisma } from '../generated/prisma/client.js';
import type { LedgerFilterQuery, LedgerKind, LedgerMethod, LedgerStatus } from './ledger.dto.js';

/** What `status=problem` stands for. */
export const PROBLEM_STATUSES: readonly LedgerStatus[] = ['PENDING', 'FAILED'];

/** The filters of one request, checked and in the shape the database wants. Nothing here touches the database. */
export interface LedgerFilter {
  kind?: LedgerKind;
  /** Entries must have one of these statuses. */
  statuses?: readonly LedgerStatus[];
  method?: LedgerMethod;
  /** Inclusive. */
  occurredFrom?: Date;
  /** Exclusive: midnight after the last day asked for. */
  occurredBefore?: Date;
  /** LIKE pattern for the order number, with the person's text escaped. */
  orderNumberLike?: string;
  /** The customer's number in E.164, when the search is a whole valid number. */
  phoneExact?: string;
  /** LIKE pattern over digits typed so far, when the search is only digits and phone punctuation. */
  phoneLike?: string;
}

/** Makes `%`, `_` and `\` in typed text match themselves inside a LIKE pattern. */
export function escapeLike(text: string): string {
  return text.replace(/[\\%_]/g, (c) => `\\${c}`);
}

function checkedDate(value: string | undefined, name: string): string | undefined {
  if (value === undefined) return undefined;
  if (!isIsoDate(value)) throw AppError.badRequest('INVALID_DATE', `${name} must be a real date, written YYYY-MM-DD`);
  return value;
}

export function parseLedgerFilter(q: LedgerFilterQuery): LedgerFilter {
  const from = checkedDate(q.from, 'from');
  const to = checkedDate(q.to, 'to');
  if (from && to && from > to) throw AppError.badRequest('INVALID_DATE_RANGE', '"from" must not be after "to"');

  const filter: LedgerFilter = {};
  if (q.kind) filter.kind = q.kind;
  if (q.status) filter.statuses = q.status === 'problem' ? PROBLEM_STATUSES : [q.status];
  if (q.method) filter.method = q.method;
  if (from) filter.occurredFrom = istInstant(from, 0);
  if (to) filter.occurredBefore = istInstant(addDays(to, 1), 0);

  const search = q.search?.trim();
  if (search) {
    filter.orderNumberLike = `%${escapeLike(search)}%`;
    const exact = normalizeIndianPhone(search);
    if (exact) {
      filter.phoneExact = exact;
    } else if (/^\+?[\d\s()-]+$/.test(search)) {
      const digits = search.replace(/\D/g, '');
      if (digits) filter.phoneLike = `%${digits}%`;
    }
  }
  return filter;
}

/**
 * The WHERE clause over the joined entry (`e`), order (`o`) and customer (`u`) of `ledger-queries.ts`.
 * Every value goes in as a bound parameter.
 */
export function ledgerWhere(filter: LedgerFilter): Prisma.Sql {
  const conditions: Prisma.Sql[] = [];
  if (filter.kind) conditions.push(Prisma.sql`e.kind = ${filter.kind}`);
  if (filter.statuses) conditions.push(Prisma.sql`e.status IN (${Prisma.join([...filter.statuses])})`);
  if (filter.method) conditions.push(Prisma.sql`e.method = ${filter.method}`);
  if (filter.occurredFrom) conditions.push(Prisma.sql`e.occurred_at >= ${filter.occurredFrom}`);
  if (filter.occurredBefore) conditions.push(Prisma.sql`e.occurred_at < ${filter.occurredBefore}`);

  if (filter.orderNumberLike) {
    const matches: Prisma.Sql[] = [Prisma.sql`o.order_number ILIKE ${filter.orderNumberLike}`];
    if (filter.phoneExact) {
      matches.push(Prisma.sql`u.phone = ${filter.phoneExact}`, Prisma.sql`u.contact_phone = ${filter.phoneExact}`);
    } else if (filter.phoneLike) {
      matches.push(Prisma.sql`u.phone LIKE ${filter.phoneLike}`, Prisma.sql`u.contact_phone LIKE ${filter.phoneLike}`);
    }
    conditions.push(Prisma.sql`(${Prisma.join(matches, ' OR ')})`);
  }
  return conditions.length ? Prisma.join(conditions, ' AND ') : Prisma.sql`TRUE`;
}
