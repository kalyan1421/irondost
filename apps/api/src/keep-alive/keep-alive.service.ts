import { Inject, Injectable, Logger, Module, OnApplicationBootstrap, OnApplicationShutdown } from '@nestjs/common';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import { PrismaService } from '../prisma/prisma.service.js';

const SERVICE_NAME = 'api';
/** Waking a sleeping Render service takes about a minute, so give each request longer than that. */
const PING_TIMEOUT_MS = 90_000;

/**
 * Keeps the free-tier hosts from going to sleep. On a timer it writes a heartbeat row (so Supabase sees
 * activity) and requests this service's own public address and each of KEEP_ALIVE_URLS (so Render sees traffic).
 * Off unless KEEP_ALIVE_INTERVAL_MINUTES is set. A failure is logged and never stops the service.
 */
@Injectable()
export class KeepAliveService implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(KeepAliveService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    private readonly prisma: PrismaService,
    @Inject(APP_ENV) private readonly env: Env,
  ) {}

  onApplicationBootstrap(): void {
    const minutes = this.env.KEEP_ALIVE_INTERVAL_MINUTES;
    if (minutes <= 0) return;
    this.timer = setInterval(() => void this.beat(), minutes * 60_000);
    this.timer.unref();
    void this.beat();
    this.logger.log(`Keep-alive every ${minutes} min: database plus ${this.targets().join(', ') || 'no addresses'}`);
  }

  onApplicationShutdown(): void {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  /** One beat. Skipped if the previous one is still waiting on a slow address. */
  async beat(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      await Promise.all([this.touchDatabase(), ...this.targets().map((url) => this.ping(url))]);
    } finally {
      this.running = false;
    }
  }

  private targets(): string[] {
    const own = this.env.RENDER_EXTERNAL_URL ? [`${this.env.RENDER_EXTERNAL_URL.replace(/\/$/, '')}/v1/health`] : [];
    return [...new Set([...own, ...this.env.KEEP_ALIVE_URLS])];
  }

  private async touchDatabase(): Promise<void> {
    const now = new Date();
    try {
      await this.prisma.serviceHeartbeat.upsert({
        where: { service: SERVICE_NAME },
        create: { service: SERVICE_NAME, beats: 1, lastBeatAt: now },
        update: { beats: { increment: 1 }, lastBeatAt: now },
      });
    } catch (err) {
      this.logger.warn(`Keep-alive database write failed: ${String(err)}`);
    }
  }

  private async ping(url: string): Promise<void> {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(PING_TIMEOUT_MS) });
      if (!res.ok) this.logger.warn(`Keep-alive ${url} answered ${res.status}`);
    } catch (err) {
      this.logger.warn(`Keep-alive ${url} failed: ${String(err)}`);
    }
  }
}

@Module({ providers: [KeepAliveService] })
export class KeepAliveModule {}
