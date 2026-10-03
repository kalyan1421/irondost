import { randomUUID } from 'node:crypto';
import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { rupees } from '../common/money.js';
import { Events, type RefundCreatedEvent, type RefundFailedEvent, type RefundProcessedEvent } from '../events.js';
import type { Order, Prisma, User } from '../generated/prisma/client.js';
import { PaymentProvider, PaymentRecordStatus, RefundMethod, RefundStatus } from '../generated/prisma/enums.js';
import type { OrderWithRelations } from '../orders/order.dto.js';
import { ORDER_INCLUDE, orderRef } from '../orders/orders.service.js';
import { paymentStatusFor } from '../orders/pricing.js';
import { PrismaService, type Tx } from '../prisma/prisma.service.js';
import { RazorpayGateway } from './razorpay.gateway.js';
import { onlineRefundable, splitRefund } from './refund-split.js';

export interface RefundRequest {
  amountPaise: number;
  method: RefundMethod;
  note: string;
}

export interface RefundOutcome {
  order: OrderWithRelations;
  refundIds: string[];
  /** What was actually refunded; less than requested only when Razorpay refused part of a split refund. */
  refundedPaise: number;
  /** Set when Razorpay refused a later part of a split refund after an earlier part went through. */
  gatewayError: string | null;
}

/** `payload.refund.entity` of a Razorpay refund.* webhook. */
export interface RazorpayRefundEntity {
  id: string;
  payment_id?: string;
  amount?: number;
  status?: string;
}

/** Refunds that count toward orders.refunded_paise. */
const COUNTED: RefundStatus[] = [RefundStatus.PENDING, RefundStatus.PROCESSED];

/** Interactive transaction budget: Razorpay is called while the order row is locked. */
const REFUND_TX_TIMEOUT_MS = 60_000;

const FAILED_AT_GATEWAY = 'Razorpay could not complete the refund';

export const gatewayError = (message: string): AppError =>
  new AppError(HttpStatus.BAD_GATEWAY, 'REFUND_GATEWAY_ERROR', message);

/** Locks the order row for the rest of the transaction, so concurrent refunds see each other. */
async function lockOrder(tx: Tx, orderId: string): Promise<Order> {
  const rows = await tx.$queryRaw<{ id: string }[]>`SELECT id FROM orders WHERE id = ${orderId}::uuid FOR UPDATE`;
  if (rows.length === 0) throw AppError.notFound('Order');
  return tx.order.findUniqueOrThrow({ where: { id: orderId } });
}

@Injectable()
export class RefundsService {
  private readonly logger = new Logger(RefundsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly razorpay: RazorpayGateway,
    private readonly events: EventEmitter2,
    private readonly clock: Clock,
  ) {}

