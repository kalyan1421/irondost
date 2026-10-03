import type { DispatchLeg, OrderStatus, RefundMethod, RefundStatus, Role } from './generated/prisma/enums.js';

/**
 * In-process domain events (via @nestjs/event-emitter). Emitted after the
 * database transaction commits; listeners handle push, realtime and dispatch.
 */
export const Events = {
  OrderCreated: 'order.created',
  OrderStatusChanged: 'order.status_changed',
  OrderUpdated: 'order.updated',
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
}

export interface OrderUpdatedEvent extends OrderRef {
  reason: 'items_changed' | 'payment_changed' | 'details_changed';
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
