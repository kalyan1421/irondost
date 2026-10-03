import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import {
  Events,
  type DispatchFailedEvent,
  type OffersCreatedEvent,
  type OrderCreatedEvent,
  type OrderStatusChangedEvent,
  type PaymentCapturedEvent,
  type RefundCreatedEvent,
  type RefundFailedEvent,
  type RefundProcessedEvent,
} from '../events.js';
import { rupees } from '../common/money.js';
import { ClientApp, DispatchLeg, OrderStatus, Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { PushService } from './push.service.js';
import { refundCopy, type RefundStage } from './refund-copy.js';

/** Customer-facing copy for each status. Statuses not listed send nothing. */
const CUSTOMER_COPY: Partial<Record<OrderStatus, (n: string) => { title: string; body: string }>> = {
  [OrderStatus.PICKUP_ASSIGNED]: (n) => ({ title: 'Pickup partner assigned', body: `A partner will collect order ${n} in your pickup slot.` }),
  [OrderStatus.PICKED_UP]: (n) => ({ title: 'Clothes picked up', body: `We have your clothes for order ${n}.` }),
  [OrderStatus.PROCESSING]: (n) => ({ title: 'Being ironed', body: `Order ${n} is being processed.` }),
  [OrderStatus.READY_FOR_DELIVERY]: (n) => ({ title: 'Ready for delivery', body: `Order ${n} is ready and will be delivered in your slot.` }),
  [OrderStatus.OUT_FOR_DELIVERY]: (n) => ({ title: 'Out for delivery', body: `Order ${n} is on its way.` }),
  [OrderStatus.DELIVERED]: (n) => ({ title: 'Delivered', body: `Order ${n} has been delivered. Thank you!` }),
  [OrderStatus.CANCELLED]: (n) => ({ title: 'Order cancelled', body: `Order ${n} was cancelled.` }),
};

/**
 * Turns domain events into in-app notifications (inbox rows) and pushes.
 * Runs after the database commit; failures are logged, never thrown back.
 */
@Injectable()
export class NotificationsListener {
  private readonly logger = new Logger(NotificationsListener.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
  ) {}

  private async inboxAndPush(
    userIds: string[],
    type: string,
    title: string,
    body: string,
    data: Record<string, string>,
    app: ClientApp,
  ): Promise<void> {
    if (userIds.length === 0) return;
    await this.prisma.notification.createMany({ data: userIds.map((userId) => ({ userId, type, title, body, data })) });
    await this.push.send(userIds, { title, body, data: { type, ...data } }, app);
  }

  private async adminIds(): Promise<string[]> {
    const admins = await this.prisma.user.findMany({
      where: { role: { in: [Role.ADMIN, Role.SUPER_ADMIN] }, isActive: true, deletedAt: null },
      select: { id: true },
    });
    return admins.map((a) => a.id);
  }

  @OnEvent(Events.OrderCreated, { async: true, suppressErrors: true })
  async orderCreated(e: OrderCreatedEvent): Promise<void> {
    try {
      const data = { orderId: e.orderId, orderNumber: e.orderNumber };
      await this.inboxAndPush([e.customerId], 'order_placed', 'Order placed', `Order ${e.orderNumber} is confirmed. We will assign a pickup partner soon.`, data, ClientApp.CUSTOMER);
      await this.inboxAndPush(await this.adminIds(), 'new_order', 'New order', `Order ${e.orderNumber} was just placed.`, data, ClientApp.ADMIN);
    } catch (err) {
      this.logger.error(err);
    }
  }

  @OnEvent(Events.OrderStatusChanged, { async: true, suppressErrors: true })
  async statusChanged(e: OrderStatusChangedEvent): Promise<void> {
    try {
      const copy = CUSTOMER_COPY[e.to];
      // An unassignment back to READY_FOR_DELIVERY is internal; don't repeat "ready" to the customer.
      const internal = e.to === OrderStatus.READY_FOR_DELIVERY && e.from !== OrderStatus.PROCESSING;
      if (copy && !internal && e.actorRole !== Role.CUSTOMER) {
        const { title, body } = copy(e.orderNumber);
        await this.inboxAndPush([e.customerId], 'order_status', title, body, { orderId: e.orderId, status: e.to }, ClientApp.CUSTOMER);
      }
      if (e.to === OrderStatus.CANCELLED) {
        const drivers = [e.pickupDriverId, e.deliveryDriverId].filter((d): d is string => d !== null);
        await this.inboxAndPush(drivers, 'order_cancelled', 'Order cancelled', `Order ${e.orderNumber} was cancelled.`, { orderId: e.orderId }, ClientApp.PARTNER);
      }
      // Cancelling does not move money by itself: staff refund from the order page, so tell them it is owed.
      const owed = e.paidPaise - e.refundedPaise;
      if (e.to === OrderStatus.CANCELLED && owed > 0) {
        await this.inboxAndPush(
          await this.adminIds(),
          'refund_needed',
          'Refund needed',
          `Order ${e.orderNumber} was cancelled after ${rupees(owed)} was paid. Refund it from the order page.`,
          { orderId: e.orderId },
          ClientApp.ADMIN,
        );
      }
      if (e.removedDriverId) {
        await this.inboxAndPush([e.removedDriverId], 'task_removed', 'Task removed', `Order ${e.orderNumber} is no longer assigned to you.`, { orderId: e.orderId }, ClientApp.PARTNER);
      }
      // Admin assigned a driver directly (no offer): tell the driver.
      const assigned =
        e.to === OrderStatus.PICKUP_ASSIGNED ? e.pickupDriverId : e.to === OrderStatus.DELIVERY_ASSIGNED ? e.deliveryDriverId : null;
      if (assigned && e.actorRole !== Role.DRIVER) {
        await this.inboxAndPush([assigned], 'task_assigned', 'New task assigned', `You have been assigned order ${e.orderNumber}.`, { orderId: e.orderId }, ClientApp.PARTNER);
      }
    } catch (err) {
      this.logger.error(err);
    }
  }

  /** Offer pushes are urgent and not stored in the inbox (they expire in seconds). */
  @OnEvent(Events.OffersCreated, { async: true, suppressErrors: true })
  async offersCreated(e: OffersCreatedEvent): Promise<void> {
    const leg = e.leg === DispatchLeg.PICKUP ? 'pickup' : 'delivery';
    await Promise.all(
      e.offers.map((o) =>
        this.push.send(
          [o.driverId],
          {
            title: `New ${leg} request`,
            body: `Order ${e.orderNumber}. Tap to accept before it expires.`,
            data: { type: 'order_offer', offerId: o.offerId, orderId: e.orderId, expiresAt: o.expiresAt.toISOString() },
            urgent: true,
          },
          ClientApp.PARTNER,
        ),
      ),
    ).catch((err) => this.logger.error(err));
  }

  @OnEvent(Events.DispatchFailed, { async: true, suppressErrors: true })
  async dispatchFailed(e: DispatchFailedEvent): Promise<void> {
    try {
      const leg = e.leg === DispatchLeg.PICKUP ? 'pickup' : 'delivery';
      await this.inboxAndPush(await this.adminIds(), 'dispatch_failed', 'No partner available', `No partner accepted the ${leg} for order ${e.orderNumber}. Assign one manually.`, { orderId: e.orderId }, ClientApp.ADMIN);
    } catch (err) {
      this.logger.error(err);
    }
  }

  private async refundToCustomer(stage: RefundStage, e: RefundCreatedEvent | RefundProcessedEvent | RefundFailedEvent): Promise<void> {
    const { type, title, body } = refundCopy({ stage, method: e.method, amountPaise: e.amountPaise, orderNumber: e.orderNumber, note: e.note });
    await this.inboxAndPush([e.customerId], type, title, body, { orderId: e.orderId, orderNumber: e.orderNumber }, ClientApp.CUSTOMER);
  }

  @OnEvent(Events.RefundCreated, { async: true, suppressErrors: true })
  async refundCreated(e: RefundCreatedEvent): Promise<void> {
    await this.refundToCustomer('created', e).catch((err) => this.logger.error(err));
  }

  @OnEvent(Events.RefundProcessed, { async: true, suppressErrors: true })
  async refundProcessed(e: RefundProcessedEvent): Promise<void> {
    await this.refundToCustomer('processed', e).catch((err) => this.logger.error(err));
  }

  @OnEvent(Events.RefundFailed, { async: true, suppressErrors: true })
  async refundFailed(e: RefundFailedEvent): Promise<void> {
    try {
      await this.refundToCustomer('failed', e);
      // Staff need to return the money some other way.
      await this.inboxAndPush(
        await this.adminIds(),
        'refund_failed',
        'Refund failed',
        `Refund of ${rupees(e.amountPaise)} for order ${e.orderNumber} failed: ${e.failureReason}. Return it another way.`,
        { orderId: e.orderId },
        ClientApp.ADMIN,
      );
    } catch (err) {
      this.logger.error(err);
    }
  }

  @OnEvent(Events.PaymentCaptured, { async: true, suppressErrors: true })
  async paymentCaptured(e: PaymentCapturedEvent): Promise<void> {
    try {
      await this.inboxAndPush([e.customerId], 'payment_received', 'Payment received', `${rupees(e.amountPaise)} received for order ${e.orderNumber}.`, { orderId: e.orderId }, ClientApp.CUSTOMER);
    } catch (err) {
      this.logger.error(err);
    }
  }
}
