import { vi } from 'vitest';
import type { PrismaService } from '../prisma/prisma.service.js';
import { OrdersService, SYSTEM_ACTOR } from './orders.service.js';

function setup() {
  const order = {
    id: 'o',
    orderNumber: 'ID1',
    status: 'PICKED_UP',
    customerId: 'c',
    totalPaise: 4500,
    revision: 0,
    deliveryFeePaise: 0,
    paidPaise: 0,
    refundedPaise: 0,
    promotion: null,
    updatedAt: new Date('2026-11-14'),
    items: [{ catalogItemId: 'shirt', name: 'Original shirt', unit: 'PIECE', unitPricePaise: 1500, quantity: 3 }],
  };
  const createMany = vi.fn();
  const updateMany = vi.fn().mockResolvedValue({ count: 1 });
  const tx = {
    order: { updateMany, findUniqueOrThrow: vi.fn().mockResolvedValue(order) },
    orderItem: { deleteMany: vi.fn(), createMany },
    orderEvent: { create: vi.fn() },
    orderAdjustment: { findFirst: vi.fn().mockResolvedValue(null) },
  };
  const prisma = {
    orderAdjustment: { findMany: vi.fn().mockResolvedValue([]) },
    order: { findUnique: vi.fn().mockResolvedValue(order) },
    catalogItem: {
      findMany: vi
        .fn()
        .mockResolvedValue([
          { id: 'shirt', name: 'Current shirt', unit: 'PIECE', pricePaise: 2000, offerPricePaise: null },
        ]),
    },
    $transaction: vi.fn((fn) => fn(tx)),
  };
  const service = new OrdersService(
    prisma as unknown as PrismaService,
    {} as never,
    {} as never,
    { emit: vi.fn() } as never,
    { now: () => new Date('2026-11-14') } as never,
    {} as never,
  );
  return { service, order, createMany, updateMany };
}

describe('item replacement', () => {
  it('keeps the accepted rate when quantities decrease after catalogue prices change', async () => {
    const { service, createMany } = setup();
    await service.updateItems('o', [{ catalogItemId: 'shirt', quantity: 2 }], SYSTEM_ACTOR);
    expect(createMany.mock.calls[0][0].data[0]).toMatchObject({
      quantity: 2,
      unitPricePaise: 1500,
      lineTotalPaise: 3000,
    });
  });
  it('refuses an edit started from an older bill revision', async () => {
    const { service } = setup();
    await expect(
      service.updateItems('o', [{ catalogItemId: 'shirt', quantity: 2 }], SYSTEM_ACTOR, undefined, 7),
    ).rejects.toMatchObject({ code: 'ORDER_CHANGED' });
  });
  it('refuses a replacement when another write won the revision race', async () => {
    const { service, updateMany, createMany } = setup();
    updateMany.mockResolvedValue({ count: 0 });
    await expect(
      service.updateItems('o', [{ catalogItemId: 'shirt', quantity: 2 }], SYSTEM_ACTOR),
    ).rejects.toMatchObject({ code: 'ORDER_CHANGED' });
    expect(createMany).not.toHaveBeenCalled();
  });
});
