import { Injectable } from '@nestjs/common';
import { Clock } from '../common/clock.js';
import { customerPhone } from '../common/phone.js';
import { istDate } from '../common/time.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ledgerCsv } from './ledger-csv.js';
import { ledgerWhere, parseLedgerFilter } from './ledger-filter.js';
import { entriesQuery, summaryQuery, type LedgerRow, type LedgerSummaryRow } from './ledger-queries.js';
import type { LedgerEntryDto, LedgerFilterQuery, LedgerPageDto, LedgerQuery } from './ledger.dto.js';

/** The most rows one CSV export holds. Staff narrow the filters (dates, status) to export less. */
export const EXPORT_ROW_LIMIT = 10_000;

export interface LedgerExport {
  filename: string;
  csv: string;
  rows: number;
  /** True when more entries matched than the limit let through; the newest ones are in the file. */
  truncated: boolean;
}

const toEntry = (r: LedgerRow): LedgerEntryDto => ({
  id: r.id,
  kind: r.kind,
  status: r.status,
  method: r.method,
  amountPaise: r.amount_paise,
  orderId: r.order_id,
  orderNumber: r.order_number,
  customerId: r.customer_id,
  customerName: r.customer_name,
  customerPhone: customerPhone({ phone: r.phone, contactPhone: r.contact_phone }),
  reference: r.reference,
  note: r.note,
  failureReason: r.failure_reason,
  occurredAt: r.occurred_at,
});

/** Read-only view over `payments` and `refunds`: one list of money in and money out, for staff reconciling the books. */
@Injectable()
export class LedgerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  async list(q: LedgerQuery): Promise<LedgerPageDto> {
    const where = ledgerWhere(parseLedgerFilter(q));
    const [rows, [summary]] = await Promise.all([
      this.prisma.$queryRaw<LedgerRow[]>(entriesQuery(where, q.pageSize, (q.page - 1) * q.pageSize)),
      this.prisma.$queryRaw<LedgerSummaryRow[]>(summaryQuery(where)),
    ]);
    const bucket = (count: number, paise: number) => ({ count: Number(count), amountPaise: Number(paise) });
    return {
      items: rows.map(toEntry),
      page: q.page,
      pageSize: q.pageSize,
      total: Number(summary.total),
      totals: {
        captured: bucket(summary.captured_count, summary.captured_paise),
        refunded: bucket(summary.refunded_count, summary.refunded_paise),
        refundPending: bucket(summary.refund_pending_count, summary.refund_pending_paise),
        failed: bucket(summary.failed_count, summary.failed_paise),
      },
    };
  }

  /** The same filters as `list`, newest first, as a spreadsheet-safe CSV of at most `EXPORT_ROW_LIMIT` entries. */
  async exportCsv(q: LedgerFilterQuery): Promise<LedgerExport> {
    const where = ledgerWhere(parseLedgerFilter(q));
    // One row past the limit tells us whether the file is complete, without counting.
    const rows = await this.prisma.$queryRaw<LedgerRow[]>(entriesQuery(where, EXPORT_ROW_LIMIT + 1, 0));
    const truncated = rows.length > EXPORT_ROW_LIMIT;
    const kept = truncated ? rows.slice(0, EXPORT_ROW_LIMIT) : rows;
    return {
      filename: `payments-ledger-${istDate(this.clock.now())}.csv`,
      csv: ledgerCsv(kept.map(toEntry)),
      rows: kept.length,
      truncated,
    };
  }
}