  /**
   * Staff refund money on an order. Razorpay refunds are sent to the gateway
   * while the order row is locked: if Razorpay refuses, nothing is saved.
   */
  async refund(orderId: string, req: RefundRequest, staff: User): Promise<RefundOutcome> {
    const note = req.note.trim();
    if (req.method === RefundMethod.RAZORPAY && !this.razorpay.isConfigured()) {
      throw new AppError(HttpStatus.SERVICE_UNAVAILABLE, 'PAYMENTS_UNAVAILABLE', 'Online refunds are not available right now');
    }

    // Razorpay refunds that went through; logged if the save fails so they can be reconciled.
    const sent: string[] = [];
    let result: { order: OrderWithRelations; rows: Prisma.RefundCreateManyInput[]; gatewayError: string | null };
    try {
      result = await this.prisma.$transaction(
        async (tx) => {
          const order = await lockOrder(tx, orderId);
          const refundable = order.paidPaise - order.refundedPaise;
          if (refundable <= 0) {
            throw AppError.conflict(
              'NOTHING_TO_REFUND',
              order.paidPaise > 0 ? 'Everything paid on this order has already been refunded' : 'Nothing has been paid on this order',
              { refundablePaise: 0 },
            );
          }
          if (req.amountPaise > refundable) {
            throw AppError.conflict('REFUND_EXCEEDS_PAID', `Only ${rupees(refundable)} can be refunded on this order`, {
              refundablePaise: refundable,
            });
          }

          const now = this.clock.now();
          let rows: Prisma.RefundCreateManyInput[];
          let gatewayError: string | null = null;
          if (req.method === RefundMethod.RAZORPAY) {
            ({ rows, gatewayError } = await this.sendToRazorpay(tx, order, req.amountPaise, note, staff, now, sent));
          } else {
            // Cash / bank transfer: staff already returned the money.
            rows = [
              {
                id: randomUUID(),
                orderId,
                method: req.method,
                status: RefundStatus.PROCESSED,
                amountPaise: req.amountPaise,
                note,
                createdById: staff.id,
                processedAt: now,
                createdAt: now,
              },
            ];
          }

          await tx.refund.createMany({ data: rows });
          const refundedPaise = order.refundedPaise + rows.reduce((sum, r) => sum + r.amountPaise, 0);
          const updated = await tx.order.update({
            where: { id: orderId },
            data: { refundedPaise, paymentStatus: paymentStatusFor(order.totalPaise, order.paidPaise, refundedPaise) },
            include: { ...ORDER_INCLUDE, events: { orderBy: { createdAt: 'asc' } } },
          });
          return { order: updated, rows, gatewayError };
        },
        { timeout: REFUND_TX_TIMEOUT_MS },
      );
    } catch (err) {
      if (sent.length) {
        this.logger.error(`Razorpay refunds ${sent.join(', ')} for order ${orderId} were sent but not saved: ${String(err)}`);
      }
      throw err;
    }

    const { order, rows } = result;
    const refundedPaise = rows.reduce((sum, r) => sum + r.amountPaise, 0);
    const refundIds = rows.map((r) => r.id!);
    this.events.emit(Events.RefundCreated, {
      ...orderRef(order),
      refundIds,
      amountPaise: refundedPaise,
      method: req.method,
      status: rows.some((r) => r.status === RefundStatus.PENDING) ? RefundStatus.PENDING : RefundStatus.PROCESSED,
      note,
    } satisfies RefundCreatedEvent);
    return { order, refundIds, refundedPaise, gatewayError: result.gatewayError };
  }

