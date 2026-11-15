import { vi } from 'vitest';
import type { FirebaseService } from '../auth/firebase.service.js';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import type { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from './users.service.js';

const user = (overrides: Partial<User> = {}): User => ({
  id: '22222222-2222-2222-2222-222222222222',
  firebaseUid: 'g-uid',
  phone: null,
  contactPhone: null,
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

function setup() {
  const update = vi.fn().mockImplementation(({ data }: { data: Partial<User> }) => Promise.resolve(user(data)));
  const service = new UsersService({ user: { update } } as unknown as PrismaService, {} as FirebaseService);
  return { service, update };
}

const codeOf = async (p: Promise<unknown>) => ((await p.catch((e: unknown) => e)) as AppError).code;

describe('UsersService.update — mobile number', () => {
  it('saves the number a Google customer types at checkout, without an SMS code', async () => {
    const { service, update } = setup();
    const me = await service.update(user(), { phone: '98765 43210' });
    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ contactPhone: '+919876543210' }) }),
    );
    expect(me.phone).toBe('+919876543210');
  });

  it('never writes the unique sign-in number', async () => {
    const { service, update } = setup();
    await service.update(user(), { phone: '9876543210' });
    const { data } = update.mock.calls[0][0] as { data: Record<string, unknown> };
    expect(data).not.toHaveProperty('phone');
  });

  it('leaves the number alone when the request is only about the name', async () => {
    const { service, update } = setup();
    await service.update(user({ contactPhone: '+919876543210' }), { name: 'Priya S' });
    const { data } = update.mock.calls[0][0] as { data: Record<string, unknown> };
    expect(data).not.toHaveProperty('contactPhone');
  });

  it('refuses something that is not an Indian mobile number', async () => {
    const { service, update } = setup();
    expect(await codeOf(service.update(user(), { phone: '12345' }))).toBe('INVALID_PHONE');
    expect(update).not.toHaveBeenCalled();
  });

  it('does not swap a number verified by SMS code for an unverified one', async () => {
    const { service, update } = setup();
    expect(await codeOf(service.update(user({ phone: '+919111111111' }), { phone: '9222222222' }))).toBe(
      'PHONE_VERIFIED',
    );
    expect(update).not.toHaveBeenCalled();
  });

  it('accepts the verified number again as a no-op', async () => {
    const { service, update } = setup();
    await service.update(user({ phone: '+919111111111' }), { phone: '9111111111' });
    const { data } = update.mock.calls[0][0] as { data: Record<string, unknown> };
    expect(data).not.toHaveProperty('contactPhone');
  });

  it('leaves staff numbers to administrators', async () => {
    const { service, update } = setup();
    expect(
      await codeOf(service.update(user({ role: Role.DRIVER, phone: '+919111111111' }), { phone: '9222222222' })),
    ).toBe('PHONE_MANAGED');
    expect(update).not.toHaveBeenCalled();
  });
});
