import { vi } from 'vitest';
import type { Env } from '../config/env.js';
import type { FirebaseService } from './firebase.service.js';
import { TokenVerifier } from './token-verifier.js';

function verifierFor(decoded: Record<string, unknown>, devBypass = false) {
  const verifyIdToken = vi.fn().mockResolvedValue(decoded);
  const firebase = { auth: { verifyIdToken } } as unknown as FirebaseService;
  return new TokenVerifier({ AUTH_DEV_BYPASS: devBypass } as Env, firebase);
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

  describe('Google sign-in', () => {
    const google = (extra: Record<string, unknown> = {}) => ({
      uid: 'g-uid',
      email: 'Priya@Example.com',
      email_verified: true,
      name: ' Priya Sharma ',
      firebase: { sign_in_provider: 'google.com' },
      ...extra,
    });

    it('accepts a Google token with no phone yet', async () => {
      expect(await verifierFor(google()).verify('t')).toEqual({
        uid: 'g-uid',
        phone: null,
        provider: 'google',
        email: 'priya@example.com',
        name: 'Priya Sharma',
      });
    });

    it('reads the verified number once it has been linked to the Google account', async () => {
      const identity = await verifierFor(google({ phone_number: '+919876543210' })).verify('t');
      expect(identity).toMatchObject({ uid: 'g-uid', phone: '+919876543210', provider: 'google' });
    });

    it('ignores a linked number that is not an Indian mobile', async () => {
      const identity = await verifierFor(google({ phone_number: '+14155550123' })).verify('t');
      expect(identity.phone).toBeNull();
    });

    it('needs an email on a Google token', async () => {
      await expect(verifierFor(google({ email: undefined })).verify('t')).rejects.toThrow('no email');
    });

    it('still asks a token from any other provider for a phone', async () => {
      const v = verifierFor({ uid: 'x', email: 'a@b.co', firebase: { sign_in_provider: 'password' } });
      await expect(v.verify('t')).rejects.toThrow('no Indian phone');
    });
  });

  describe('development tokens', () => {
    it('takes dev-google tokens only with the bypass on', async () => {
      const firebase = { auth: { verifyIdToken: vi.fn().mockRejectedValue(new Error('not a Firebase token')) } } as unknown as FirebaseService;
      const off = new TokenVerifier({ AUTH_DEV_BYPASS: false } as Env, firebase);
      await expect(off.verify('dev-google:a@b.co')).rejects.toThrow('Invalid or expired token');
    });

    it('gives a Google account without a number, and the same uid with one', async () => {
      const v = verifierFor({}, true);
      const bare = await v.verify('dev-google:Test@Example.com');
      expect(bare).toEqual({ uid: 'dev-google-test@example.com', phone: null, provider: 'google', email: 'test@example.com', name: 'test' });
      const linked = await v.verify('dev-google:test@example.com:9000000012');
      expect(linked).toMatchObject({ uid: bare.uid, phone: '+919000000012', provider: 'google' });
    });

    it('rejects a malformed email or number', async () => {
      const v = verifierFor({}, true);
      await expect(v.verify('dev-google:not-an-email')).rejects.toThrow('Invalid dev token');
      await expect(v.verify('dev-google:a@b.co:12345')).rejects.toThrow('Invalid dev token');
    });

    it('keeps the plain dev:<phone> token working', async () => {
      expect(await verifierFor({}, true).verify('dev:9876543210')).toEqual({ uid: 'dev-919876543210', phone: '+919876543210' });
    });
  });
});
