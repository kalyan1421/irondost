import { Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { OnGatewayConnection, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';
import { TokenVerifier } from '../auth/token-verifier.js';
import {
  Events,
  type OffersClosedEvent,
  type OffersCreatedEvent,
  type OrderCreatedEvent,
  type OrderRef,
  type OrderStatusChangedEvent,
  type OrderUpdatedEvent,
  type PaymentCapturedEvent,
  type RefundCreatedEvent,
  type RefundFailedEvent,
  type RefundProcessedEvent,
} from '../events.js';
import { Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';

const ADMIN_ROOM = 'admins';
const userRoom = (id: string) => `user:${id}`;

/**
 * Live updates over Socket.IO at path /v1/realtime.
 * Connect with `auth: { token: <Firebase ID token> }`. Each socket joins its
 * user's room (and the admin room for staff). Events carry ids and the new
 * state; clients refetch details over REST when they need them.
 *
 * Server → client events:
 *   order.updated   { orderId, orderNumber, status?, reason }
 *                   reason: created | status_changed | items_changed | payment_changed | details_changed | refund_changed
 *   offer.created   { offerId, orderId, orderNumber, leg, expiresAt }
 *   offer.closed    { orderId, leg }
 */
@WebSocketGateway({ path: '/v1/realtime', cors: { origin: true, credentials: true } })
export class RealtimeGateway implements OnGatewayConnection {
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer() server!: Server;

  constructor(
    private readonly verifier: TokenVerifier,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(socket: Socket): Promise<void> {
    try {
      const token = (socket.handshake.auth as { token?: unknown }).token;
      if (typeof token !== 'string' || !token) throw new Error('missing token');
      const identity = await this.verifier.verify(token);
      const user = await this.prisma.user.findUnique({ where: { firebaseUid: identity.uid } });
      if (!user || !user.isActive || user.deletedAt) throw new Error('unknown or disabled user');
      await socket.join(userRoom(user.id));
      if (user.role === Role.ADMIN || user.role === Role.SUPER_ADMIN) await socket.join(ADMIN_ROOM);
    } catch (err) {
      this.logger.debug(`Rejected socket: ${String(err)}`);
      socket.emit('error', { code: 'UNAUTHORIZED' });
      socket.disconnect(true);
    }
  }

  private toOrderParties(ref: OrderRef, payload: object): void {
    const rooms = [ADMIN_ROOM, userRoom(ref.customerId)];
    if (ref.pickupDriverId) rooms.push(userRoom(ref.pickupDriverId));
    if (ref.deliveryDriverId) rooms.push(userRoom(ref.deliveryDriverId));
    this.server?.to(rooms).emit('order.updated', payload);
  }

  @OnEvent(Events.OrderCreated)
  onCreated(e: OrderCreatedEvent): void {
    this.toOrderParties(e, { orderId: e.orderId, orderNumber: e.orderNumber, status: e.status, reason: 'created' });
  }

  @OnEvent(Events.OrderStatusChanged)
  onStatus(e: OrderStatusChangedEvent): void {
    const payload = { orderId: e.orderId, orderNumber: e.orderNumber, status: e.to, reason: 'status_changed' };
    this.toOrderParties(e, payload);
    // A driver who was just unassigned also needs to drop the task.
    if (e.removedDriverId) this.server?.to(userRoom(e.removedDriverId)).emit('order.updated', payload);
  }

  @OnEvent(Events.OrderUpdated)
  onUpdated(e: OrderUpdatedEvent): void {
    this.toOrderParties(e, { orderId: e.orderId, orderNumber: e.orderNumber, reason: e.reason });
  }

  @OnEvent(Events.PaymentCaptured)
  onPayment(e: PaymentCapturedEvent): void {
    this.toOrderParties(e, { orderId: e.orderId, orderNumber: e.orderNumber, reason: 'payment_changed' });
  }

  @OnEvent(Events.RefundCreated)
  @OnEvent(Events.RefundProcessed)
  @OnEvent(Events.RefundFailed)
  onRefund(e: RefundCreatedEvent | RefundProcessedEvent | RefundFailedEvent): void {
    this.toOrderParties(e, { orderId: e.orderId, orderNumber: e.orderNumber, reason: 'refund_changed' });
  }

  @OnEvent(Events.OffersCreated)
  onOffers(e: OffersCreatedEvent): void {
    for (const o of e.offers) {
      this.server?.to(userRoom(o.driverId)).emit('offer.created', {
        offerId: o.offerId,
        orderId: e.orderId,
        orderNumber: e.orderNumber,
        leg: e.leg,
        expiresAt: o.expiresAt,
      });
    }
  }

  @OnEvent(Events.OffersClosed)
  onOffersClosed(e: OffersClosedEvent): void {
    if (e.driverIds.length === 0) return;
    this.server?.to(e.driverIds.map(userRoom)).emit('offer.closed', { orderId: e.orderId, leg: e.leg });
  }
}
