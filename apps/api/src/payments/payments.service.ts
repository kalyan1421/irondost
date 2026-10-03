import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { AppError } from '../common/errors.js';
import { Events, type PaymentCapturedEvent } from '../events.js';
import type { Payment, Prisma, User } from '../generated/prisma/client.js';
import { OrderStatus, PaymentProvider, PaymentRecordStatus } from '../generated/prisma/enums.js';
import { orderRef } from '../orders/orders.service.js';
import { paymentStatusFor } from '../orders/pricing.js';
import { PrismaService, type Tx } from '../prisma/prisma.service.js';
import { RazorpayGateway } from './razorpay.gateway.js';
import { verifyPaymentSignature, verifyWebhookSignature } from './razorpay-signature.js';
import { RefundsService, type RazorpayRefundEntity } from './refunds.service.js';

export interface CheckoutParams {
  keyId: string;
  razorpayOrderId: string;
  amountPaise: number;
  currency: 'INR';
  orderNumber: string;
  prefill: { name: string | null; contact: string; email: string | null };
}

interface RazorpayWebhook {
  event: string;
  payload?: {
    payment?: { entity?: { id: string; order_id: string; amount: number; status: string } };
    refund?: { entity?: RazorpayRefundEntity };
  };
}

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly razorpay: RazorpayGateway,
    private readonly events: EventEmitter2,
    private readonly refunds: RefundsService,
  ) {}

  private requireRazorpay(): void {
    if (!this.razorpay.isConfigured()) {
      throw new AppError(HttpStatus.SERVICE_UNAVAILABLE, 'PAYMENTS_UNAVAILABLE', 'Online payment is not available right now');
    }
  }

  /** Starts an online payment for whatever is still due on the order. */
  async createRazorpayOrder(customer: User, orderId: string): Promise<CheckoutParams> {
    this.requireRazorpay();
    const order = await this.prisma.order.findFirst({ where: { id: orderId, customerId: customer.id } });
    if (!order) throw AppError.notFound('Order');
    if (order.status === OrderStatus.CANCELLED) throw AppError.conflict('ORDER_CANCELLED', 'This order was cancelled');
    const due = order.totalPaise - order.paidPaise;
    if (due <= 0) throw AppError.conflict('NOTHING_DUE', 'This order is already paid');

    const rp = await this.razorpay.createOrder(due, order.orderNumber, { orderId: order.id });
    await this.prisma.payment.create({
      data: {
        orderId: order.id,
        provider: PaymentProvider.RAZORPAY,
        status: PaymentRecordStatus.CREATED,
        amountPaise: due,
        razorpayOrderId: rp.id,
      },
    });
    return {
      keyId: this.razorpay.keyId,
      razorpayOrderId: rp.id,
      amountPaise: due,
      currency: 'INR',
      orderNumber: order.orderNumber,
      prefill: { name: customer.name, contact: customer.phone, email: customer.email },
    };
  }

  /** Checkout success callback from the app. The webhook confirms the same payment independently. */
  async verifyCheckout(
    customer: User,
    razorpayOrderId: string,
    razorpayPaymentId: string,
    signature: string,
  ): Promise<{ paymentStatus: string }> {
    this.requireRazorpay();
    const payment = await this.prisma.payment.findUnique({
      where: { razorpayOrderId },
      include: { order: true },
    });
    if (!payment || payment.order.customerId !== customer.id) throw AppError.notFound('Payment');
    if (!verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, signature, this.razorpay.keySecret)) {
      throw AppError.badRequest('INVALID_SIGNATURE', 'Payment could not be verified');
    }
    const order = await this.capture(payment, razorpayPaymentId, payment.amountPaise, { source: 'checkout' });
    return { paymentStatus: order.paymentStatus };
  }

  /** Razorpay webhook. Returns true when the signature is valid (the event may still be ignored). */
  async handleWebhook(rawBody: Buffer | undefined, signature: string | undefined): Promise<boolean> {
    if (!rawBody || !signature || !this.razorpay.webhookSecret) return false;
    if (!verifyWebhookSignature(rawBody, signature, this.razorpay.webhookSecret)) return false;

    const body = JSON.parse(rawBody.toString('utf8')) as RazorpayWebhook;
    // Refund events also carry the payment; they are about the refund.
    if (body.event.startsWith('refund.')) {
      const refund = body.payload?.refund?.entity;
      if (refund) await this.refunds.handleWebhook(body.event, refund);
      return true;
    }
    const entity = body.payload?.payment?.entity;
    if (!entity) return true;
    const payment = await this.prisma.payment.findUnique({ where: { razorpayOrderId: entity.order_id } });
    if (!payment) {
      this.logger.warn(`Webhook ${body.event} for unknown Razorpay order ${entity.order_id}`);
      return true;
    }
    if (body.event === 'payment.captured') {
      await this.capture(payment, entity.id, entity.amount, body as unknown as Prisma.InputJsonValue);
    } else if (body.event === 'payment.failed') {
      await this.prisma.payment.updateMany({
        where: { id: payment.id, status: PaymentRecordStatus.CREATED },
        data: { status: PaymentRecordStatus.FAILED, razorpayPaymentId: entity.id, raw: body as unknown as Prisma.InputJsonValue },
      });
    }
    return true;
  }

  /** Idempotent: capturing an already-captured payment changes nothing. */
  private async capture(payment: Payment, razorpayPaymentId: string, amountPaise: number, raw: Prisma.InputJsonValue) {
    const result = await this.prisma.$transaction(async (tx) => {
      const res = await tx.payment.updateMany({
        where: { id: payment.id, status: { in: [PaymentRecordStatus.CREATED, PaymentRecordStatus.FAILED] } },
        data: { status: PaymentRecordStatus.CAPTURED, razorpayPaymentId, amountPaise, raw },
      });
      if (res.count === 0) {
        return { order: await tx.order.findUniqueOrThrow({ where: { id: payment.orderId } }), captured: false };
      }
      return { order: await this.addPaid(tx, payment.orderId, amountPaise), captured: true };
    });
    if (result.captured) {
      this.events.emit(Events.PaymentCaptured, {
        ...orderRef(result.order),
        amountPaise,
        provider: 'RAZORPAY',
      } satisfies PaymentCapturedEvent);
    }
    return result.order;
  }

  /**
   * Records cash for whatever is still due, inside the caller's transaction
   * (used when a driver marks an order delivered). Returns the amount recorded.
   */
  async recordCashInTx(tx: Tx, orderId: string, collectedById: string): Promise<number> {
    const order = await tx.order.findUniqueOrThrow({ where: { id: orderId } });
    const due = order.totalPaise - order.paidPaise;
    if (due <= 0) return 0;
    await tx.payment.create({
      data: {
        orderId,
        provider: PaymentProvider.CASH,
        status: PaymentRecordStatus.CAPTURED,
        amountPaise: due,
        collectedById,
      },
    });
    await this.addPaid(tx, orderId, due);
    return due;
  }

  /** Admin records a cash payment taken outside the delivery flow. */
  async recordCash(orderId: string, amountPaise: number, collectedBy: User): Promise<void> {
    const order = await this.prisma.$transaction(async (tx) => {
      const current = await tx.order.findUnique({ where: { id: orderId } });
      if (!current) throw AppError.notFound('Order');
      if (amountPaise > current.totalPaise - current.paidPaise) {
        throw AppError.badRequest('OVERPAYMENT', 'Amount is more than what is due');
      }
      await tx.payment.create({
        data: {
          orderId,
          provider: PaymentProvider.CASH,
          status: PaymentRecordStatus.CAPTURED,
          amountPaise,
          collectedById: collectedBy.id,
        },
      });
      return this.addPaid(tx, orderId, amountPaise);
    });
    this.events.emit(Events.PaymentCaptured, {
      ...orderRef(order),
      amountPaise,
      provider: 'CASH',
    } satisfies PaymentCapturedEvent);
  }

  listForOrder(orderId: string): Promise<Payment[]> {
    return this.prisma.payment.findMany({ where: { orderId }, orderBy: { createdAt: 'asc' } });
  }

  private async addPaid(tx: Tx, orderId: string, amountPaise: number) {
    const updated = await tx.order.update({
      where: { id: orderId },
      data: { paidPaise: { increment: amountPaise } },
    });
    return tx.order.update({
      where: { id: orderId },
      data: { paymentStatus: paymentStatusFor(updated.totalPaise, updated.paidPaise, updated.refundedPaise) },
    });
  }
}
