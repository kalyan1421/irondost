import { rupees } from '../common/money.js';
import { RefundMethod } from '../generated/prisma/enums.js';

export type RefundStage = 'created' | 'processed' | 'failed';

export interface RefundCopyInput {
  stage: RefundStage;
  method: RefundMethod;
  amountPaise: number;
  orderNumber: string;
  /** The staff note; always ends the body. */
  note: string;
}

export interface RefundCopy {
  type: 'refund_started' | 'refund_processed' | 'refund_failed';
  title: string;
  body: string;
}

const RETURNED_BY: Record<Exclude<RefundMethod, 'RAZORPAY'>, string> = {
  [RefundMethod.CASH]: 'by cash',
  [RefundMethod.BANK_TRANSFER]: 'by bank transfer or UPI',
};

/** Customer inbox + push copy for a refund. */
export function refundCopy({ stage, method, amountPaise, orderNumber, note }: RefundCopyInput): RefundCopy {
  const amount = rupees(amountPaise);
  const withNote = (text: string) => `${text}\nNote: ${note.trim()}`;

  if (stage === 'failed') {
    return {
      type: 'refund_failed',
      title: `Refund of ${amount} failed`,
      body: withNote(`We couldn't return ${amount} for order ${orderNumber} to your original payment method. Our team will contact you to sort it out.`),
    };
  }
  if (method === RefundMethod.RAZORPAY) {
    return stage === 'created'
      ? {
          type: 'refund_started',
          title: `Refund of ${amount} started`,
          body: withNote(`For order ${orderNumber}. It reaches your original payment method in 7–14 business days.`),
        }
      : {
          type: 'refund_processed',
          title: `Refund of ${amount} processed`,
          body: withNote(`We've sent ${amount} for order ${orderNumber} back to your original payment method. Your bank may take a few days to show it.`),
        };
  }
  // Cash and bank transfers are recorded once staff have already returned the money.
  return {
    type: 'refund_processed',
    title: `${amount} refunded`,
    body: withNote(`We've returned ${amount} for order ${orderNumber} ${RETURNED_BY[method]}.`),
  };
}
