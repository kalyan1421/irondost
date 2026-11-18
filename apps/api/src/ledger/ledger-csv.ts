import { istTimestamp } from '../common/time.js';
import type { LedgerEntryDto } from './ledger.dto.js';

/** Excel only reads a CSV as UTF-8 (customer names in Telugu or Hindi) when it starts with this mark. */
export const CSV_BOM = '﻿';

/** A spreadsheet runs a cell that starts with one of these as a formula. */
const FORMULA_START = /^[=+\-@\t\r]/;
const NEEDS_QUOTES = /[",\r\n]/;

/**
 * One CSV cell. Text a person typed (a customer's name, a refund note) can start with `=`, `+`, `-`, `@`, a tab or a
 * carriage return, which Excel and Sheets would run as a formula, so those cells get a leading apostrophe. Cells that
 * hold commas, quotes or line breaks are quoted, with quotes doubled.
 */
export function csvCell(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return '';
  let text = String(value);
  if (FORMULA_START.test(text)) text = `'${text}`;
  return NEEDS_QUOTES.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

export function csvRow(cells: ReadonlyArray<string | number | null | undefined>): string {
  return cells.map(csvCell).join(',');
}

const HEADER = ['Time (IST)', 'Type', 'Status', 'Method', 'Amount (INR)', 'Order', 'Customer', 'Phone', 'Reference', 'Note'];

/** "+919876543210" as "98765 43210": the same digits without a leading `+`, which a spreadsheet would read as a formula. */
function csvPhone(e164: string | null): string | null {
  if (!e164) return null;
  const m = /^\+91(\d{5})(\d{5})$/.exec(e164);
  return m ? `${m[1]} ${m[2]}` : e164;
}

/** The ledger as CSV text: a byte-order mark, a header, then one CRLF-ended row per entry. Amounts are positive rupees. */
export function ledgerCsv(entries: readonly LedgerEntryDto[]): string {
  const rows = entries.map((e) =>
    csvRow([
      istTimestamp(e.occurredAt),
      e.kind,
      e.status,
      e.method,
      (e.amountPaise / 100).toFixed(2),
      e.orderNumber,
      e.customerName,
      csvPhone(e.customerPhone),
      e.reference,
      // A failed refund's reason is what staff need next to its note.
      e.failureReason ? [e.note, `Failed: ${e.failureReason}`].filter(Boolean).join(' | ') : e.note,
    ]),
  );
  return `${CSV_BOM}${[csvRow(HEADER), ...rows].join('\r\n')}\r\n`;
}
