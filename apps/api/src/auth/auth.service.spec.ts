import { vi } from 'vitest';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { ClientApp, Role } from '../generated/prisma/enums.js';
import type { PrismaService } from '../prisma/prisma.service.js';
import { AuthService } from './auth.service.js';
import type { FirebaseService } from './firebase.service.js';
import { hashPassword } from './password.js';

const PASSWORD = 'a-long-enough-password';

async function adminUser(overrides: Partial<User> = {}): Promise<User> {
  return {
    id: '11111111-1111-1111-1111-111111111111',
    firebaseUid: null,
    phone: 'email:admin@example.com',
    name: 'Admin',
    email: 'admin@example.com',
    passwordHash: await hashPassword(PASSWORD),
    role: Role.SUPER_ADMIN,
    isActive: true,
    lastLoginAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
    ...overrides,
  };
}

function setup(user: User | null, { firebaseOn = true }: { firebaseOn?: boolean } = {}) {
  const findFirst = vi.fn().mockResolvedValue(user);
  const findUnique = vi.fn().mockResolvedValue(user);
  const update = vi.fn().mockImplementation(({ data }: { data: Partial<User> }) => Promise.resolve({ ...user, ...data }));
  const create = vi.fn();
  const prisma = { user: { findFirst, findUnique, update, create } } as unknown as PrismaService;
  const createCustomToken = vi.fn().mockResolvedValue('custom-token');
  const firebase = { auth: firebaseOn ? { createCustomToken } : null } as unknown as FirebaseService;
  return { service: new AuthService(prisma, firebase), findFirst, findUnique, update, create, createCustomToken };
}

const codeOf = (p: Promise<unknown>) => p.then(() => 'resolved', (e: unknown) => (e as AppError).code);

