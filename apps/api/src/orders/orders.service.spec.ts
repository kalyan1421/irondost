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

describe('OrdersService.place', () => {
  it.each([OrderSource.CUSTOMER_APP, OrderSource.ADMIN])('needs a verified number before taking an order (%s)', async (source) => {
    const findUnique = vi.fn().mockResolvedValue(customer());
    const settings = { get: vi.fn() };
    const service = new OrdersService({ user: { findUnique } } as unknown as PrismaService, settings as never, {} as never, {} as never, {} as never, {} as never);
    const result = await service.place('22222222-2222-2222-2222-222222222222', {} as PlaceOrderDto, source, customer()).catch((e: unknown) => e);
    expect(result).toBeInstanceOf(AppError);
    expect((result as AppError).code).toBe('PHONE_REQUIRED');
    expect(settings.get).not.toHaveBeenCalled();
  });
});
