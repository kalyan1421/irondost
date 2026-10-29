import { vi } from 'vitest';
import type { Env } from '../config/env.js';
import type { FirebaseService } from './firebase.service.js';
import { TokenVerifier } from './token-verifier.js';

function verifierFor(decoded: Record<string, unknown>) {
  const verifyIdToken = vi.fn().mockResolvedValue(decoded);
  const firebase = { auth: { verifyIdToken } } as unknown as FirebaseService;
  return new TokenVerifier({ AUTH_DEV_BYPASS: false } as Env, firebase);
}

describe('TokenVerifier', () => {
  it('accepts a phone sign-in token', async () => {
    const v = verifierFor({ uid: 'abc123', phone_number: '+919876543210', firebase: { sign_in_provider: 'phone' } });
    expect(await v.verify('t')).toEqual({ uid: 'abc123', phone: '+919876543210' });
  });

  it('accepts a custom token for a password admin without a phone', async () => {
    const v = verifierFor({ uid: 'pw_7d1c', firebase: { sign_in_provider: 'custom' } });
    expect(await v.verify('t')).toEqual({ uid: 'pw_7d1c', phone: null });
  });

  it('does not trust a pw_ uid that did not come from a custom token', async () => {
    const v = verifierFor({ uid: 'pw_7d1c', email: 'a@b.co', email_verified: true, firebase: { sign_in_provider: 'password' } });
    await expect(v.verify('t')).rejects.toThrow('no Indian phone');
  });

  it('does not trust a custom token for any other uid', async () => {
    const v = verifierFor({ uid: 'someone-else', firebase: { sign_in_provider: 'custom' } });
    await expect(v.verify('t')).rejects.toThrow('no Indian phone');
  });

  it('rejects a token Firebase will not verify', async () => {
    const firebase = { auth: { verifyIdToken: vi.fn().mockRejectedValue(new Error('expired')) } } as unknown as FirebaseService;
    const v = new TokenVerifier({ AUTH_DEV_BYPASS: false } as Env, firebase);
    await expect(v.verify('t')).rejects.toThrow('Invalid or expired token');
  });
});
