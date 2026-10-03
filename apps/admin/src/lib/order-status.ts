import type { OrderStatus, PaymentStatus } from "@/lib/api/types";

interface StatusMeta {
  label: string;
  /** Short phrase for what happens next, shown in lists. */
  hint: string;
  className: string;
}

/** Lifecycle order, used for tabs and sorting. */
export const ORDER_STATUSES: OrderStatus[] = [
  "PENDING",
  "PICKUP_ASSIGNED",
  "PICKED_UP",
  "PROCESSING",
  "READY_FOR_DELIVERY",
  "DELIVERY_ASSIGNED",
  "OUT_FOR_DELIVERY",
  "DELIVERED",
  "CANCELLED",
];

export const STATUS: Record<OrderStatus, StatusMeta> = {
  PENDING: {
    label: "Awaiting pickup partner",
    hint: "Finding a partner",
    className: "bg-amber-100 text-amber-900 ring-amber-600/20 dark:bg-amber-400/10 dark:text-amber-300 dark:ring-amber-400/20",
  },
  PICKUP_ASSIGNED: {
    label: "Pickup assigned",
    hint: "Partner on the way",
    className: "bg-sky-100 text-sky-900 ring-sky-600/20 dark:bg-sky-400/10 dark:text-sky-300 dark:ring-sky-400/20",
  },
  PICKED_UP: {
    label: "Picked up",
    hint: "Heading to workshop",
    className: "bg-indigo-100 text-indigo-900 ring-indigo-600/20 dark:bg-indigo-400/10 dark:text-indigo-300 dark:ring-indigo-400/20",
  },
  PROCESSING: {
    label: "At workshop",
    hint: "Being ironed",
    className: "bg-violet-100 text-violet-900 ring-violet-600/20 dark:bg-violet-400/10 dark:text-violet-300 dark:ring-violet-400/20",
  },
  READY_FOR_DELIVERY: {
    label: "Ready for delivery",
    hint: "Finding a partner",
    className: "bg-teal-100 text-teal-900 ring-teal-600/20 dark:bg-teal-400/10 dark:text-teal-300 dark:ring-teal-400/20",
  },
  DELIVERY_ASSIGNED: {
    label: "Delivery assigned",
    hint: "Partner collecting",
    className: "bg-cyan-100 text-cyan-900 ring-cyan-600/20 dark:bg-cyan-400/10 dark:text-cyan-300 dark:ring-cyan-400/20",
  },
  OUT_FOR_DELIVERY: {
    label: "Out for delivery",
    hint: "On the way to customer",
    className: "bg-blue-100 text-blue-900 ring-blue-600/20 dark:bg-blue-400/10 dark:text-blue-300 dark:ring-blue-400/20",
  },
  DELIVERED: {
    label: "Delivered",
    hint: "Complete",
    className: "bg-emerald-100 text-emerald-900 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-300 dark:ring-emerald-400/20",
  },
  CANCELLED: {
    label: "Cancelled",
    hint: "Cancelled",
    className: "bg-zinc-100 text-zinc-700 ring-zinc-500/20 dark:bg-zinc-400/10 dark:text-zinc-400 dark:ring-zinc-400/20",
  },
};

/** Verb shown on the button that moves an order to this status. */
export const ACTION_LABEL: Partial<Record<OrderStatus, string>> = {
  PICKED_UP: "Mark picked up",
  PROCESSING: "Received at workshop",
  READY_FOR_DELIVERY: "Ready for delivery",
  OUT_FOR_DELIVERY: "Mark out for delivery",
  DELIVERED: "Mark delivered",
  PENDING: "Back to awaiting pickup",
  CANCELLED: "Cancel order",
};

export const PAYMENT: Record<PaymentStatus, { label: string; className: string }> = {
  UNPAID: { label: "Unpaid", className: "text-amber-700 dark:text-amber-300" },
  PARTIALLY_PAID: { label: "Part paid", className: "text-amber-700 dark:text-amber-300" },
  PAID: { label: "Paid", className: "text-emerald-700 dark:text-emerald-300" },
  REFUNDED: { label: "Refunded", className: "text-muted-foreground" },
};

/** Tabs on the orders board. */
export const ORDER_TABS: { key: string; label: string; statuses: OrderStatus[] }[] = [
  { key: "active", label: "Active", statuses: ORDER_STATUSES.filter((s) => s !== "DELIVERED" && s !== "CANCELLED") },
  { key: "pickup", label: "Pickups", statuses: ["PENDING", "PICKUP_ASSIGNED"] },
  { key: "workshop", label: "At workshop", statuses: ["PICKED_UP", "PROCESSING"] },
  { key: "delivery", label: "Deliveries", statuses: ["READY_FOR_DELIVERY", "DELIVERY_ASSIGNED", "OUT_FOR_DELIVERY"] },
  { key: "done", label: "Delivered", statuses: ["DELIVERED"] },
  { key: "cancelled", label: "Cancelled", statuses: ["CANCELLED"] },
  { key: "all", label: "All", statuses: [] },
];
