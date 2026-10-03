import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { AddressesModule } from './addresses/addresses.module.js';
import { AdminModule } from './admin/admin.module.js';
import { AppVersionsModule } from './app-versions/app-versions.controller.js';
import { AuditModule } from './audit/audit.service.js';
import { AuthGuard } from './auth/auth.guard.js';
import { AuthModule } from './auth/auth.module.js';
import { BannersModule } from './banners/banners.controller.js';
import { CatalogModule } from './catalog/catalog.module.js';
import { APP_ENV, ConfigModule } from './config/config.module.js';
import type { Env } from './config/env.js';
import { DriversModule } from './drivers/drivers.module.js';
import { HealthController } from './health/health.controller.js';
import { JobsModule } from './jobs/jobs.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { PaymentsModule } from './payments/payments.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { PromotionsModule } from './promotions/promotions.module.js';
import { RealtimeGateway } from './realtime/realtime.gateway.js';
import { SettingsModule } from './settings/settings.module.js';
import { UploadsModule } from './uploads/uploads.controller.js';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [
    ConfigModule,
    LoggerModule.forRootAsync({
      inject: [APP_ENV],
      useFactory: (env: Env) => ({
        pinoHttp: {
          level: env.LOG_LEVEL,
          redact: ['req.headers.authorization', 'req.headers.cookie'],
          transport:
            env.NODE_ENV === 'development' ? { target: 'pino-pretty', options: { singleLine: true } } : undefined,
          autoLogging: { ignore: (req) => req.url?.startsWith('/v1/health') ?? false },
          serializers: {
            req: (req: { id: unknown; method: string; url: string }) => ({ id: req.id, method: req.method, url: req.url }),
            res: (res: { statusCode: number }) => ({ statusCode: res.statusCode }),
          },
        },
      }),
    }),
    EventEmitterModule.forRoot(),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 300 }]),
    PrismaModule,
    AuditModule,
    JobsModule,
    AuthModule,
    SettingsModule,
    UsersModule,
    AddressesModule,
    CatalogModule,
    PromotionsModule,
    BannersModule,
    AppVersionsModule,
    OrdersModule,
    PaymentsModule,
    DriversModule,
    NotificationsModule,
    AdminModule,
    UploadsModule,
  ],
  controllers: [HealthController],
  providers: [
    RealtimeGateway,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: AuthGuard },
  ],
})
export class AppModule {}
