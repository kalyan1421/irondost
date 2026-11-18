import { vi } from 'vitest';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { OrderSource, Role } from '../generated/prisma/enums.js';
import type { PrismaService } from '../prisma/prisma.service.js';
import { OrdersService } from './orders.service.js';
import type { PlaceOrderDto } from './order.dto.js';

const customer = (overrides: Partial<User> = {}): User => ({
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

function serviceFor(user: User, settings: { get: ReturnType<typeof vi.fn> }): OrdersService {
  const findUnique = vi.fn().mockResolvedValue(user);
  return new OrdersService({ user: { findUnique } } as unknown as PrismaService, settings as never, {} as never, {} as never, {} as never, {} as never);
}

describe('OrdersService.place', () => {
  it.each([OrderSource.CUSTOMER_APP, OrderSource.ADMIN])('needs a mobile number before taking an order (%s)', async (source) => {
    const settings = { get: vi.fn() };
    const service = serviceFor(customer(), settings);
    const result = await service.place('22222222-2222-2222-2222-222222222222', {} as PlaceOrderDto, source, customer()).catch((e: unknown) => e);
    expect(result).toBeInstanceOf(AppError);
    expect((result as AppError).code).toBe('PHONE_REQUIRED');
    expect(settings.get).not.toHaveBeenCalled();
  });

  it.each([
    ['a number typed at checkout', { contactPhone: '+919876543210' }],
    ['a number verified by SMS code', { phone: '+919876543210' }],
  ])('goes ahead with %s', async (_, numbers) => {
    const stop = new Error('past the phone check');
    const settings = { get: vi.fn().mockRejectedValue(stop) };
    const service = serviceFor(customer(numbers), settings);
    const result = await service.place('22222222-2222-2222-2222-222222222222', {} as PlaceOrderDto, OrderSource.CUSTOMER_APP, customer()).catch((e: unknown) => e);
    expect(result).toBe(stop);
    expect(settings.get).toHaveBeenCalled();
  });
});
