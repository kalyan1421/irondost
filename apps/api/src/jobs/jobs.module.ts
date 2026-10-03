import { Global, Module } from '@nestjs/common';
import { JobScheduler } from './job-scheduler.js';
import { PgBossScheduler } from './pg-boss.scheduler.js';

@Global()
@Module({
  providers: [{ provide: JobScheduler, useClass: PgBossScheduler }],
  exports: [JobScheduler],
})
export class JobsModule {}
