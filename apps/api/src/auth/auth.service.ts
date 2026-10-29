import { HttpStatus, Injectable } from '@nestjs/common';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { ClientApp, Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { FirebaseService } from './firebase.service.js';
import { hashPassword, verifyPassword } from './password.js';
import { PASSWORD_UID_PREFIX, type VerifiedIdentity } from './token-verifier.js';

const APP_ROLES: Record<ClientApp, readonly Role[]> = {
  [ClientApp.CUSTOMER]: [Role.CUSTOMER],
  [ClientApp.PARTNER]: [Role.DRIVER],
  [ClientApp.ADMIN]: [Role.ADMIN, Role.SUPER_ADMIN],
};

/** After this many wrong passwords for one account, further attempts are refused for the window below. */
const MAX_FAILED_LOGINS = 8;
const LOCK_WINDOW_MS = 15 * 60_000;

@Injectable()
export class AuthService {
  /** Wrong-password counts per admin email. Only real accounts get an entry, so strangers cannot grow it. */
  private readonly failedLogins = new Map<string, { count: number; since: number }>();
  /** Checked when the email is unknown, so a miss takes as long as a wrong password. */
  private decoyHash: Promise<string> | undefined;

  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
  ) {}

  /**
   * Called by every app right after sign-in.
   * - Customers are created on first sign-in, by phone code or by Google.
   * - A Google customer has no phone until they link a verified number to the same Firebase account; the next call here
   *   then stores it. Placing an order needs that number.
   * - Drivers and admins must have been added by an admin (matched by phone);
   *   their Firebase UID is linked on first sign-in. Google can never sign in to those apps.
   * - An admin who signed in with email + password has no phone; they were linked when the password was checked.
   */
  async startSession(identity: VerifiedIdentity, app: ClientApp): Promise<User> {
    const isGoogle = identity.provider === 'google';
    if (isGoogle && app !== ClientApp.CUSTOMER) {
      throw AppError.forbidden('WRONG_APP', 'This account cannot sign in to this app');
    }

    let user = await this.prisma.user.findUnique({ where: { firebaseUid: identity.uid } });

    if (!user) {
      if (!identity.phone && !isGoogle) {
        throw AppError.forbidden('NOT_REGISTERED', 'This account is not registered. Ask a super admin to add you.');
      }
      const byPhone = identity.phone
        ? await this.prisma.user.findUnique({ where: { phone: identity.phone } })
        : null;
      if (byPhone) {
        // A staff member's number must not be claimed through the customer app, even with a verified Google account.
        if (isGoogle && byPhone.role !== Role.CUSTOMER) {
          throw AppError.forbidden('WRONG_APP', 'This account cannot sign in to this app');
        }
        // Same phone, new Firebase UID: either first sign-in of a provisioned
        // user, or the Firebase account was recreated. Firebase guarantees one
        // UID per phone, so relinking is safe.
        user = await this.prisma.user.update({
          where: { id: byPhone.id },
          data: { firebaseUid: identity.uid },
        });
      } else if (app === ClientApp.CUSTOMER) {
        user = await this.prisma.user.create({
          data: {
            firebaseUid: identity.uid,
            phone: identity.phone,
            role: Role.CUSTOMER,
            ...(isGoogle ? { email: identity.email ?? null, name: identity.name ?? null } : {}),
          },
        });
      } else {
        throw AppError.forbidden(
          'NOT_REGISTERED',
          'This number is not registered. Ask your administrator to add you.',
        );
      }
    } else if (isGoogle && identity.phone && !user.phone) {
      // The customer verified a number and linked it to their Google account. Never merge two accounts silently.
      const owner = await this.prisma.user.findUnique({ where: { phone: identity.phone } });
      if (owner && owner.id !== user.id) {
        throw AppError.conflict('PHONE_IN_USE', 'This number already belongs to another account.');
      }
      user = await this.prisma.user.update({ where: { id: user.id }, data: { phone: identity.phone } });
    }

    if (!user.isActive || user.deletedAt) {
      throw AppError.forbidden('ACCOUNT_DISABLED', 'This account is disabled');
    }
    if (!APP_ROLES[app].includes(user.role)) {
      throw AppError.forbidden('WRONG_APP', 'This account cannot sign in to this app');
    }

    return this.prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
  }

  /**
   * Checks an admin's email + password and returns a Firebase custom token for the admin app to sign in with.
   * The app then holds an ordinary Firebase ID token (refreshed by the Firebase SDK), which TokenVerifier accepts.
   */
  async passwordLogin(rawEmail: string, password: string): Promise<string> {
    const email = rawEmail.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: {
        email: { equals: email, mode: 'insensitive' },
        role: { in: [Role.ADMIN, Role.SUPER_ADMIN] },
        passwordHash: { not: null },
        deletedAt: null,
      },
    });

    if (user && this.isLocked(email)) {
      throw new AppError(HttpStatus.TOO_MANY_REQUESTS, 'TOO_MANY_ATTEMPTS', 'Too many wrong passwords. Try again in a few minutes.');
    }

    const valid = await verifyPassword(password, user?.passwordHash ?? (await this.decoy()));
    if (!user || !valid) {
      if (user) this.recordFailure(email);
      throw new AppError(HttpStatus.UNAUTHORIZED, 'INVALID_CREDENTIALS', 'The email or password is not right.');
    }
    if (!user.isActive) throw AppError.forbidden('ACCOUNT_DISABLED', 'This admin account has been disabled.');
    if (!this.firebase.auth) {
      throw new AppError(HttpStatus.SERVICE_UNAVAILABLE, 'AUTH_UNAVAILABLE', 'Sign-in is not configured on the server.');
    }

    this.failedLogins.delete(email);
    const uid = `${PASSWORD_UID_PREFIX}${user.id}`;
    if (user.firebaseUid !== uid) {
      await this.prisma.user.update({ where: { id: user.id }, data: { firebaseUid: uid } });
    }
    return this.firebase.auth.createCustomToken(uid);
  }

  private decoy(): Promise<string> {
    this.decoyHash ??= hashPassword('not-a-real-password');
    return this.decoyHash;
  }

  private isLocked(email: string): boolean {
    const entry = this.failedLogins.get(email);
    if (!entry) return false;
    if (Date.now() - entry.since > LOCK_WINDOW_MS) {
      this.failedLogins.delete(email);
      return false;
    }
    return entry.count >= MAX_FAILED_LOGINS;
  }

  private recordFailure(email: string): void {
    const entry = this.failedLogins.get(email);
    if (!entry || Date.now() - entry.since > LOCK_WINDOW_MS) {
      this.failedLogins.set(email, { count: 1, since: Date.now() });
    } else {
      entry.count += 1;
    }
  }
}
