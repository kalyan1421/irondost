import { Injectable } from '@nestjs/common';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { ClientApp, Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { VerifiedIdentity } from './token-verifier.js';

const APP_ROLES: Record<ClientApp, readonly Role[]> = {
  [ClientApp.CUSTOMER]: [Role.CUSTOMER],
  [ClientApp.PARTNER]: [Role.DRIVER],
  [ClientApp.ADMIN]: [Role.ADMIN, Role.SUPER_ADMIN],
};

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Called by every app right after phone-OTP sign-in.
   * - Customers are created on first sign-in.
   * - Drivers and admins must have been added by an admin (matched by phone);
   *   their Firebase UID is linked on first sign-in.
   */
  async startSession(identity: VerifiedIdentity, app: ClientApp): Promise<User> {
    let user = await this.prisma.user.findUnique({ where: { firebaseUid: identity.uid } });

    if (!user) {
      const byPhone = await this.prisma.user.findUnique({ where: { phone: identity.phone } });
      if (byPhone) {
        // Same phone, new Firebase UID: either first sign-in of a provisioned
        // user, or the Firebase account was recreated. Firebase guarantees one
        // UID per phone, so relinking is safe.
        user = await this.prisma.user.update({
          where: { id: byPhone.id },
          data: { firebaseUid: identity.uid },
        });
      } else if (app === ClientApp.CUSTOMER) {
        user = await this.prisma.user.create({
          data: { firebaseUid: identity.uid, phone: identity.phone, role: Role.CUSTOMER },
        });
      } else {
        throw AppError.forbidden(
          'NOT_REGISTERED',
          'This number is not registered. Ask your administrator to add you.',
        );
      }
    }

    if (!user.isActive || user.deletedAt) {
      throw AppError.forbidden('ACCOUNT_DISABLED', 'This account is disabled');
    }
    if (!APP_ROLES[app].includes(user.role)) {
      throw AppError.forbidden('WRONG_APP', 'This account cannot sign in to this app');
    }

    return this.prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
  }
}