describe('AuthService.passwordLogin', () => {
  it('returns a custom token for the right password and links the pw_ uid', async () => {
    const user = await adminUser();
    const { service, update, createCustomToken } = setup(user);
    expect(await service.passwordLogin('  Admin@Example.com ', PASSWORD)).toBe('custom-token');
    expect(createCustomToken).toHaveBeenCalledWith(`pw_${user.id}`);
    expect(update).toHaveBeenCalledWith({ where: { id: user.id }, data: { firebaseUid: `pw_${user.id}` } });
  });

  it('does not rewrite the uid when it is already linked', async () => {
    const user = await adminUser();
    const { service, update } = setup({ ...user, firebaseUid: `pw_${user.id}` });
    await service.passwordLogin('admin@example.com', PASSWORD);
    expect(update).not.toHaveBeenCalled();
  });

  it('gives the same answer for a wrong password and an unknown email', async () => {
    const wrong = setup(await adminUser());
    const unknown = setup(null);
    expect(await codeOf(wrong.service.passwordLogin('admin@example.com', 'nope'))).toBe('INVALID_CREDENTIALS');
    expect(await codeOf(unknown.service.passwordLogin('ghost@example.com', PASSWORD))).toBe('INVALID_CREDENTIALS');
    expect(wrong.createCustomToken).not.toHaveBeenCalled();
  });

  it('refuses a disabled admin, but only after the password is right', async () => {
    const { service } = setup(await adminUser({ isActive: false }));
    expect(await codeOf(service.passwordLogin('admin@example.com', 'nope'))).toBe('INVALID_CREDENTIALS');
    expect(await codeOf(service.passwordLogin('admin@example.com', PASSWORD))).toBe('ACCOUNT_DISABLED');
  });

  it('locks the account after repeated wrong passwords, even for the right one', async () => {
    const { service, createCustomToken } = setup(await adminUser());
    for (let i = 0; i < 8; i++) await codeOf(service.passwordLogin('admin@example.com', 'nope'));
    expect(await codeOf(service.passwordLogin('admin@example.com', PASSWORD))).toBe('TOO_MANY_ATTEMPTS');
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it('reports a server problem when Firebase is not configured', async () => {
    const { service } = setup(await adminUser(), { firebaseOn: false });
    expect(await codeOf(service.passwordLogin('admin@example.com', PASSWORD))).toBe('AUTH_UNAVAILABLE');
  });
});

describe('AuthService.startSession for a password admin (no phone)', () => {
  const identity = (uid: string) => ({ uid, phone: null });

  it('opens the session for the linked admin', async () => {
    const user = await adminUser({ firebaseUid: 'pw_x' });
    const { service, update } = setup(user);
    const result = await service.startSession(identity('pw_x'), ClientApp.ADMIN);
    expect(result.id).toBe(user.id);
    expect(update).toHaveBeenCalledWith({ where: { id: user.id }, data: { lastLoginAt: expect.any(Date) } });
  });

  it('does not create or match anyone by phone when the uid is unknown', async () => {
    const { service, create } = setup(null);
    expect(await codeOf(service.startSession(identity('pw_unknown'), ClientApp.ADMIN))).toBe('NOT_REGISTERED');
    expect(await codeOf(service.startSession(identity('pw_unknown'), ClientApp.CUSTOMER))).toBe('NOT_REGISTERED');
    expect(create).not.toHaveBeenCalled();
  });

  it('keeps an admin out of the customer and partner apps', async () => {
    const { service } = setup(await adminUser({ firebaseUid: 'pw_x' }));
    expect(await codeOf(service.startSession(identity('pw_x'), ClientApp.CUSTOMER))).toBe('WRONG_APP');
    expect(await codeOf(service.startSession(identity('pw_x'), ClientApp.PARTNER))).toBe('WRONG_APP');
  });
});

describe('AuthService.startSession', () => {
  const customer = (overrides: Partial<User> = {}): User => ({
    id: '22222222-2222-2222-2222-222222222222',
    firebaseUid: 'g-uid',
    phone: null,
    name: 'Priya',
    email: 'priya@example.com',
    passwordHash: null,
    role: Role.CUSTOMER,
    isActive: true,
    lastLoginAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
    ...overrides,
  });
  const google = { uid: 'g-uid', phone: null, provider: 'google' as const, email: 'priya@example.com', name: 'Priya Sharma' };

  /** `byUid` is what the Firebase UID lookup finds, `byPhone` what the phone lookup finds. */
  function sessionSetup({ byUid = null, byPhone = null }: { byUid?: User | null; byPhone?: User | null }) {
    const findUnique = vi.fn().mockImplementation(({ where }: { where: { firebaseUid?: string; phone?: string } }) =>
      Promise.resolve(where.firebaseUid !== undefined ? byUid : byPhone),
    );
    const create = vi.fn().mockImplementation(({ data }: { data: Partial<User> }) => Promise.resolve(customer(data)));
    let stored = byUid ?? byPhone ?? customer();
    const update = vi.fn().mockImplementation(({ where, data }: { where: { id: string }; data: Partial<User> }) => {
      stored = { ...stored, id: where.id, ...data };
      return Promise.resolve(stored);
    });
    const prisma = { user: { findUnique, create, update } } as unknown as PrismaService;
    return { service: new AuthService(prisma, {} as FirebaseService), create, update };
  }

  it('creates a Google customer with no phone, taking the name and email from Google', async () => {
    const { service, create } = sessionSetup({});
    const user = await service.startSession(google, ClientApp.CUSTOMER);
    expect(create).toHaveBeenCalledWith({
      data: { firebaseUid: 'g-uid', phone: null, role: Role.CUSTOMER, email: 'priya@example.com', name: 'Priya Sharma' },
    });
    expect(user.phone).toBeNull();
  });

  it('keeps phone sign-in creating customers as before', async () => {
    const { service, create } = sessionSetup({});
    await service.startSession({ uid: 'p-uid', phone: '+919876543210' }, ClientApp.CUSTOMER);
    expect(create).toHaveBeenCalledWith({ data: { firebaseUid: 'p-uid', phone: '+919876543210', role: Role.CUSTOMER } });
  });

  it('stores the number the first time the Google account arrives with a verified one', async () => {
    const { service, update } = sessionSetup({ byUid: customer(), byPhone: null });
    const user = await service.startSession({ ...google, phone: '+919000000012' }, ClientApp.CUSTOMER);
    expect(update).toHaveBeenCalledWith({ where: { id: customer().id }, data: { phone: '+919000000012' } });
    expect(user.phone).toBe('+919000000012');
  });

  it('refuses a number that already belongs to another account', async () => {
    const other = customer({ id: '33333333-3333-3333-3333-333333333333', firebaseUid: 'someone-else', phone: '+919000000012' });
    const { service, update } = sessionSetup({ byUid: customer(), byPhone: other });
    const code = await codeOf(service.startSession({ ...google, phone: '+919000000012' }, ClientApp.CUSTOMER));
    expect(code).toBe('PHONE_IN_USE');
    expect(update).not.toHaveBeenCalled();
  });

  it('does not change a number that is already stored', async () => {
    const { service, update } = sessionSetup({ byUid: customer({ phone: '+919111111111' }) });
    await service.startSession({ ...google, phone: '+919222222222' }, ClientApp.CUSTOMER);
    expect(update).toHaveBeenCalledTimes(1); // only lastLoginAt
    expect(update).toHaveBeenCalledWith({ where: { id: customer().id }, data: { lastLoginAt: expect.any(Date) } });
  });

  it.each([ClientApp.ADMIN, ClientApp.PARTNER])('never lets Google sign in to the %s app', async (app) => {
    const { service, create, update } = sessionSetup({});
    expect(await codeOf(service.startSession(google, app))).toBe('WRONG_APP');
    expect(await codeOf(service.startSession({ ...google, phone: '+919000000012' }, app))).toBe('WRONG_APP');
    expect(create).not.toHaveBeenCalled();
    expect(update).not.toHaveBeenCalled();
  });

  it('does not let a Google account claim a staff number through the customer app', async () => {
    const admin = customer({ id: '44444444-4444-4444-4444-444444444444', firebaseUid: 'staff-uid', phone: '+919000000000', role: Role.ADMIN });
    const { service, update } = sessionSetup({ byPhone: admin });
    expect(await codeOf(service.startSession({ ...google, phone: '+919000000000' }, ClientApp.CUSTOMER))).toBe('WRONG_APP');
    expect(update).not.toHaveBeenCalled();
  });

  it('still refuses an unknown phone-less identity that is not Google', async () => {
    const { service } = sessionSetup({});
    expect(await codeOf(service.startSession({ uid: 'x', phone: null }, ClientApp.CUSTOMER))).toBe('NOT_REGISTERED');
  });
});

