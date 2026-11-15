import { PaymentProvider, PaymentRecordStatus, RefundMethod, RefundStatus } from '../generated/prisma/enums.js';
import { escapeLike, ledgerWhere, parseLedgerFilter, PROBLEM_STATUSES } from './ledger-filter.js';
import { LEDGER_METHODS, LEDGER_STATUSES } from './ledger.dto.js';

describe('ledger filters', () => {
  it('stay in step with the payment and refund statuses and methods in the schema', () => {
    const statuses = new Set<string>([...Object.values(PaymentRecordStatus), ...Object.values(RefundStatus)]);
    expect(new Set<string>(LEDGER_STATUSES)).toEqual(statuses);
    const methods = new Set<string>([...Object.values(PaymentProvider), ...Object.values(RefundMethod)]);
    expect(new Set<string>(LEDGER_METHODS)).toEqual(methods);
  });

  it('are empty when nothing is asked', () => {
    expect(parseLedgerFilter({})).toEqual({});
    expect(parseLedgerFilter({ search: '   ' })).toEqual({});
    const where = ledgerWhere({});
    expect(where.text).toBe('TRUE');
    expect(where.values).toEqual([]);
  });

  it('turn status=problem into pending and failed, and any other status into itself', () => {
    expect(parseLedgerFilter({ status: 'problem' }).statuses).toEqual(PROBLEM_STATUSES);
    expect([...PROBLEM_STATUSES].sort()).toEqual(['FAILED', 'PENDING']);
    expect(parseLedgerFilter({ status: 'CAPTURED' }).statuses).toEqual(['CAPTURED']);
  });

  it('read the date range as whole IST days, the last day included', () => {
    const f = parseLedgerFilter({ from: '2026-10-01', to: '2026-10-31' });
    expect(f.occurredFrom?.toISOString()).toBe('2026-09-30T18:30:00.000Z');
    expect(f.occurredBefore?.toISOString()).toBe('2026-10-31T18:30:00.000Z');
    expect(parseLedgerFilter({ from: '2026-10-01', to: '2026-10-01' }).occurredBefore?.toISOString()).toBe('2026-10-01T18:30:00.000Z');
    expect(parseLedgerFilter({ to: '2026-12-31' }).occurredFrom).toBeUndefined();
  });

  it('refuse dates that are not real and ranges that run backwards', () => {
    expect(() => parseLedgerFilter({ from: '2026-02-30' })).toThrow(/real date/);
    expect(() => parseLedgerFilter({ to: '2026-13-01' })).toThrow(/real date/);
    expect(() => parseLedgerFilter({ from: '2026-10-02', to: '2026-10-01' })).toThrow(/after/);
  });

  describe('search', () => {
    it('matches an order number anywhere in it, whatever the case', () => {
      const f = parseLedgerFilter({ search: ' ld0010 ' });
      expect(f.orderNumberLike).toBe('%ld0010%');
      expect(f.phoneExact).toBeUndefined();
      expect(f.phoneLike).toBeUndefined();
    });

    it('treats a whole mobile number as exact, however it is written', () => {
      for (const typed of ['9876543210', '+91 98765 43210', '09876543210', '91-9876543210']) {
        expect(parseLedgerFilter({ search: typed }).phoneExact).toBe('+919876543210');
      }
    });

    it('matches part of a number typed so far, but not digits inside an order number search', () => {
      expect(parseLedgerFilter({ search: '98765 4' }).phoneLike).toBe('%987654%');
      expect(parseLedgerFilter({ search: '+91 987' }).phoneLike).toBe('%91987%');
      expect(parseLedgerFilter({ search: 'LD001042' }).phoneLike).toBeUndefined();
    });

    it('makes %, _ and \\ match themselves', () => {
      expect(escapeLike('100%_off\\')).toBe('100\\%\\_off\\\\');
      expect(parseLedgerFilter({ search: 'a%b' }).orderNumberLike).toBe('%a\\%b%');
    });
  });

  describe('SQL', () => {
    it('binds every value and joins the conditions with AND', () => {
      const where = ledgerWhere(
        parseLedgerFilter({ kind: 'REFUND', status: 'problem', method: 'RAZORPAY', from: '2026-10-01', to: '2026-10-02' }),
      );
      expect(where.text).toBe(
        'e.kind = $1 AND e.status IN ($2,$3) AND e.method = $4 AND e.occurred_at >= $5 AND e.occurred_at < $6',
      );
      expect(where.values).toEqual([
        'REFUND',
        'PENDING',
        'FAILED',
        'RAZORPAY',
        new Date('2026-09-30T18:30:00.000Z'),
        new Date('2026-10-02T18:30:00.000Z'),
      ]);
    });

    it('searches the order number, and the phone or contact phone', () => {
      const exact = ledgerWhere(parseLedgerFilter({ search: '9876543210' }));
      expect(exact.text).toBe('(o.order_number ILIKE $1 OR u.phone = $2 OR u.contact_phone = $3)');
      expect(exact.values).toEqual(['%9876543210%', '+919876543210', '+919876543210']);

      const partial = ledgerWhere(parseLedgerFilter({ search: '98765' }));
      expect(partial.text).toBe('(o.order_number ILIKE $1 OR u.phone LIKE $2 OR u.contact_phone LIKE $3)');
      expect(partial.values).toEqual(['%98765%', '%98765%', '%98765%']);

      const order = ledgerWhere(parseLedgerFilter({ search: 'LD001042' }));
      expect(order.text).toBe('(o.order_number ILIKE $1)');
    });

    it('never puts what the person typed into the statement text', () => {
      const evil = "x'; DROP TABLE payments; --";
      const where = ledgerWhere(parseLedgerFilter({ search: evil }));
      expect(where.text).not.toContain('DROP');
      expect(where.values).toEqual([`%${evil}%`]);
    });
  });
});
