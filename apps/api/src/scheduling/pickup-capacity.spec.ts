import { vi } from 'vitest';
import { AppError } from '../common/errors.js';
import { toDbDate } from '../common/time.js';
import { OrderStatus, TimeSlot } from '../generated/prisma/enums.js';
import type { PrismaService, Tx } from '../prisma/prisma.service.js';
import { CAPACITY_STATUSES, fullPickupWindows, isFull, reservePickupWindow } from './pickup-capacity.js';
import { windowKey } from './schedule-rules.js';

const DAY = '2026-11-20';

describe('isFull', () => {
  it('is full at the capacity, not before', () => {
    expect(isFull(7, 8)).toBe(false);
    expect(isFull(8, 8)).toBe(true);
    expect(isFull(9, 8)).toBe(true);
  });
  it('is never full without a cap', () => {
    expect(isFull(10_000, null)).toBe(false);
  });
});

describe('the orders that use a place', () => {
  it('are the ones still waiting to be collected', () => {
    expect([...CAPACITY_STATUSES].sort()).toEqual([OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED].sort());
  });
});

describe('fullPickupWindows', () => {
  const prismaWith = (rows: { pickupDate: Date; pickupSlot: TimeSlot; _count: { _all: number } }[]) => {
    const groupBy = vi.fn().mockResolvedValue(rows);
    return { prisma: { order: { groupBy } } as unknown as Pick<PrismaService, 'order'>, groupBy };
  };

  it('lists the windows at or over the cap, as date and slot keys', async () => {
    const { prisma, groupBy } = prismaWith([
      { pickupDate: toDbDate(DAY), pickupSlot: TimeSlot.MORNING, _count: { _all: 8 } },
      { pickupDate: toDbDate(DAY), pickupSlot: TimeSlot.NOON, _count: { _all: 7 } },
      { pickupDate: toDbDate('2026-11-21'), pickupSlot: TimeSlot.EVENING, _count: { _all: 12 } },
    ]);
    const full = await fullPickupWindows(prisma, DAY, '2026-11-26', 8);
    expect([...full].sort()).toEqual([windowKey(DAY, TimeSlot.MORNING), windowKey('2026-11-21', TimeSlot.EVENING)].sort());
    const where = groupBy.mock.calls[0][0].where;
    expect(where.status.in).toEqual(expect.arrayContaining([OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED]));
    expect(where.status.in).toHaveLength(2);
  });

  it('does not even ask the database when there is no cap', async () => {
    const { prisma, groupBy } = prismaWith([]);
    expect((await fullPickupWindows(prisma, DAY, DAY, null)).size).toBe(0);
    expect(groupBy).not.toHaveBeenCalled();
  });
});

describe('reservePickupWindow', () => {
  const txWith = (used: number) => {
    const executeRaw = vi.fn().mockResolvedValue(1);
    const count = vi.fn().mockResolvedValue(used);
    return { tx: { $executeRaw: executeRaw, order: { count } } as unknown as Tx, executeRaw, count };
  };

  it('takes the window lock before it counts', async () => {
    const { tx, executeRaw, count } = txWith(3);
    const order: string[] = [];
    executeRaw.mockImplementation(async () => void order.push('lock'));
    count.mockImplementation(async () => (order.push('count'), 3));
    await expect(reservePickupWindow(tx, DAY, TimeSlot.MORNING, 8)).resolves.toEqual({ overrode: false });
    expect(order).toEqual(['lock', 'count']);
  });

  it('counts only that window, only the waiting orders, and not the order being moved', async () => {
    const { tx, count } = txWith(0);
    await reservePickupWindow(tx, DAY, TimeSlot.NOON, 8, { excludeOrderId: 'order-1' });
    expect(count).toHaveBeenCalledWith({
      where: { pickupDate: toDbDate(DAY), pickupSlot: TimeSlot.NOON, status: { in: expect.arrayContaining([OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED]) }, id: { not: 'order-1' } },
    });
  });

  it('refuses a full window with SLOT_FULL', async () => {
    const { tx } = txWith(8);
    const e = await reservePickupWindow(tx, DAY, TimeSlot.MORNING, 8).catch((err: unknown) => err);
    expect(e).toBeInstanceOf(AppError);
    expect((e as AppError).code).toBe('SLOT_FULL');
    expect((e as AppError).getStatus()).toBe(409);
    expect((e as AppError).details).toEqual({ date: DAY, slot: TimeSlot.MORNING });
  });

  it('lets staff book into a full window and says they did', async () => {
    const { tx } = txWith(8);
    await expect(reservePickupWindow(tx, DAY, TimeSlot.MORNING, 8, { allowFull: true })).resolves.toEqual({ overrode: true });
    const room = txWith(2);
    await expect(reservePickupWindow(room.tx, DAY, TimeSlot.MORNING, 8, { allowFull: true })).resolves.toEqual({ overrode: false });
  });

  it('does nothing, not even a lock, when there is no cap', async () => {
    const { tx, executeRaw, count } = txWith(100);
    await expect(reservePickupWindow(tx, DAY, TimeSlot.MORNING, null)).resolves.toEqual({ overrode: false });
    expect(executeRaw).not.toHaveBeenCalled();
    expect(count).not.toHaveBeenCalled();
  });

  it('locks each window on its own key', async () => {
    const a = txWith(0);
    const b = txWith(0);
    await reservePickupWindow(a.tx, DAY, TimeSlot.MORNING, 8);
    await reservePickupWindow(b.tx, DAY, TimeSlot.NOON, 8);
    const keyOf = (m: ReturnType<typeof vi.fn>) => m.mock.calls[0].slice(1)[0];
    expect(keyOf(a.executeRaw)).toBe(`pickup-window:${DAY}|MORNING`);
    expect(keyOf(b.executeRaw)).toBe(`pickup-window:${DAY}|NOON`);
  });
});
