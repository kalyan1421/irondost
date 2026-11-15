import type { DispatchLeg, OrderStatus, RefundMethod, RefundStatus, Role, TimeSlot } from './generated/prisma/enums.js';

/**
 * In-process domain events (via @nestjs/event-emitter). Emitted after the
 * database transaction commits; listeners handle push, realtime and dispatch.
 */
export const Events = {
  IssueChanged: 'issue.changed',
  AdjustmentChanged: 'adjustment.changed',
  OrderCreated: 'order.created',
  OrderStatusChanged: 'order.status_changed',
  OrderUpdated: 'order.updated',
  OrderRescheduled: 'order.rescheduled',
  OffersCreated: 'dispatch.offers_created',
  OffersClosed: 'dispatch.offers_closed',
  DispatchFailed: 'dispatch.failed',
  PaymentCaptured: 'payment.captured',
  RefundCreated: 'refund.created',
  RefundProcessed: 'refund.processed',
  RefundFailed: 'refund.failed',
} as const;

export interface OrderRef {
  orderId: string;
  orderNumber: string;
  customerId: string;
  pickupDriverId: string | null;
  deliveryDriverId: string | null;
}

export interface OrderCreatedEvent extends OrderRef {
  status: OrderStatus;
}

export interface OrderStatusChangedEvent extends OrderRef {
  from: OrderStatus;
  to: OrderStatus;
  actorId: string | null;
  actorRole: Role | null;
  /** Driver removed from a leg by this change (unassignment), if any. */
  removedDriverId: string | null;
  /** Money in hand once the status changed: what was paid and how much of it has gone back. */
  paidPaise: number;
  refundedPaise: number;
}

export interface OrderUpdatedEvent extends OrderRef {
  reason: 'items_changed' | 'payment_changed' | 'details_changed';
  /** For items_changed: the total before and after, and the money in hand, so the customer can be told what it means. */
  previousTotalPaise?: number;
  totalPaise?: number;
  paidPaise?: number;
  refundedPaise?: number;
  actorRole?: Role | null;
}

/** The booked pickup and delivery times of an order: IST calendar dates (YYYY-MM-DD) and slots. */
export interface OrderWindows {
  pickupDate: string;
  pickupSlot: TimeSlot;
  deliveryDate: string;
  deliverySlot: TimeSlot;
}

/** The customer moved the pickup and/or delivery time. Emitted once the new times are committed. */
export interface OrderRescheduledEvent extends OrderRef {
  /** PICKUP_ASSIGNED to PENDING when the pickup moved and a partner had accepted. */
  from: OrderStatus;
  to: OrderStatus;
  previous: OrderWindows;
  next: OrderWindows;
  pickupChanged: boolean;
  deliveryChanged: boolean;
  /** The pickup partner who held the order and no longer does, if any. */
  removedDriverId: string | null;
}

export interface OffersCreatedEvent {
  orderId: string;
  orderNumber: string;
  leg: DispatchLeg;
  offers: { offerId: string; driverId: string; expiresAt: Date }[];
}

export interface OffersClosedEvent {
  orderId: string;
  leg: DispatchLeg;
  driverIds: string[];
}

export interface DispatchFailedEvent {
  orderId: string;
  orderNumber: string;
  leg: DispatchLeg;
}

export interface PaymentCapturedEvent extends OrderRef {
  amountPaise: number;
  provider: 'RAZORPAY' | 'CASH';
}

interface RefundEventBase extends OrderRef {
  refundIds: string[];
  amountPaise: number;
  method: RefundMethod;
  /** Staff note shown to the customer. */
  note: string;
}

/** Staff issued a refund (one request may span several Razorpay payments). */
export interface RefundCreatedEvent extends RefundEventBase {
  /** PENDING while Razorpay is still working on any part of it. */
  status: RefundStatus;
}

/** Razorpay confirmed a pending refund (webhook). */
export type RefundProcessedEvent = RefundEventBase;

/** Razorpay could not complete a refund (webhook); its amount is no longer counted as refunded. */
export interface RefundFailedEvent extends RefundEventBase {
  failureReason: string;
}
