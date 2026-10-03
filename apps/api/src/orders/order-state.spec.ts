import { OrderStatus } from '../generated/prisma/enums.js';
import { canTransition, isFinal, nextStatuses, TRANSITIONS } from './order-state.js';

const S = OrderStatus;

describe('order state machine', () => {
  it('walks the happy path', () => {
    expect(canTransition(S.PENDING, S.PICKUP_ASSIGNED, 'SYSTEM')).toBe(true);
    expect(canTransition(S.PICKUP_ASSIGNED, S.PICKED_UP, 'DRIVER')).toBe(true);
    expect(canTransition(S.PICKED_UP, S.PROCESSING, 'ADMIN')).toBe(true);
    expect(canTransition(S.PROCESSING, S.READY_FOR_DELIVERY, 'ADMIN')).toBe(true);
    expect(canTransition(S.READY_FOR_DELIVERY, S.DELIVERY_ASSIGNED, 'SYSTEM')).toBe(true);
    expect(canTransition(S.DELIVERY_ASSIGNED, S.OUT_FOR_DELIVERY, 'DRIVER')).toBe(true);
    expect(canTransition(S.OUT_FOR_DELIVERY, S.DELIVERED, 'DRIVER')).toBe(true);
  });

  it('lets customers cancel only before pickup', () => {
    expect(canTransition(S.PENDING, S.CANCELLED, 'CUSTOMER')).toBe(true);
    expect(canTransition(S.PICKUP_ASSIGNED, S.CANCELLED, 'CUSTOMER')).toBe(true);
    expect(canTransition(S.PICKED_UP, S.CANCELLED, 'CUSTOMER')).toBe(false);
  });

  it('does not let drivers skip steps or assign themselves directly', () => {
    expect(canTransition(S.PENDING, S.PICKUP_ASSIGNED, 'DRIVER')).toBe(false);
    expect(canTransition(S.PICKUP_ASSIGNED, S.DELIVERED, 'DRIVER')).toBe(false);
    expect(canTransition(S.PICKED_UP, S.PROCESSING, 'DRIVER')).toBe(false);
  });

  it('never leaves a final status', () => {
    for (const actor of ['CUSTOMER', 'DRIVER', 'ADMIN', 'SYSTEM'] as const) {
      expect(nextStatuses(S.DELIVERED, actor)).toEqual([]);
      expect(nextStatuses(S.CANCELLED, actor)).toEqual([]);
    }
    expect(isFinal(S.DELIVERED)).toBe(true);
    expect(isFinal(S.PROCESSING)).toBe(false);
  });

  it('lets an admin cancel any non-final order', () => {
    for (const status of Object.values(S)) {
      if (isFinal(status)) continue;
      expect(canTransition(status, S.CANCELLED, 'ADMIN')).toBe(true);
    }
  });

  it('has an entry for every status', () => {
    expect(Object.keys(TRANSITIONS).sort()).toEqual(Object.values(S).sort());
  });
});
