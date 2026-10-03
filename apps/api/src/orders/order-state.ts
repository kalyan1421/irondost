import { DispatchLeg, OrderStatus, Role } from '../generated/prisma/enums.js';

/** Who is moving the order. SYSTEM = automatic dispatch. */
export type ActorKind = 'CUSTOMER' | 'DRIVER' | 'ADMIN' | 'SYSTEM';

export function actorKind(role: Role): ActorKind {
  switch (role) {
    case Role.CUSTOMER:
      return 'CUSTOMER';
    case Role.DRIVER:
      return 'DRIVER';
    case Role.ADMIN:
    case Role.SUPER_ADMIN:
      return 'ADMIN';
  }
}

const S = OrderStatus;

/**
 * The only allowed status changes, and who may make each one.
 *
 *   PENDING → PICKUP_ASSIGNED → PICKED_UP → PROCESSING → READY_FOR_DELIVERY
 *     → DELIVERY_ASSIGNED → OUT_FOR_DELIVERY → DELIVERED
 *
 * Any non-final status can be CANCELLED by an admin; customers can cancel
 * until the clothes are picked up. Assignments can be undone (driver
 * unassigned), and a failed delivery attempt goes back to READY_FOR_DELIVERY.
 */
export const TRANSITIONS: Readonly<Record<OrderStatus, Partial<Record<OrderStatus, readonly ActorKind[]>>>> = {
  [S.PENDING]: {
    [S.PICKUP_ASSIGNED]: ['SYSTEM', 'ADMIN'],
    [S.CANCELLED]: ['CUSTOMER', 'ADMIN'],
  },
  [S.PICKUP_ASSIGNED]: {
    [S.PENDING]: ['ADMIN', 'SYSTEM'],
    [S.PICKED_UP]: ['DRIVER', 'ADMIN'],
    [S.CANCELLED]: ['CUSTOMER', 'ADMIN'],
  },
  [S.PICKED_UP]: {
    [S.PROCESSING]: ['ADMIN'],
    [S.CANCELLED]: ['ADMIN'],
  },
  [S.PROCESSING]: {
    [S.READY_FOR_DELIVERY]: ['ADMIN'],
    [S.CANCELLED]: ['ADMIN'],
  },
  [S.READY_FOR_DELIVERY]: {
    [S.DELIVERY_ASSIGNED]: ['SYSTEM', 'ADMIN'],
    [S.CANCELLED]: ['ADMIN'],
  },
  [S.DELIVERY_ASSIGNED]: {
    [S.READY_FOR_DELIVERY]: ['ADMIN', 'SYSTEM'],
    [S.OUT_FOR_DELIVERY]: ['DRIVER', 'ADMIN'],
    [S.CANCELLED]: ['ADMIN'],
  },
  [S.OUT_FOR_DELIVERY]: {
    [S.DELIVERED]: ['DRIVER', 'ADMIN'],
    [S.READY_FOR_DELIVERY]: ['ADMIN'],
    [S.CANCELLED]: ['ADMIN'],
  },
  [S.DELIVERED]: {},
  [S.CANCELLED]: {},
};

export function canTransition(from: OrderStatus, to: OrderStatus, actor: ActorKind): boolean {
  return TRANSITIONS[from][to]?.includes(actor) ?? false;
}

export function nextStatuses(from: OrderStatus, actor: ActorKind): OrderStatus[] {
  return (Object.entries(TRANSITIONS[from]) as [OrderStatus, readonly ActorKind[]][])
    .filter(([, actors]) => actors.includes(actor))
    .map(([to]) => to);
}

export const FINAL_STATUSES: readonly OrderStatus[] = [S.DELIVERED, S.CANCELLED];

export function isFinal(status: OrderStatus): boolean {
  return FINAL_STATUSES.includes(status);
}

/** The status an order must be in for a driver to be assigned to that leg. */
export const AWAITING_DRIVER: Record<DispatchLeg, OrderStatus> = {
  [DispatchLeg.PICKUP]: S.PENDING,
  [DispatchLeg.DELIVERY]: S.READY_FOR_DELIVERY,
};

/** The status an order moves to once a driver takes that leg. */
export const ASSIGNED_STATUS: Record<DispatchLeg, OrderStatus> = {
  [DispatchLeg.PICKUP]: S.PICKUP_ASSIGNED,
  [DispatchLeg.DELIVERY]: S.DELIVERY_ASSIGNED,
};

/** Line items can be changed by an admin until the order leaves the workshop. */
export const ITEMS_EDITABLE: readonly OrderStatus[] = [
  S.PENDING,
  S.PICKUP_ASSIGNED,
  S.PICKED_UP,
  S.PROCESSING,
];
