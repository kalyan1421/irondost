import { Global, Injectable, Logger, Module } from '@nestjs/common';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

/** Append-only record of admin actions (who changed what). Never blocks the request. */
@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private readonly prisma: PrismaService) {}

  log(actorId: string, action: string, entity: string, entityId: string | null, data?: unknown): void {
    this.prisma.auditLog
      .create({
        data: {
          actorId,
          action,
          entity,
          entityId,
          data: data === undefined ? undefined : (JSON.parse(JSON.stringify(data)) as Prisma.InputJsonValue),
        },
      })
      .catch((err: unknown) => this.logger.error(`Audit write failed for ${action}: ${String(err)}`));
  }
}

@Global()
@Module({ providers: [AuditService], exports: [AuditService] })
export class AuditModule {}