  /**
   * Refunds captured Razorpay payments, newest first. Throws (rolling back) if
   * Razorpay refuses the first part; a refusal after that returns what went through.
   */
  private async sendToRazorpay(
    tx: Tx,
    order: Order,
    amountPaise: number,
    note: string,
    staff: User,
    now: Date,
    sent: string[],
  ): Promise<{ rows: Prisma.RefundCreateManyInput[]; gatewayError: string | null }> {
    const payments = await tx.payment.findMany({
      where: {
        orderId: order.id,
        provider: PaymentProvider.RAZORPAY,
        status: PaymentRecordStatus.CAPTURED,
        razorpayPaymentId: { not: null },
      },
    });
    if (payments.length === 0) {
      throw AppError.conflict('NO_ONLINE_PAYMENT', 'This order has no online payment to refund. Choose cash or bank transfer.');
    }
    const used = await tx.refund.groupBy({
      by: ['paymentId'],
      where: { paymentId: { in: payments.map((p) => p.id) }, status: { in: COUNTED } },
      _sum: { amountPaise: true },
    });
    const usedBy = new Map(used.map((u) => [u.paymentId, u._sum.amountPaise ?? 0]));
    const refundable = payments.map((p) => ({
      id: p.id,
      razorpayPaymentId: p.razorpayPaymentId!,
      amountPaise: p.amountPaise,
      refundedPaise: usedBy.get(p.id) ?? 0,
      createdAt: p.createdAt,
    }));
    const parts = splitRefund(amountPaise, refundable);
    if (!parts) {
      const online = onlineRefundable(refundable);
      throw AppError.conflict(
        'REFUND_EXCEEDS_ONLINE_PAID',
        online > 0
          ? `Only ${rupees(online)} can go back through Razorpay. Refund the rest by cash or bank transfer.`
          : 'The online payments on this order have already been refunded. Choose cash or bank transfer.',
        { refundablePaise: online },
      );
    }

    const rows: Prisma.RefundCreateManyInput[] = [];
    let refused: string | null = null;
    for (const part of parts) {
      const id = randomUUID();
      try {
        const reply = await this.razorpay.refund(part.razorpayPaymentId, part.amountPaise, {
          orderId: order.id,
          orderNumber: order.orderNumber,
          refundId: id,
        });
        if (reply.status === 'failed') {
          refused = 'Razorpay declined the refund';
          break;
        }
        sent.push(reply.id);
        const processed = reply.status === 'processed';
        rows.push({
          id,
          // Parts of one split refund share a moment; a millisecond apart keeps them in the order they were sent.
          createdAt: new Date(now.getTime() + rows.length),
          orderId: order.id,
          paymentId: part.paymentId,
          method: RefundMethod.RAZORPAY,
          status: processed ? RefundStatus.PROCESSED : RefundStatus.PENDING,
          amountPaise: part.amountPaise,
          note,
          razorpayRefundId: reply.id,
          createdById: staff.id,
          processedAt: processed ? now : null,
        });
      } catch (err) {
        refused = err instanceof Error ? err.message : String(err);
        break;
      }
    }
    if (rows.length === 0) throw gatewayError(refused ?? 'Razorpay could not refund this payment');
    return { rows, gatewayError: refused };
  }

  /** Razorpay refund.processed / refund.failed webhooks. Idempotent. */
  async handleWebhook(event: string, entity: RazorpayRefundEntity): Promise<void> {
    if (event !== 'refund.processed' && event !== 'refund.failed') return;
    const refund = await this.prisma.refund.findUnique({ where: { razorpayRefundId: entity.id } });
    if (!refund) {
      this.logger.warn(`Webhook ${event} for unknown Razorpay refund ${entity.id}`);
      return;
    }

    if (event === 'refund.processed') {
      const res = await this.prisma.refund.updateMany({
        where: { id: refund.id, status: RefundStatus.PENDING },
        data: { status: RefundStatus.PROCESSED, processedAt: this.clock.now() },
      });
      if (res.count === 0) return;
      const order = await this.prisma.order.findUniqueOrThrow({ where: { id: refund.orderId } });
      this.events.emit(Events.RefundProcessed, {
        ...orderRef(order),
        refundIds: [refund.id],
        amountPaise: refund.amountPaise,
        method: refund.method,
        note: refund.note,
      } satisfies RefundProcessedEvent);
      return;
    }

    // refund.failed: the money never left, so it no longer counts as refunded.
    const order = await this.prisma.$transaction(async (tx) => {
      const locked = await lockOrder(tx, refund.orderId);
      const res = await tx.refund.updateMany({
        where: { id: refund.id, status: { in: COUNTED } },
        data: { status: RefundStatus.FAILED, failureReason: FAILED_AT_GATEWAY },
      });
      if (res.count === 0) return null;
      const refundedPaise = locked.refundedPaise - refund.amountPaise;
      return tx.order.update({
        where: { id: locked.id },
        data: { refundedPaise, paymentStatus: paymentStatusFor(locked.totalPaise, locked.paidPaise, refundedPaise) },
      });
    });
    if (!order) return;
    this.events.emit(Events.RefundFailed, {
      ...orderRef(order),
      refundIds: [refund.id],
      amountPaise: refund.amountPaise,
      method: refund.method,
      note: refund.note,
      failureReason: FAILED_AT_GATEWAY,
    } satisfies RefundFailedEvent);
  }
}
