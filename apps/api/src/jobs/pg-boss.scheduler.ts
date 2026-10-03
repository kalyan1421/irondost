import { Inject, Injectable, Logger, OnApplicationBootstrap, OnApplicationShutdown } from '@nestjs/common';
import { PgBoss } from 'pg-boss';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import { JobScheduler, type JobHandler, type ScheduleOptions } from './job-scheduler.js';

/** pg-boss keeps jobs in the `pgboss` schema of the main database, so there is no Redis to run. */
@Injectable()
export class PgBossScheduler extends JobScheduler implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(PgBossScheduler.name);
  private readonly handlers = new Map<string, JobHandler<object>>();
  private boss: PgBoss | null = null;

  constructor(@Inject(APP_ENV) private readonly env: Env) {
    super();
  }

  register<T extends object>(queue: string, handler: JobHandler<T>): void {
    this.handlers.set(queue, handler as JobHandler<object>);
  }

  async onApplicationBootstrap(): Promise<void> {
    if (!this.env.JOBS_ENABLED) {
      this.logger.warn('Background jobs disabled (JOBS_ENABLED=false)');
      return;
    }
    const boss = new PgBoss({ connectionString: this.env.DATABASE_URL, schema: 'pgboss' });
    boss.on('error', (err: unknown) => this.logger.error(`pg-boss: ${String(err)}`));
    await boss.start();
    for (const [queue, handler] of this.handlers) {
      await boss.createQueue(queue);
      await boss.work<object>(queue, { pollingIntervalSeconds: 1 }, async (jobs) => {
        for (const job of jobs) await handler(job.data);
      });
    }
    this.boss = boss;
    this.logger.log(`Job workers started: ${[...this.handlers.keys()].join(', ')}`);
  }

  async onApplicationShutdown(): Promise<void> {
    await this.boss?.stop({ graceful: true, timeout: 10_000 });
  }

  async schedule<T extends object>(queue: string, data: T, options: ScheduleOptions = {}): Promise<void> {
    if (!this.boss) {
      this.logger.warn(`Job ${queue} dropped: job workers are not running`);
      return;
    }
    await this.boss.send(queue, data, {
      startAfter: options.startAfter,
      retryLimit: 3,
      retryDelay: 5,
    });
  }
}
