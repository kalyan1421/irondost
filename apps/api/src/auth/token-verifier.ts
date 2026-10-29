import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import { normalizeIndianPhone } from '../common/phone.js';
import { FirebaseService } from './firebase.service.js';

/**
 * Identity proven by a verified token: the Firebase UID and, when the account has a verified Indian number, its phone.
 * `provider` is set only for Google sign-in, whose token carries an email and a name but may have no phone yet.
 */
export interface VerifiedIdentity {
  uid: string;
  /** Null for an admin who signed in with email + password, and for a Google customer who has not added a number. */
  phone: string | null;
  provider?: 'google';
  email?: string | null;
  name?: string | null;
}

const DEV_PREFIX = 'dev:';
/** `dev-google:<email>` or `dev-google:<email>:<phone>` (the second form stands in for a Google account with a linked, verified phone). */
const DEV_GOOGLE_PREFIX = 'dev-google:';
const EMAIL_SHAPE = /^[^\s@:]+@[^\s@:]+\.[^\s@:]+$/;

/** UID prefix of admins signed in with email + password. Firebase's own UIDs never contain an underscore. */
export const PASSWORD_UID_PREFIX = 'pw_';

/**
 * Verifies `Authorization: Bearer <token>` values.
 * - Normal tokens are Firebase ID tokens from phone-OTP sign-in.
 * - Google sign-in tokens (`google.com`) are accepted without a phone: such a customer can browse and build a basket, and
 *   adds a verified number (linked to the same Firebase account) before ordering.
 * - Admins who signed in with email + password hold an ID token minted from a custom token that only this API
 *   can create (after checking the password), so a `custom` provider with a `pw_` UID is trusted without a phone.
 * - With AUTH_DEV_BYPASS=true (never allowed in production), `dev:<phone>` and `dev-google:<email>[:<phone>]`
 *   are accepted so the API can be exercised locally without Firebase.
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
    if (this.env.AUTH_DEV_BYPASS && token.startsWith(DEV_GOOGLE_PREFIX)) return this.devGoogle(token.slice(DEV_GOOGLE_PREFIX.length));

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
    if (decoded.firebase.sign_in_provider === 'google.com') {
      if (!decoded.email) throw new UnauthorizedException('Google account has no email');
      const name = typeof decoded.name === 'string' && decoded.name.trim() ? decoded.name.trim() : null;
      return { uid: decoded.uid, phone, provider: 'google', email: decoded.email.toLowerCase(), name };
    }
    if (!phone) throw new UnauthorizedException('Token has no Indian phone number');
    return { uid: decoded.uid, phone };
  }

  private devGoogle(rest: string): VerifiedIdentity {
    const split = rest.indexOf(':');
    const email = (split < 0 ? rest : rest.slice(0, split)).trim().toLowerCase();
    const rawPhone = split < 0 ? null : rest.slice(split + 1);
    if (!EMAIL_SHAPE.test(email)) throw new UnauthorizedException('Invalid dev token');
    const phone = rawPhone === null ? null : normalizeIndianPhone(rawPhone);
    if (rawPhone !== null && !phone) throw new UnauthorizedException('Invalid dev token');
    return { uid: `dev-google-${email}`, phone, provider: 'google', email, name: email.split('@')[0] ?? null };
  }
}
