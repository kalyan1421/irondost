import { createHash } from 'node:crypto';
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { AuditService } from '../audit/audit.service.js';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { pageArgs } from '../common/pagination.js';
import { Events } from '../events.js';
import { Prisma, type User } from '../generated/prisma/client.js';
import { JobScheduler } from '../jobs/job-scheduler.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { SettingsService } from '../settings/settings.service.js';
import { FileStorage } from '../uploads/file-storage.js';
import type { CreateIssueDto, IssueDto, IssuesQuery, UpdateIssueDto } from './issue.dto.js';

const INCLUDE = {
  order: { select: { orderNumber: true } },
  messages: { orderBy: { createdAt: 'asc' } },
} as const satisfies Prisma.OrderIssueInclude;
type Case = Prisma.OrderIssueGetPayload<{ include: typeof INCLUDE }>;
const staff = (u: User) => u.role === 'ADMIN' || u.role === 'SUPER_ADMIN';
const closed = (status: string) => status === 'RESOLVED' || status === 'REJECTED';

@Injectable()
export class IssuesService implements OnModuleInit {
  private readonly logger = new Logger(IssuesService.name);
  constructor(
    private readonly prisma: PrismaService,
    private readonly settings: SettingsService,
    private readonly clock: Clock,
    private readonly jobs: JobScheduler,
    private readonly events: EventEmitter2,
    private readonly audit: AuditService,
    private readonly storage: FileStorage,
  ) {}

  async onModuleInit(): Promise<void> {
    this.jobs.register<{ issueId: string }>('issues-first-response', (data) => this.checkOverdue(data.issueId));
    const open = await this.prisma.orderIssue.findMany({
      where: { status: 'OPEN', firstResponseDueAt: { not: null }, overdueNotifiedAt: null },
    });
    for (const issue of open)
      await this.jobs.schedule(
        'issues-first-response',
        { issueId: issue.id },
        { startAfter: issue.firstResponseDueAt!, jobId: issue.id },
      );
  }

  private dto(issue: Case, user: User): IssueDto {
    return {
      id: issue.id,
      orderId: issue.orderId,
      orderNumber: issue.order.orderNumber,
      category: issue.category,
      status: issue.status,
      description: issue.description,
      photoUrls: issue.photoUrls,
      firstResponseDueAt: issue.firstResponseDueAt,
      acknowledgedAt: issue.acknowledgedAt,
      resolvedAt: issue.resolvedAt,
      resolutionNote: issue.resolutionNote,
      compensationPaise: issue.compensationPaise,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
      ...(staff(user) ? { handledById: issue.handledById, refundId: issue.refundId } : {}),
      messages: issue.messages.map((m) => ({ id: m.id, fromStaff: m.fromStaff, body: m.body, createdAt: m.createdAt })),
    };
  }

  private async ownPhotos(user: User, urls: string[]): Promise<void> {
    if (new Set(urls).size !== urls.length) throw AppError.badRequest('INVALID_PHOTO', 'Use each photo once.');
    const prefix = this.storage.publicUrl(`issues/${user.id}/`);
    for (const url of urls) {
      const name = url.startsWith(prefix) ? url.slice(prefix.length) : '';
      if (
        !/^[0-9a-f-]{36}\.webp$/.test(name) ||
        !(await this.prisma.issuePhoto.findFirst({ where: { userId: user.id, key: `issues/${user.id}/${name}` } }))
      ) {
        throw AppError.badRequest('INVALID_PHOTO', 'Use only photos uploaded from your own account.');
      }
    }
  }

  private changed(issue: Case, kind: 'created' | 'message' | 'updated' | 'overdue', fromStaff = false): void {
    this.events.emit(Events.IssueChanged, {
      issueId: issue.id,
      orderId: issue.orderId,
      orderNumber: issue.order.orderNumber,
      customerId: issue.customerId,
      status: issue.status,
      kind,
      fromStaff,
    });
  }

  private async priorAttempt(user: User, key: string, hash: string): Promise<IssueDto | null> {
    const prior = await this.prisma.orderIssue.findUnique({
      where: { customerId_requestKey: { customerId: user.id, requestKey: key } },
      include: INCLUDE,
    });
    if (!prior) return null;
    if (prior.requestHash !== hash)
      throw AppError.conflict('IDEMPOTENCY_KEY_REUSED', 'This report key belongs to different report details.');
    return this.dto(prior, user);
  }

