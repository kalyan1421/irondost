import { AppError } from '../common/errors.js';
import { fromDbDate, toDbDate } from '../common/time.js';
import { OrderStatus, type TimeSlot } from '../generated/prisma/enums.js';
import type { PrismaService, Tx } from '../prisma/prisma.service.js';
import { windowKey } from './schedule-rules.js';

/**
 * Pickup capacity: how many pickups one window (a pickup date and a slot) takes. A window is used by the orders that are
 * still waiting to be collected on it: PENDING (no partner yet) and PICKUP_ASSIGNED (a partner is coming). Picked-up,
 * delivered and cancelled orders no longer use a place. The limit is `business_settings.pickup_capacity_per_slot`;
 * null means no limit.
 */
export const CAPACITY_STATUSES: readonly OrderStatus[] = [OrderStatus.PENDING, OrderStatus.PICKUP_ASSIGNED];

export const SLOT_FULL_MESSAGE = 'That pickup time just filled up. Please pick another time.';

/** Whether a window already holding `used` pickups has no place left under `capacity`. */
export function isFull(used: number, capacity: number | null): boolean {
  return capacity !== null && used >= capacity;
}

/**
 * The windows between two IST dates (inclusive) that have no place left, as `windowKey`s. One grouped query for the whole
 * range, so listing a week of slots costs the same as listing one.
 */
export async function fullPickupWindows(
  prisma: Pick<PrismaService, 'order'>,
  from: string,
  to: string,
  capacity: number | null,
): Promise<Set<string>> {
  const full = new Set<string>();
  if (capacity === null) return full;
  const rows = await prisma.order.groupBy({
    by: ['pickupDate', 'pickupSlot'],
    where: { status: { in: [...CAPACITY_STATUSES] }, pickupDate: { gte: toDbDate(from), lte: toDbDate(to) } },
    _count: { _all: true },
  });
  for (const row of rows) {
    if (isFull(row._count._all, capacity)) full.add(windowKey(fromDbDate(row.pickupDate), row.pickupSlot));
  }
  return full;
}

export interface ReserveOptions {
  /** Staff may book into a full window with a reason; the caller stores it. */
  allowFull?: boolean;
  /** The order being moved: it holds a place in its old window, never in the new one, but it is not counted either way. */
  excludeOrderId?: string;
}

/**
 * Takes the place for a booking or a reschedule, inside the caller's transaction. Two requests for the last place in a window
 * cannot both succeed: the first takes a transaction-scoped advisory lock on the window, counts, and writes its order; the
 * second waits for the lock, which is released when the first commits, so it counts that order and is refused. Windows lock
 * independently, so unrelated bookings never wait for each other.
 *
 * Returns `overrode: true` when the window was already full and staff booked into it anyway. Throws SLOT_FULL otherwise.
 */
export async function reservePickupWindow(
  tx: Tx,
  date: string,
  slot: TimeSlot,
  capacity: number | null,
  options: ReserveOptions = {},
): Promise<{ overrode: boolean }> {
  if (capacity === null) return { overrode: false };
  // $executeRaw because the function returns void, which Prisma cannot read back as a row.
  await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`pickup-window:${windowKey(date, slot)}`}, 0))`;
  const used = await tx.order.count({
    where: {
      pickupDate: toDbDate(date),
      pickupSlot: slot,
      status: { in: [...CAPACITY_STATUSES] },
      ...(options.excludeOrderId ? { id: { not: options.excludeOrderId } } : {}),
    },
  });
  if (!isFull(used, capacity)) return { overrode: false };
  if (options.allowFull) return { overrode: true };
  throw AppError.conflict('SLOT_FULL', SLOT_FULL_MESSAGE, { date, slot });
}
