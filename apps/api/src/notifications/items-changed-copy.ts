import { rupees } from '../common/money.js';

export interface ItemsChanged {
  orderNumber: string;
  previousTotalPaise: number;
  totalPaise: number;
  paidPaise: number;
  refundedPaise: number;
}

export interface ItemsChangedCopy {
  title: string;
  body: string;
  /** What the customer paid beyond the new total and has not got back yet. Staff must return it. */
  refundOwedPaise: number;
}

/**
 * What to tell a customer when staff change an order's items (for example after counting the clothes at pickup),
 * or null when the total did not move.
 */
export function itemsChangedCopy(e: ItemsChanged): ItemsChangedCopy | null {
  if (e.totalPaise === e.previousTotalPaise) return null;
  const inHand = Math.max(0, e.paidPaise - e.refundedPaise);
  const due = Math.max(0, e.totalPaise - inHand);
  const refundOwedPaise = Math.max(0, inHand - e.totalPaise);

  let body = `Order ${e.orderNumber} was updated after we counted your clothes. The new total is ${rupees(e.totalPaise)} (it was ${rupees(e.previousTotalPaise)}).`;
  if (due > 0) body += ` ${rupees(due)} is still due: pay in the app or in cash at delivery.`;
  else if (refundOwedPaise > 0) body += ` You paid ${rupees(inHand)}, so we will return the extra ${rupees(refundOwedPaise)}.`;
  return { title: 'Your order total changed', body, refundOwedPaise };
}
