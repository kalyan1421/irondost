import type { OrderStatus, PaymentStatus } from "@/lib/api/types";
import { PAYMENT, STATUS } from "@/lib/order-status";
import { cn } from "@/lib/utils";

export function StatusBadge({ status, className }: { status: OrderStatus; className?: string }) {
  const meta = STATUS[status];
  return (
    <span
      className={cn(
        "inline-flex items-center whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
        meta.className,
        className,
      )}
    >
      {meta.label}
    </span>
  );
}

export function PaymentBadge({ status }: { status: PaymentStatus }) {
  const meta = PAYMENT[status];
  return <span className={cn("text-xs font-medium", meta.className)}>{meta.label}</span>;
}

/** Active / inactive dot + label. */
export function ActiveDot({ active, on = "Active", off = "Inactive" }: { active: boolean; on?: string; off?: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 text-sm">
      <span className={cn("size-2 rounded-full", active ? "bg-success" : "bg-muted-foreground/40")} />
      {active ? on : off}
    </span>
  );
}
