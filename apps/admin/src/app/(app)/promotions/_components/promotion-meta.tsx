import type { Promotion } from "@/lib/api/types";
import { istToday, rupees } from "@/lib/format";
import { cn } from "@/lib/utils";

export type PromotionState = "RUNNING" | "SCHEDULED" | "ENDED" | "PAUSED";

const STATE_META: Record<PromotionState, { label: string; chip: string; dot: string }> = {
  RUNNING: { label: "Running", chip: "bg-success/10 ring-success/25", dot: "bg-success" },
  SCHEDULED: { label: "Scheduled", chip: "bg-primary/10 ring-primary/20", dot: "bg-primary" },
  PAUSED: { label: "Paused", chip: "bg-warning/15 ring-warning/30", dot: "bg-warning" },
  ENDED: { label: "Ended", chip: "bg-muted ring-border", dot: "bg-muted-foreground/50" },
};

/** An ended promotion stays "Ended" even if it is also switched off: switching it on would not bring it back. */
export function promotionState(p: Pick<Promotion, "isActive" | "validFrom" | "validTo">, now: number): PromotionState {
  if (new Date(p.validTo).getTime() <= now) return "ENDED";
  if (!p.isActive) return "PAUSED";
  if (new Date(p.validFrom).getTime() > now) return "SCHEDULED";
  return "RUNNING";
}

export function StateChip({ state }: { state: PromotionState }) {
  const meta = STATE_META[state];
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium text-foreground ring-1 ring-inset",
        meta.chip,
      )}
    >
      <span className={cn("size-1.5 rounded-full", meta.dot)} aria-hidden />
      {meta.label}
    </span>
  );
}

/** "20% off, up to ₹100" or "₹50 off" */
export function discountLabel(p: Pick<Promotion, "discountType" | "discountValue" | "maxDiscountPaise">): string {
  if (p.discountType === "FLAT") return `${rupees(p.discountValue)} off`;
  return p.maxDiscountPaise ? `${p.discountValue}% off, up to ${rupees(p.maxDiscountPaise)}` : `${p.discountValue}% off`;
}

const IST_OFFSET_MS = 330 * 60_000;

/** ISO timestamp → "YYYY-MM-DDTHH:mm" in IST, for a datetime-local input. India has no daylight saving, so a fixed offset is exact. */
export function toIstInput(iso: string): string {
  return new Date(new Date(iso).getTime() + IST_OFFSET_MS).toISOString().slice(0, 16);
}

/** "YYYY-MM-DDTHH:mm" read as IST → ISO timestamp, or null if incomplete. */
export function fromIstInput(value: string): string | null {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value)) return null;
  const d = new Date(`${value}:00+05:30`);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

/** A new promotion runs from the start of today to the end of the day 30 days later, in IST. */
export function defaultWindow(): { from: string; to: string } {
  const today = istToday();
  const end = new Date(`${today}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + 30);
  return { from: `${today}T00:00`, to: `${end.toISOString().slice(0, 10)}T23:59` };
}
