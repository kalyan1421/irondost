import { JobScheduler, type JobHandler, type ScheduleOptions } from '../src/jobs/job-scheduler.js';
import { RazorpayGateway, type GatewayRefund } from '../src/payments/razorpay.gateway.js';

interface QueuedJob {
  queue: string;
  data: object;
  startAfter?: Date;
}

/** In-memory jobs: tests decide when queued work runs, ignoring start times. */
export class MemoryScheduler extends JobScheduler {
  private readonly handlers = new Map<string, JobHandler<object>>();
  readonly queued: QueuedJob[] = [];

  register<T extends object>(queue: string, handler: JobHandler<T>): void {
    this.handlers.set(queue, handler as JobHandler<object>);
  }

  async schedule<T extends object>(queue: string, data: T, options: ScheduleOptions = {}): Promise<void> {
    this.queued.push({ queue, data, startAfter: options.startAfter });
  }

  has(queue: string, match: (data: Record<string, unknown>) => boolean = () => true): boolean {
    return this.queued.some((j) => j.queue === queue && match(j.data as Record<string, unknown>));
  }

  /** Runs (and removes) every queued job of `queue` matching `match`. */
  async run(queue: string, match: (data: Record<string, unknown>) => boolean = () => true): Promise<number> {
    const jobs = this.queued.filter((j) => j.queue === queue && match(j.data as Record<string, unknown>));
    for (const job of jobs) this.queued.splice(this.queued.indexOf(job), 1);
    for (const job of jobs) await this.handlers.get(queue)!(job.data);
    return jobs.length;
  }

  clear(): void {
    this.queued.length = 0;
  }
}

type RefundOutcome = GatewayRefund['status'] | Error;

export class FakeRazorpay extends RazorpayGateway {
  readonly keyId = 'rzp_test_key';
  readonly keySecret = 'rzp_test_secret';
  readonly webhookSecret = 'rzp_webhook_secret';
  private n = 0;
  /** Every refund Razorpay accepted, in call order. */
  readonly refunds: { id: string; paymentId: string; amountPaise: number; notes: Record<string, string> }[] = [];
  private readonly refundOutcomes: RefundOutcome[] = [];

  isConfigured(): boolean {
    return true;
  }

  async createOrder(): Promise<{ id: string }> {
    this.n += 1;
    return { id: `order_test_${this.n}` };
  }

  /**
   * Decides how the next refund calls go, one outcome per call: a status to
   * reply with, or an Error to throw (Razorpay refusing). Unqueued calls are processed.
   */
  queueRefunds(...outcomes: RefundOutcome[]): void {
    this.refundOutcomes.push(...outcomes);
  }

  async refund(paymentId: string, amountPaise: number, notes: Record<string, string>): Promise<GatewayRefund> {
    const outcome = this.refundOutcomes.shift() ?? 'processed';
    if (outcome instanceof Error) throw outcome;
    this.n += 1;
    const id = `rfnd_test_${this.n}`;
    this.refunds.push({ id, paymentId, amountPaise, notes });
    return { id, status: outcome };
  }
}

/** Polls until `check` passes (event listeners run after the HTTP response). */
export async function waitFor(check: () => boolean | Promise<boolean>, timeoutMs = 3000): Promise<void> {
  const start = Date.now();
  while (!(await check())) {
    if (Date.now() - start > timeoutMs) throw new Error('waitFor timed out');
    await new Promise((r) => setTimeout(r, 20));
  }
}
