import type { OrderWindows } from '../events.js';
import { deliveryChanged, pickupChanged, windowText } from './reschedule.js';

export interface RescheduleCopyInput {
  orderNumber: string;
  previous: OrderWindows;
  next: OrderWindows;
  /** A partner held the pickup and no longer does. */
  partnerReleased: boolean;
}

export interface RescheduleCopy {
  title: string;
  body: string;
}

/** To the partner who had accepted the pickup: it moved, and it is not theirs any more. */
export function partnerRescheduleCopy(orderNumber: string): RescheduleCopy {
  return {
    title: 'Pickup time changed',
    body: `The customer changed the pickup time for order ${orderNumber}. It is no longer assigned to you.`,
  };
}

/** To staff: what moved, and what that did to the assignment. */
export function staffRescheduleCopy({ orderNumber, previous, next, partnerReleased }: RescheduleCopyInput): RescheduleCopy {
  const pickup = pickupChanged(previous, next);
  const moved: string[] = [];
  if (pickup) moved.push(`pickup from ${windowText(previous.pickupDate, previous.pickupSlot)} to ${windowText(next.pickupDate, next.pickupSlot)}`);
  if (deliveryChanged(previous, next)) {
    moved.push(`delivery from ${windowText(previous.deliveryDate, previous.deliverySlot)} to ${windowText(next.deliveryDate, next.deliverySlot)}`);
  }
  const effect = partnerReleased ? ' The assigned partner was released and the order is offered again.' : '';
  return {
    title: pickup ? 'Pickup time changed' : 'Delivery time changed',
    body: `Order ${orderNumber}: the customer moved the ${moved.join(' and the ')}.${effect}`,
  };
}
