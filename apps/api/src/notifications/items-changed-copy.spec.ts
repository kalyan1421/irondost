import { itemsChangedCopy } from './items-changed-copy.js';

const base = { orderNumber: 'ID-1001', previousTotalPaise: 10000, totalPaise: 12000, paidPaise: 0, refundedPaise: 0 };

describe('itemsChangedCopy', () => {
  it('says nothing when the total did not move', () => {
    expect(itemsChangedCopy({ ...base, totalPaise: 10000 })).toBeNull();
  });

  it('tells a cash customer the new total', () => {
    const copy = itemsChangedCopy(base)!;
    expect(copy.title).toBe('Your order total changed');
    expect(copy.body).toContain('ID-1001');
    expect(copy.body).toContain('₹120');
    expect(copy.body).toContain('still due');
    expect(copy.refundOwedPaise).toBe(0);
  });

  it('asks for the difference when a prepaid order grows', () => {
    const copy = itemsChangedCopy({ ...base, paidPaise: 10000 })!;
    expect(copy.body).toContain('₹20');
    expect(copy.body).toContain('still due');
  });

  it('promises the difference back, and reports it, when a prepaid order shrinks', () => {
    const copy = itemsChangedCopy({ ...base, totalPaise: 7000, paidPaise: 10000 })!;
    expect(copy.refundOwedPaise).toBe(3000);
    expect(copy.body).toContain('return the extra');
    expect(copy.body).not.toContain('still due');
  });

  it('does not owe what was already refunded', () => {
    const copy = itemsChangedCopy({ ...base, totalPaise: 7000, paidPaise: 10000, refundedPaise: 3000 })!;
    expect(copy.refundOwedPaise).toBe(0);
    expect(copy.body).not.toContain('return the extra');
    expect(copy.body).not.toContain('still due');
  });
});