  async create(
    user: User,
    orderId: string,
    body: CreateIssueDto,
    key?: string,
  ): Promise<{ issue: IssueDto; replayed: boolean }> {
    const hash = key
      ? createHash('sha256')
          .update(
            JSON.stringify({
              orderId,
              category: body.category,
              description: body.description,
              photoUrls: body.photoUrls ?? [],
            }),
          )
          .digest('hex')
      : null;
    if (key && hash) {
      const prior = await this.priorAttempt(user, key, hash);
      if (prior) return { issue: prior, replayed: true };
    }
    const order = await this.prisma.order.findFirst({ where: { id: orderId, customerId: user.id } });
    if (!order) throw AppError.notFound('Order');
    const urls = body.photoUrls ?? [];
    await this.ownPhotos(user, urls);
    const settings = await this.settings.get();
    const due =
      settings.issueFirstResponseHours == null
        ? null
        : new Date(this.clock.now().getTime() + settings.issueFirstResponseHours * 3_600_000);
    let issue: Case;
    try {
      issue = await this.prisma.orderIssue.create({
        data: {
          orderId,
          customerId: user.id,
          category: body.category,
          description: body.description,
          photoUrls: urls,
          firstResponseDueAt: due,
          requestKey: key,
          requestHash: hash,
        },
        include: INCLUDE,
      });
    } catch (err) {
      if (key && hash && err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        const prior = await this.priorAttempt(user, key, hash);
        if (prior) return { issue: prior, replayed: true };
      }
      throw err;
    }
    if (due)
      await this.jobs
        .schedule('issues-first-response', { issueId: issue.id }, { startAfter: due, jobId: issue.id })
        .catch((err) => this.logger.error('Could not schedule report first-response check', err));
    this.changed(issue, 'created');
    return { issue: this.dto(issue, user), replayed: false };
  }

  async list(user: User, q: IssuesQuery) {
    const where: Prisma.OrderIssueWhereInput = {
      ...(!staff(user) ? { customerId: user.id } : {}),
      ...(q.status ? { status: q.status } : {}),
      ...(q.orderId ? { orderId: q.orderId } : {}),
      ...(staff(user) && q.handledById ? { handledById: q.handledById } : {}),
      ...(q.search ? { order: { orderNumber: { contains: q.search.trim(), mode: 'insensitive' } } } : {}),
      ...(q.overdue ? { status: 'OPEN', acknowledgedAt: null, firstResponseDueAt: { lte: this.clock.now() } } : {}),
    };
    const [items, total] = await Promise.all([
      this.prisma.orderIssue.findMany({
        where,
        include: INCLUDE,
        orderBy: [{ firstResponseDueAt: { sort: 'asc', nulls: 'last' } }, { createdAt: 'asc' }],
        ...pageArgs(q),
      }),
      this.prisma.orderIssue.count({ where }),
    ]);
    return { items: items.map((i) => this.dto(i, user)), total, page: q.page, pageSize: q.pageSize };
  }

  async get(user: User, id: string): Promise<IssueDto> {
    const issue = await this.prisma.orderIssue.findFirst({
      where: { id, ...(!staff(user) ? { customerId: user.id } : {}) },
      include: INCLUDE,
    });
    if (!issue) throw AppError.notFound('Report');
    return this.dto(issue, user);
  }

