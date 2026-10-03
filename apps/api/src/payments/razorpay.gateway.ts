import { Inject, Injectable } from '@nestjs/common';
import Razorpay from 'razorpay';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';

export interface GatewayRefund {
  id: string;
  status: 'pending' | 'processed' | 'failed';
}

/** The slice of Razorpay we use. Abstract so tests can substitute a fake. */
export abstract class RazorpayGateway {
  abstract readonly keyId: string;
  abstract readonly keySecret: string;
  abstract readonly webhookSecret: string;
  abstract isConfigured(): boolean;
  abstract createOrder(amountPaise: number, receipt: string, notes: Record<string, string>): Promise<{ id: string }>;
  /** Refunds part or all of a captured payment. Throws with Razorpay's own message when it refuses. */
  abstract refund(paymentId: string, amountPaise: number, notes: Record<string, string>): Promise<GatewayRefund>;
}

const RAZORPAY_API = 'https://api.razorpay.com/v1';
const REFUND_TIMEOUT_MS = 15_000;

@Injectable()
export class RazorpaySdkGateway extends RazorpayGateway {
  readonly keyId: string;
  readonly keySecret: string;
  readonly webhookSecret: string;
  private readonly client: Razorpay | null;

  constructor(@Inject(APP_ENV) env: Env) {
    super();
    this.keyId = env.RAZORPAY_KEY_ID;
    this.keySecret = env.RAZORPAY_KEY_SECRET;
    this.webhookSecret = env.RAZORPAY_WEBHOOK_SECRET;
    this.client = this.keyId && this.keySecret ? new Razorpay({ key_id: this.keyId, key_secret: this.keySecret }) : null;
  }

  isConfigured(): boolean {
    return this.client !== null;
  }

  async createOrder(amountPaise: number, receipt: string, notes: Record<string, string>): Promise<{ id: string }> {
    if (!this.client) throw new Error('Razorpay is not configured');
    const order = await this.client.orders.create({ amount: amountPaise, currency: 'INR', receipt, notes });
    return { id: order.id };
  }

  async refund(paymentId: string, amountPaise: number, notes: Record<string, string>): Promise<GatewayRefund> {
    if (!this.client) throw new Error('Razorpay is not configured');
    let res: Response;
    try {
      res = await fetch(`${RAZORPAY_API}/payments/${encodeURIComponent(paymentId)}/refund`, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(`${this.keyId}:${this.keySecret}`).toString('base64')}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ amount: amountPaise, speed: 'normal', notes }),
        signal: AbortSignal.timeout(REFUND_TIMEOUT_MS),
      });
    } catch (err) {
      const timedOut = err instanceof Error && err.name === 'TimeoutError';
      throw new Error(timedOut ? 'Razorpay did not respond in time' : 'Could not reach Razorpay', { cause: err });
    }
    const body = (await res.json().catch(() => null)) as {
      id?: string;
      status?: string;
      error?: { description?: string };
    } | null;
    if (!res.ok) throw new Error(body?.error?.description || `Razorpay refused the refund (HTTP ${res.status})`);
    if (!body?.id) throw new Error('Razorpay sent an unexpected reply');
    const status = body.status === 'processed' || body.status === 'failed' ? body.status : 'pending';
    return { id: body.id, status };
  }
}
