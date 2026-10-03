import { Inject, Injectable, Logger } from '@nestjs/common';
import { cert, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';

/**
 * Firebase is used for exactly two things: verifying phone-OTP ID tokens and
 * sending push notifications. No Firebase database or storage is touched.
 * When no service account is configured (local dev, tests) both are null.
 */
@Injectable()
export class FirebaseService {
  private readonly logger = new Logger(FirebaseService.name);
  readonly auth: Auth | null;
  readonly messaging: Messaging | null;

  constructor(@Inject(APP_ENV) env: Env) {
    if (!env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
      this.logger.warn('Firebase not configured: ID-token login and push are disabled');
      this.auth = null;
      this.messaging = null;
      return;
    }
    const serviceAccount = JSON.parse(
      Buffer.from(env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8'),
    ) as Record<string, string>;
    const app: App = initializeApp({ credential: cert(serviceAccount) });
    this.auth = getAuth(app);
    this.messaging = getMessaging(app);
  }
}
