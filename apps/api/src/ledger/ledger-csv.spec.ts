import { CSV_BOM, csvCell, csvRow, ledgerCsv } from './ledger-csv.js';
import type { LedgerEntryDto } from './ledger.dto.js';

const entry = (over: Partial<LedgerEntryDto> = {}): LedgerEntryDto => ({
  id: 'a1',
  kind: 'PAYMENT',
  status: 'CAPTURED',
  method: 'RAZORPAY',
  amountPaise: 12050,
  orderId: 'o1',
  orderNumber: 'LD001042',
  customerId: 'c1',
  customerName: 'Priya Sharma',
  customerPhone: '+919876543210',
  reference: 'pay_Abc123',
  note: null,
  failureReason: null,
  occurredAt: new Date('2026-10-02T09:15:09.000Z'),
  ...over,
});

describe('csvCell', () => {
  it('leaves plain text alone and writes nothing for a missing value', () => {
    expect(csvCell('Priya Sharma')).toBe('Priya Sharma');
    expect(csvCell(42)).toBe('42');
    expect(csvCell(null)).toBe('');
    expect(csvCell(undefined)).toBe('');
    expect(csvCell('')).toBe('');
  });

  it('puts an apostrophe in front of anything a spreadsheet would run as a formula', () => {
    expect(csvCell('=SUM(A1:A9)')).toBe("'=SUM(A1:A9)");
    expect(csvCell('+91 98765')).toBe("'+91 98765");
    expect(csvCell('-2+3')).toBe("'-2+3");
    expect(csvCell('@cmd')).toBe("'@cmd");
    expect(csvCell('\tcmd')).toBe("'\tcmd");
    expect(csvCell('\rcmd')).toBe('"\'\rcmd"');
  });

  it('only looks at the start of the cell', () => {
    expect(csvCell('a=b')).toBe('a=b');
    expect(csvCell('Ravi - cash')).toBe('Ravi - cash');
    expect(csvCell('user@example.com')).toBe('user@example.com');
    expect(csvCell(' =1')).toBe(' =1');
  });

  it('quotes cells with commas, quotes or line breaks, doubling the quotes', () => {
    expect(csvCell('Sharma, Priya')).toBe('"Sharma, Priya"');
    expect(csvCell('said "hi"')).toBe('"said ""hi"""');
    expect(csvCell('line one\nline two')).toBe('"line one\nline two"');
    expect(csvCell('a\r\nb')).toBe('"a\r\nb"');
  });

  it('neutralises first and quotes after, so a formula with commas stays one harmless cell', () => {
    expect(csvCell('=HYPERLINK("http://x.test","click")')).toBe('"\'=HYPERLINK(""http://x.test"",""click"")"');
    expect(csvCell('-1,2')).toBe('"\'-1,2"');
  });

  it('joins cells into a row', () => {
    expect(csvRow(['a', null, 'b,c', 3])).toBe('a,,"b,c",3');
  });
});

describe('ledgerCsv', () => {
  const lines = (csv: string) => csv.replace(CSV_BOM, '').split('\r\n');

  it('starts with a byte-order mark and a header, and ends every row with CRLF', () => {
    const csv = ledgerCsv([entry()]);
    expect(csv.startsWith(CSV_BOM)).toBe(true);
    expect(csv.endsWith('\r\n')).toBe(true);
    expect(lines(csv)).toEqual([
      'Time (IST),Type,Status,Method,Amount (INR),Order,Customer,Phone,Reference,Note',
      '2026-10-02 14:45:09,PAYMENT,CAPTURED,RAZORPAY,120.50,LD001042,Priya Sharma,98765 43210,pay_Abc123,',
      '',
    ]);
  });

  it('writes a header only when there are no entries', () => {
    expect(lines(ledgerCsv([]))).toEqual(['Time (IST),Type,Status,Method,Amount (INR),Order,Customer,Phone,Reference,Note', '']);
  });

  it('neutralises what customers and staff typed', () => {
    const csv = ledgerCsv([
      entry({ customerName: '=cmd|\' /C calc\'!A0', note: '@SUM(1,1)', reference: '+1' }),
    ]);
    const [, row] = lines(csv);
    expect(row).toContain(",'=cmd|' /C calc'!A0,");
    expect(row).toContain(',"\'@SUM(1,1)"');
    expect(row).toContain(",'+1,");
  });

  it('shows a refund with its note and why it failed, and an erased customer as blank', () => {
    const [, row] = lines(
      ledgerCsv([
        entry({
          kind: 'REFUND',
          status: 'FAILED',
          method: 'BANK_TRANSFER',
          amountPaise: 5000,
          customerName: null,
          customerPhone: null,
          reference: null,
          note: 'Sorry, shirt damaged',
          failureReason: 'Razorpay could not complete the refund',
        }),
      ]),
    );
    expect(row).toBe(
      '2026-10-02 14:45:09,REFUND,FAILED,BANK_TRANSFER,50.00,LD001042,,,,"Sorry, shirt damaged | Failed: Razorpay could not complete the refund"',
    );
  });

  it('writes a number it does not know how to shorten as it is, but still safe', () => {
    const [, row] = lines(ledgerCsv([entry({ customerPhone: '+14155550123' })]));
    expect(row).toContain(",'+14155550123,");
  });
});
