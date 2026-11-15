import type { components } from "@/lib/api/schema";

type S = components["schemas"];
export type Delivery = S["DeliveryDto"];
export type DeliveryStatus = S["PushDeliveryStatus"];
export type DeliveryApp = S["ClientApp"];
export type FollowUp = S["DeliveryFollowUp"];

/** What the status means for the person, not for Firebase. */
export const STATUS_META: Record<DeliveryStatus, { label: string; className: string }> = {
  NO_DEVICE: {
    label: "No phone registered",
    className: "bg-amber-100 text-amber-900 ring-amber-600/20 dark:bg-amber-400/10 dark:text-amber-300 dark:ring-amber-400/20",
  },
  FAILED: {
    label: "Not delivered",
    className: "bg-rose-100 text-rose-900 ring-rose-600/20 dark:bg-rose-400/10 dark:text-rose-300 dark:ring-rose-400/20",
  },
  PARTIAL: {
    label: "Reached some phones",
    className: "bg-orange-100 text-orange-900 ring-orange-600/20 dark:bg-orange-400/10 dark:text-orange-300 dark:ring-orange-400/20",
  },
  SENT: {
    label: "Delivered",
    className: "bg-teal-100 text-teal-900 ring-teal-600/20 dark:bg-teal-400/10 dark:text-teal-300 dark:ring-teal-400/20",
  },
};

export const APP_LABEL: Record<DeliveryApp, string> = {
  CUSTOMER: "Customer app",
  PARTNER: "Partner app",
  ADMIN: "Staff app",
};

const KIND: Record<string, string> = {
  order_placed: "Order placed",
  order_status: "Order update",
  order_updated: "Bill changed",
  order_cancelled: "Order cancelled",
  new_order: "New order",
  payment_received: "Payment",
  refund_started: "Refund",
  refund_processed: "Refund",
  refund_failed: "Refund",
  refund_needed: "Refund needed",
  price_approval: "Price approval",
  issue_update: "Customer report",
  dispatch_failed: "No partner found",
  task_assigned: "Task",
  task_removed: "Task",
  order_rescheduled: "Pickup changed",
};

/** "order_status" → "Order update"; unknown kinds read as plain words rather than a code. */
export function kindLabel(type: string): string {
  const known = KIND[type];
  if (known) return known;
  const words = type.replace(/[_-]+/g, " ").trim();
  return words ? words.charAt(0).toUpperCase() + words.slice(1) : "Alert";
}

/** The day `days` before today (IST) as YYYY-MM-DD, for the "last N days" filter. */
export function daysAgo(today: string, days: number): string {
  const d = new Date(`${today}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - days);
  return d.toISOString().slice(0, 10);
}

/** Reads a URL value, falling back when it is missing or not one of the allowed values. */
export function pick<T extends string>(value: string | null, allowed: readonly T[], fallback: T): T {
  return allowed.includes(value as T) ? (value as T) : fallback;
}
