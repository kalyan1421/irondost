import { Injectable } from '@nestjs/common';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { pageArgs } from '../common/pagination.js';
import { normalizeIndianPhone } from '../common/phone.js';
import { addDays, istDate, istInstant, toDbDate } from '../common/time.js';
import type { Prisma, User } from '../generated/prisma/client.js';
import {
  OrderStatus,
  PaymentRecordStatus,
  Role,
} from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toUserDto } from '../users/user.dto.js';
import type {
  CreateCustomerDto,
  CreateStaffDto,
  CustomerPageDto,
  CustomersQuery,
  DashboardDto,
  UpdateCustomerDto,
  UpdateStaffDto,
} from './admin.dto.js';

const STAFF_ROLES = [Role.ADMIN, Role.SUPER_ADMIN];

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  private phoneOrThrow(input: string): string {
    const phone = normalizeIndianPhone(input);
    if (!phone)
      throw AppError.badRequest(
        'INVALID_PHONE',
        'Enter a valid 10-digit Indian mobile number',
      );
    return phone;
  }

  // ───────────── Customers ─────────────

  async customers(q: CustomersQuery): Promise<CustomerPageDto> {
    const search = q.search?.trim();
    const exactPhone = search ? normalizeIndianPhone(search) : null;
    const where: Prisma.UserWhereInput = {
      role: Role.CUSTOMER,
      deletedAt: null,
      ...(exactPhone
        ? { phone: exactPhone }
        : search
          ? {
              OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { phone: { contains: search.replace(/\s/g, '') } },
              ],
            }
          : {}),
    };
    const [rows, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { orders: true } },
          orders: {
            select: { createdAt: true },
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
        },
        ...pageArgs(q),
      }),
      this.prisma.user.count({ where }),
    ]);
    return {
      items: rows.map((u) => ({
        ...toUserDto(u),
        orderCount: u._count.orders,
        lastOrderAt: u.orders[0]?.createdAt ?? null,
      })),
      page: q.page,
      pageSize: q.pageSize,
      total,
    };
  }

  async customer(id: string): Promise<User> {
    const user = await this.prisma.user.findFirst({
      where: { id, role: Role.CUSTOMER, deletedAt: null },
    });
    if (!user) throw AppError.notFound('Customer');
    return user;
  }

  /** For phone orders. The customer can later sign in with OTP on this number and see their orders. */
  async createCustomer(dto: CreateCustomerDto): Promise<User> {
    const phone = this.phoneOrThrow(dto.phone);
    if (await this.prisma.user.findUnique({ where: { phone } })) {
      throw AppError.conflict(
        'PHONE_IN_USE',
        'A customer with this number already exists',
      );
    }
    return this.prisma.user.create({
      data: {
        phone,
        name: dto.name.trim(),
        email: dto.email?.trim().toLowerCase() ?? null,
        role: Role.CUSTOMER,
      },
    });
  }

  async updateCustomer(id: string, dto: UpdateCustomerDto): Promise<User> {
    const current = await this.customer(id);
    const phone = dto.phone ? this.phoneOrThrow(dto.phone) : undefined;
    return this.prisma.user.update({
      where: { id },
      data: {
        // Changing the number unlinks the old Firebase login.
        ...(phone && phone !== current.phone
          ? { phone, firebaseUid: null }
          : {}),
        name: dto.name?.trim(),
        email: dto.email === null ? null : dto.email?.trim().toLowerCase(),
        isActive: dto.isActive,
      },
    });
  }

  // ───────────── Staff ─────────────

  staff(): Promise<User[]> {
    return this.prisma.user.findMany({
      where: { role: { in: STAFF_ROLES }, deletedAt: null },
      orderBy: { name: 'asc' },
    });
  }

  async createStaff(dto: CreateStaffDto): Promise<User> {
    const phone = this.phoneOrThrow(dto.phone);
    if (await this.prisma.user.findUnique({ where: { phone } })) {
      throw AppError.conflict(
        'PHONE_IN_USE',
        'This number already belongs to another account',
      );
    }
    return this.prisma.user.create({
      data: { phone, name: dto.name.trim(), role: dto.role },
    });
  }

  async updateStaff(
    actor: User,
    id: string,
    dto: UpdateStaffDto,
  ): Promise<User> {
    const target = await this.prisma.user.findFirst({
      where: { id, role: { in: STAFF_ROLES }, deletedAt: null },
    });
    if (!target) throw AppError.notFound('Staff member');
    if (
      id === actor.id &&
      (dto.isActive === false || (dto.role && dto.role !== actor.role))
    ) {
      throw AppError.badRequest(
        'SELF_LOCKOUT',
        'You cannot deactivate or demote yourself',
      );
    }
    const demotesSuper =
      target.role === Role.SUPER_ADMIN &&
      (dto.isActive === false || dto.role === Role.ADMIN);
    if (demotesSuper) {
      const supers = await this.prisma.user.count({
        where: { role: Role.SUPER_ADMIN, isActive: true, deletedAt: null },
      });
      if (supers <= 1)
        throw AppError.badRequest(
          'LAST_SUPER_ADMIN',
          'There must be at least one active super admin',
        );
    }
    return this.prisma.user.update({
      where: { id },
      data: { name: dto.name?.trim(), role: dto.role, isActive: dto.isActive },
    });
  }

  // ───────────── Dashboard ─────────────

  async dashboard(): Promise<DashboardDto> {
    const now = this.clock.now();
    const today = istDate(now);
    const startOfToday = istInstant(today, 0);
    const since = (days: number) => istInstant(addDays(today, -days + 1), 0);
    const collected = (from: Date) =>
      this.prisma.payment
        .aggregate({
          where: {
            status: PaymentRecordStatus.CAPTURED,
            updatedAt: { gte: from },
          },
          _sum: { amountPaise: true },
        })
        .then((r) => r._sum.amountPaise ?? 0);

    const [
      byStatus,
      pickupsToday,
      deliveriesToday,
      ordersToday,
      needsAttention,
      driversOnline,
      c1,
      c7,
      c30,
      daily,
    ] = await Promise.all([
      this.prisma.order.groupBy({ by: ['status'], _count: { _all: true } }),
      this.prisma.order.count({
        where: {
          pickupDate: toDbDate(today),
          status: { not: OrderStatus.CANCELLED },
        },
      }),
      this.prisma.order.count({
        where: {
          deliveryDate: toDbDate(today),
          status: { not: OrderStatus.CANCELLED },
        },
      }),
      this.prisma.order.count({ where: { createdAt: { gte: startOfToday } } }),
      this.prisma.order.count({
        where: {
          dispatchFailedAt: { not: null },
          status: { in: [OrderStatus.PENDING, OrderStatus.READY_FOR_DELIVERY] },
        },
      }),
      this.prisma.driverProfile.count({
        where: { isOnline: true, user: { isActive: true, deletedAt: null } },
      }),
      collected(startOfToday),
      collected(since(7)),
      collected(since(30)),
      this.prisma.$queryRaw<
        { date: string; orders: bigint; value: bigint | null }[]
      >`
          SELECT to_char((created_at AT TIME ZONE 'Asia/Kolkata')::date, 'YYYY-MM-DD') AS date,
                 count(*) AS orders,
                 sum(total_paise) AS value
          FROM orders
          WHERE created_at >= ${since(14)} AND status <> 'CANCELLED'
          GROUP BY 1 ORDER BY 1`,
    ]);

    const dailyMap = new Map(daily.map((d) => [d.date, d]));
    return {
      byStatus: Object.fromEntries(
        byStatus.map((s) => [s.status, s._count._all]),
      ),
      pickupsToday,
      deliveriesToday,
      ordersToday,
      needsAttention,
      driversOnline,
      collectedTodayPaise: c1,
      collectedLast7DaysPaise: c7,
      collectedLast30DaysPaise: c30,
      dailyOrders: Array.from({ length: 14 }, (_, i) => {
        const date = addDays(today, i - 13);
        const row = dailyMap.get(date);
        return {
          date,
          orders: Number(row?.orders ?? 0),
          valuePaise: Number(row?.value ?? 0),
        };
      }),
    };
  }
}