  async message(user: User, id: string, body: string): Promise<IssueDto> {
    const issue = await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM order_issues WHERE id = ${id}::uuid FOR UPDATE`;
      const current = await tx.orderIssue.findFirst({
        where: { id, ...(!staff(user) ? { customerId: user.id } : {}) },
      });
      if (!current) throw AppError.notFound('Report');
      if (closed(current.status))
        throw AppError.conflict('REPORT_CLOSED', 'This report is closed. Contact support or start a new report.');
      await tx.orderIssueMessage.create({ data: { issueId: id, authorId: user.id, fromStaff: staff(user), body } });
      return tx.orderIssue.update({
        where: { id },
        data: staff(user)
          ? {
              status: 'ACKNOWLEDGED',
              acknowledgedAt: current.acknowledgedAt ?? this.clock.now(),
              handledById: current.handledById ?? user.id,
            }
          : {},
        include: INCLUDE,
      });
    });
    if (staff(user)) this.audit.log(user.id, 'issue.replied', 'issue', id, { orderId: issue.orderId });
    this.changed(issue, 'message', staff(user));
    return this.dto(issue, user);
  }

  async update(user: User, id: string, body: UpdateIssueDto): Promise<IssueDto> {
    if (!staff(user)) throw AppError.notFound('Report');
    if (
      body.handledById &&
      !(await this.prisma.user.findFirst({
        where: { id: body.handledById, role: { in: ['ADMIN', 'SUPER_ADMIN'] }, isActive: true, deletedAt: null },
      }))
    )
      throw AppError.badRequest('INVALID_HANDLER', 'Assign an active staff member.');
    const issue = await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM order_issues WHERE id = ${id}::uuid FOR UPDATE`;
      const current = await tx.orderIssue.findUnique({ where: { id } });
      if (!current) throw AppError.notFound('Report');
      const status = body.status ?? current.status;
      const note = body.resolutionNote?.trim() ?? current.resolutionNote;
      if (closed(status) && (!note || note.length < 3))
        throw AppError.badRequest('RESOLUTION_REQUIRED', 'Explain the resolution before closing the report.');
      if (!closed(status) && (body.compensationPaise || body.refundId))
        throw AppError.badRequest('COMPENSATION_NEEDS_CLOSE', 'Record the remedy when you resolve the report.');
      // The remedy belongs to a closed report; reopening clears it, as it does the resolution note.
      let compensation = closed(status)
        ? body.compensationPaise !== undefined
          ? body.compensationPaise
          : current.compensationPaise
        : null;
      const refundId = closed(status) ? (body.refundId !== undefined ? body.refundId : current.refundId) : null;
      if (refundId) {
        const refund = await tx.refund.findUnique({
          where: { id: refundId },
          select: { orderId: true, amountPaise: true },
        });
        if (!refund || refund.orderId !== current.orderId)
          throw AppError.badRequest('INVALID_REFUND', "Link a refund made on this report's order.");
        compensation ??= refund.amountPaise;
        if (refund.amountPaise > compensation)
          throw AppError.badRequest('REFUND_EXCEEDS_REMEDY', 'The linked refund is larger than the agreed remedy.');
      }
      if (status === 'REJECTED' && compensation)
        throw AppError.badRequest(
          'COMPENSATION_ON_REJECTED',
          'A report closed with an explanation cannot carry a payout.',
        );
      return tx.orderIssue.update({
        where: { id },
        data: {
          status,
          compensationPaise: compensation,
          refundId,
          ...(body.handledById !== undefined ? { handledById: body.handledById } : {}),
          acknowledgedAt: status !== 'OPEN' ? (current.acknowledgedAt ?? this.clock.now()) : current.acknowledgedAt,
          resolvedAt: closed(status) ? (current.resolvedAt ?? this.clock.now()) : null,
          resolutionNote: closed(status) ? note : null,
        },
        include: INCLUDE,
      });
    });
    this.audit.log(user.id, 'issue.updated', 'issue', id, {
      orderId: issue.orderId,
      status: issue.status,
      handledById: issue.handledById,
      compensationPaise: issue.compensationPaise,
      refundId: issue.refundId,
    });
    this.changed(issue, 'updated', true);
    return this.dto(issue, user);
  }

  async checkOverdue(id: string): Promise<void> {
    const marked = await this.prisma.orderIssue.updateMany({
      where: {
        id,
        status: 'OPEN',
        acknowledgedAt: null,
        overdueNotifiedAt: null,
        firstResponseDueAt: { lte: this.clock.now() },
      },
      data: { overdueNotifiedAt: this.clock.now() },
    });
    if (marked.count === 1) {
      const issue = await this.prisma.orderIssue.findUniqueOrThrow({ where: { id }, include: INCLUDE });
      this.changed(issue, 'overdue');
    }
  }
}
