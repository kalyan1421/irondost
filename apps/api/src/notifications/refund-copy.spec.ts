import { RefundMethod } from '../generated/prisma/enums.js';
import { refundCopy } from './refund-copy.js';

const base = { amountPaise: 24800, orderNumber: 'ID001046', note: 'Sorry, we could not pick up in time.' };

describe('refundCopy', () => {
  it('tells the customer a Razorpay refund has started and how long it takes', () => {
    expect(refundCopy({ ...base, stage: 'created', method: RefundMethod.RAZORPAY })).toEqual({
      type: 'refund_started',
      title: 'Refund of ₹248 started',
      body: 'For order ID001046. It reaches your original payment method in 7–14 business days.\nNote: Sorry, we could not pick up in time.',
    });
  });

  it('confirms when Razorpay has processed it', () => {
    const copy = refundCopy({ ...base, stage: 'processed', method: RefundMethod.RAZORPAY });
    expect(copy.type).toBe('refund_processed');
    expect(copy.title).toBe('Refund of ₹248 processed');
    expect(copy.body).toMatch(/Note: Sorry, we could not pick up in time\.$/);
  });

  it('says how the money was returned by hand', () => {
    expect(refundCopy({ ...base, stage: 'created', method: RefundMethod.CASH })).toEqual({
      type: 'refund_processed',
      title: '₹248 refunded',
      body: "We've returned ₹248 for order ID001046 by cash.\nNote: Sorry, we could not pick up in time.",
    });
    expect(refundCopy({ ...base, amountPaise: 24850, stage: 'created', method: RefundMethod.BANK_TRANSFER }).body).toContain(
      "We've returned ₹248.50 for order ID001046 by bank transfer or UPI.",
    );
  });

  it('owns up when a refund fails', () => {
    const copy = refundCopy({ ...base, stage: 'failed', method: RefundMethod.RAZORPAY });
    expect(copy).toMatchObject({ type: 'refund_failed', title: 'Refund of ₹248 failed' });
    expect(copy.body).toMatch(/^We couldn't return ₹248 for order ID001046/);
    expect(copy.body.endsWith('Note: Sorry, we could not pick up in time.')).toBe(true);
  });
});
