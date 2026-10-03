import { Injectable, Logger } from '@nestjs/common';
import { FirebaseService } from '../auth/firebase.service.js';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { OrderStatus, Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toDriverProfileDto, toUserDto, type MeDto, type RegisterDeviceDto, type UpdateMeDto } from './user.dto.js';

const TERMINAL: OrderStatus[] = [OrderStatus.DELIVERED, OrderStatus.CANCELLED];

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
  ) {}

  async me(user: User): Promise<MeDto> {
    const driver =
      user.role === Role.DRIVER
        ? await this.prisma.driverProfile.findUnique({ where: { userId: user.id } })
        : null;
    return { ...toUserDto(user), driver: driver ? toDriverProfileDto(driver) : null };
  }

  async update(user: User, dto: UpdateMeDto): Promise<MeDto> {
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { name: dto.name?.trim(), email: dto.email === null ? null : dto.email?.trim().toLowerCase() },
    });
    return this.me(updated);
  }

  /** Registers (or moves) an FCM token to this user. */
  async registerDevice(user: User, dto: RegisterDeviceDto): Promise<void> {
    await this.prisma.device.upsert({
      where: { fcmToken: dto.fcmToken },
      create: { userId: user.id, fcmToken: dto.fcmToken, platform: dto.platform, app: dto.app },
      update: { userId: user.id, platform: dto.platform, app: dto.app, lastSeenAt: new Date() },
    });
  }

  async removeDevice(user: User, fcmToken: string): Promise<void> {
    await this.prisma.device.deleteMany({ where: { userId: user.id, fcmToken } });
  }

  /**
   * In-app account deletion (App Store guideline 5.1.1(v)).
   * Personal data is erased; orders are kept for accounting but no longer
   * linked to a phone number or name.
   *
   * [actorId] is who asked for it: the customer themselves in the app, or an administrator acting on a request
   * made by email or phone (for people who can no longer open the app).
   */
  async deleteAccount(user: User, actorId: string = user.id): Promise<void> {
    if (user.role !== Role.CUSTOMER) {
      throw AppError.forbidden('STAFF_ACCOUNT', 'Staff accounts are removed by an administrator');
    }
    const active = await this.prisma.order.count({
      where: { customerId: user.id, status: { notIn: TERMINAL } },
    });
    if (active > 0) {
      throw AppError.conflict(
        'ACTIVE_ORDERS',
        'You have orders in progress. Cancel them or wait until they are delivered.',
        { activeOrders: active },
      );
    }

    const now = new Date();
    await this.prisma.$transaction([
      this.prisma.address.updateMany({
        where: { userId: user.id, deletedAt: null },
        data: { deletedAt: now, isPrimary: false },
      }),
      this.prisma.device.deleteMany({ where: { userId: user.id } }),
      this.prisma.notification.deleteMany({ where: { userId: user.id } }),
      this.prisma.user.update({
        where: { id: user.id },
        data: {
          phone: `deleted:${user.id}`,
          firebaseUid: null,
          name: null,
          email: null,
          isActive: false,
          deletedAt: now,
        },
      }),
      this.prisma.auditLog.create({
        data: { actorId, action: 'account.deleted', entity: 'user', entityId: user.id },
      }),
    ]);

    if (this.firebase.auth && user.firebaseUid && !user.firebaseUid.startsWith('dev-')) {
      await this.firebase.auth.deleteUser(user.firebaseUid).catch((err: unknown) => {
        this.logger.warn(`Could not delete Firebase user ${user.firebaseUid}: ${String(err)}`);
      });
    }
  }
}
