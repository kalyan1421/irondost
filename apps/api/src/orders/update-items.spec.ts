import { vi } from 'vitest';
import type { PrismaService } from '../prisma/prisma.service.js';
import { OrdersService, SYSTEM_ACTOR } from './orders.service.js';

function setup(overrides: Record<string, unknown> = {}) {
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
    travelChargePaiseRule: null,
    travelFreeFromPaiseRule: null,
    ...overrides,
  };
  const adjustmentCreate = vi.fn().mockImplementation(async ({ data }) => {
    adjustment = { id: 'adj', expiresAt: new Date('2026-11-15'), ...data };
    return adjustment;
  });
  let adjustment: Record<string, unknown> | null = null;
  const createMany = vi.fn();
  const updateMany = vi.fn().mockResolvedValue({ count: 1 });
  const tx = {
    order: { updateMany, findUniqueOrThrow: vi.fn().mockImplementation(async () => ({ ...order, adjustments: adjustment ? [adjustment] : [] })) },
    orderItem: { deleteMany: vi.fn(), createMany },
    orderEvent: { create: vi.fn() },
    orderAdjustment: { findFirst: vi.fn().mockResolvedValue(null), create: adjustmentCreate },
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
    { get: vi.fn().mockResolvedValue({ adjustmentExpiryHours: 12 }) } as never,
    {} as never,
    { emit: vi.fn() } as never,
    { now: () => new Date('2026-11-14') } as never,
    {} as never,
  );
  return { service, order, createMany, updateMany, adjustmentCreate };
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

describe('travel charge when the items change', () => {
  const shirts = (quantity: number) => [{ catalogItemId: 'shirt', quantity }];
  // Items at Rs 100 each so the Rs 200 line is easy to cross; the order was booked under charge Rs 30, free from Rs 200.
  const booked = (quantity: number, over: Record<string, unknown> = {}) => {
    const subtotal = quantity * 10_000;
    const fee = subtotal >= 20_000 ? 0 : 3000;
    return {
      subtotalPaise: subtotal,
      deliveryFeePaise: fee,
      totalPaise: subtotal + fee,
      travelChargePaiseRule: 3000,
      travelFreeFromPaiseRule: 20_000,
      items: [{ catalogItemId: 'shirt', name: 'Shirt', unit: 'PIECE', unitPricePaise: 10_000, quantity }],
      ...over,
    };
  };

  it('adds the charge when a lower count falls under Rs 200, applying the decrease at once', async () => {
    const { service, updateMany, createMany } = setup(booked(3)); // Rs 300, free: total 30000
    const preview = await service.previewItems('o', shirts(1));
    expect(preview).toMatchObject({ oldDeliveryFeePaise: 0, deliveryFeePaise: 3000, oldTotalPaise: 30_000, newTotalPaise: 13_000, requiresApproval: false });
    await service.updateItems('o', shirts(1), SYSTEM_ACTOR);
    expect(updateMany.mock.calls[0][0].data).toMatchObject({ subtotalPaise: 10_000, deliveryFeePaise: 3000, totalPaise: 13_000 });
    expect(createMany).toHaveBeenCalled();
  });

  it('removes the charge when a lower count still reaches Rs 200 and the total drops', async () => {
    // Booked at Rs 199 of clothes plus the Rs 30 charge (Rs 229); recounted as two items, Rs 200 and free: Rs 200 < Rs 229.
    const { service, updateMany } = setup(booked(1, { subtotalPaise: 19_900, deliveryFeePaise: 3000, totalPaise: 22_900 }));
    await service.updateItems('o', shirts(2), SYSTEM_ACTOR);
    expect(updateMany.mock.calls[0][0].data).toMatchObject({ subtotalPaise: 20_000, deliveryFeePaise: 0, totalPaise: 20_000 });
  });

  it('asks for approval when a higher count reaches Rs 200 but the net total still goes up, carrying the new charge', async () => {
    const { service, updateMany, adjustmentCreate } = setup(booked(1)); // Rs 100 + Rs 30 = 13000
    const actor = { id: 'staff', role: 'ADMIN', kind: 'ADMIN' } as never;
    await service.updateItems('o', shirts(3), actor); // Rs 300, free: 30000
    expect(adjustmentCreate.mock.calls[0][0].data).toMatchObject({ oldTotalPaise: 13_000, newTotalPaise: 30_000, subtotalPaise: 30_000, deliveryFeePaise: 0 });
    expect(updateMany.mock.calls[0][0].data).not.toHaveProperty('deliveryFeePaise'); // the bill changes only when the customer approves
  });

  it('shows the charge changing in the approval request when more clothes add up under the threshold', async () => {
    // 1 item booked at Rs 100 + 30; recount to 2 items = Rs 200 free: total 20000 > 13000 → approval, charge goes 30 → 0
    const { service, adjustmentCreate } = setup(booked(1));
    const actor = { id: 'staff', role: 'ADMIN', kind: 'ADMIN' } as never;
    await service.updateItems('o', shirts(2), actor);
    expect(adjustmentCreate.mock.calls[0][0].data).toMatchObject({ deliveryFeePaise: 0, newTotalPaise: 20_000 });
    const preview = await setup(booked(1)).service.previewItems('o', shirts(2));
    expect(preview).toMatchObject({ oldDeliveryFeePaise: 3000, deliveryFeePaise: 0, requiresApproval: true });
  });

  it('uses the rule frozen at booking, not today\'s settings', async () => {
    // Booked when travel was free from Rs 100 (charge Rs 50): a recount of Rs 100 is still free.
    const frozen = booked(2, { travelChargePaiseRule: 5000, travelFreeFromPaiseRule: 10_000, deliveryFeePaise: 0, totalPaise: 20_000 });
    const { service } = setup(frozen);
    expect(await service.previewItems('o', shirts(1))).toMatchObject({ deliveryFeePaise: 0, newTotalPaise: 10_000 });
  });

  it('leaves an order booked before the rule with its stored fee, whatever the new count', async () => {
    const legacy = {
      subtotalPaise: 30_000, deliveryFeePaise: 3000, totalPaise: 33_000, travelChargePaiseRule: null, travelFreeFromPaiseRule: null,
      items: [{ catalogItemId: 'shirt', name: 'Shirt', unit: 'PIECE', unitPricePaise: 10_000, quantity: 3 }],
    };
    const { service, updateMany } = setup(legacy);
    expect(await service.previewItems('o', shirts(1))).toMatchObject({ oldDeliveryFeePaise: 3000, deliveryFeePaise: 3000, newTotalPaise: 13_000 });
    await service.updateItems('o', shirts(1), SYSTEM_ACTOR);
    expect(updateMany.mock.calls[0][0].data).toMatchObject({ deliveryFeePaise: 3000 });

    const free = setup({ ...legacy, deliveryFeePaise: 0, totalPaise: 30_000 });
    expect(await free.service.previewItems('o', shirts(1))).toMatchObject({ deliveryFeePaise: 0, newTotalPaise: 10_000 });
  });

  it('counts the items total before the coupon, so a coupon cannot add the charge', async () => {
    const withCoupon = booked(3, { promotion: { id: 'p', code: 'TEN', discountType: 'PERCENT', discountValue: 10, minOrderPaise: 0, maxDiscountPaise: null } });
    const { service } = setup(withCoupon);
    // Rs 200 of clothes less a 10% coupon is Rs 180, under the threshold after the discount, yet travel stays free.
    expect(await service.previewItems('o', shirts(2))).toMatchObject({ subtotalPaise: 20_000, discountPaise: 2000, deliveryFeePaise: 0, newTotalPaise: 18_000 });
  });
});
