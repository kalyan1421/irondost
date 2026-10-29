import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import { normalizeIndianPhone } from '../common/phone.js';
import { FirebaseService } from './firebase.service.js';

/** Identity proven by a verified token: the Firebase UID and, for phone sign-in, its phone number. */
export interface VerifiedIdentity {
  uid: string;
  /** Null for an admin who signed in with email + password; the account is found by `uid` alone. */
  phone: string | null;
}

const DEV_PREFIX = 'dev:';

/** UID prefix of admins signed in with email + password. Firebase's own UIDs never contain an underscore. */
export const PASSWORD_UID_PREFIX = 'pw_';

/**
 * Verifies `Authorization: Bearer <token>` values.
 * - Normal tokens are Firebase ID tokens from phone-OTP sign-in.
 * - Admins who signed in with email + password hold an ID token minted from a custom token that only this API
 *   can create (after checking the password), so a `custom` provider with a `pw_` UID is trusted without a phone.
 * - With AUTH_DEV_BYPASS=true (never allowed in production), `dev:<phone>`
 *   is accepted so the API can be exercised locally without Firebase.
 */
@Injectable()
export class TokenVerifier {
  constructor(
    @Inject(APP_ENV) private readonly env: Env,
    private readonly firebase: FirebaseService,
  ) {}

  async verify(token: string): Promise<VerifiedIdentity> {
    if (this.env.AUTH_DEV_BYPASS && token.startsWith(DEV_PREFIX)) {
      const phone = normalizeIndianPhone(token.slice(DEV_PREFIX.length));
      if (!phone) throw new UnauthorizedException('Invalid dev token');
      return { uid: `dev-${phone.slice(1)}`, phone };
    }

    if (!this.firebase.auth) throw new UnauthorizedException('Authentication is not configured');

    let decoded;
    try {
      // No revocation check per request (it costs a network call); disabling an
      // account is enforced through users.is_active instead.
      decoded = await this.firebase.auth.verifyIdToken(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
    if (decoded.firebase.sign_in_provider === 'custom' && decoded.uid.startsWith(PASSWORD_UID_PREFIX)) {
      return { uid: decoded.uid, phone: null };
    }
    const phone = decoded.phone_number ? normalizeIndianPhone(decoded.phone_number) : null;
    if (!phone) throw new UnauthorizedException('Token has no Indian phone number');
    return { uid: decoded.uid, phone };
  }
}
