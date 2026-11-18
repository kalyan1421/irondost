"use client";

import { ErrorState } from "@/components/page";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import type { SlotOption, TimeSlot } from "@/lib/api/types";
import { calendarDate } from "@/lib/format";

export type SlotChoice = { date: string; slot: TimeSlot; label: string };

type SlotsQuery = { data?: SlotOption[]; isError: boolean; error: unknown; refetch: () => unknown };

const SLOT_NAME: Record<TimeSlot, string> = { MORNING: "Morning", NOON: "Afternoon", EVENING: "Evening" };

/** The shortest reason staff must type to book into a full window. */
export const CAPACITY_REASON_MIN = 5;
export const CAPACITY_REASON_MAX = 300;

/** True when `choice` is still one of the bookable options. With `allowFull`, a window that is only full counts too (staff override). */
export function isBookable(choice: SlotChoice | null, options: SlotOption[] | undefined, allowFull = false): boolean {
  return Boolean(
    choice && options?.some((o) => o.date === choice.date && o.slot === choice.slot && (o.available || (allowFull && o.reason === "FULL"))),
  );
}

/** True when `choice` is a window with no place left: booking it needs the override reason. */
export function isFullChoice(choice: SlotChoice | null, options: SlotOption[] | undefined): boolean {
  return Boolean(choice && options?.some((o) => o.date === choice.date && o.slot === choice.slot && o.reason === "FULL"));
}

/** Pickup slot first; delivery options depend on it. */
export function ScheduleStep({
  pickupSlots,
  deliverySlots,
  pickup,
  delivery,
  onPickup,
  onDelivery,
  allowFull = false,
  onAllowFull,
  capacityReason = "",
  onCapacityReason,
}: {
  pickupSlots: SlotsQuery;
  deliverySlots: SlotsQuery;
  pickup: SlotChoice | null;
  delivery: SlotChoice | null;
  onPickup: (s: SlotChoice) => void;
  onDelivery: (s: SlotChoice) => void;
  /** Staff override: full pickup windows can be chosen, with a typed reason. */
  allowFull?: boolean;
  onAllowFull?: (allow: boolean) => void;
  capacityReason?: string;
  onCapacityReason?: (reason: string) => void;
}) {
  const pickupGone = pickup !== null && pickupSlots.data !== undefined && !isBookable(pickup, pickupSlots.data, allowFull);
  const anyFull = pickupSlots.data?.some((o) => o.reason === "FULL") ?? false;
  const pickupFull = isFullChoice(pickup, pickupSlots.data);
  const deliveryGone = delivery !== null && deliverySlots.data !== undefined && !isBookable(delivery, deliverySlots.data);

  return (
    <div className="grid gap-6">
      <div className="grid gap-3">
        <h3 className="text-sm font-medium">Pickup</h3>
        {pickupSlots.isError ? (
          <ErrorState error={pickupSlots.error} onRetry={() => void pickupSlots.refetch()} />
        ) : !pickupSlots.data ? (
          <Skeleton className="h-40" />
        ) : (
          <SlotGrid name="pickup-slot" legend="Pickup slot" options={pickupSlots.data} value={pickup} onChange={onPickup} allowFull={allowFull} />
        )}
        {pickupGone ? <p className="text-xs text-destructive">The chosen pickup slot is no longer available. Choose another.</p> : null}
        {anyFull && onAllowFull && onCapacityReason ? (
          <FullWindowOverride allow={allowFull} onAllow={onAllowFull} selectedFull={pickupFull} reason={capacityReason} onReason={onCapacityReason} />
        ) : null}
      </div>
      <div className="grid gap-3">
        <h3 className="text-sm font-medium">Delivery</h3>
        {!pickup ? (
          <p className="text-sm text-muted-foreground">Choose a pickup slot first. Delivery options depend on it.</p>
        ) : deliverySlots.isError ? (
          <ErrorState error={deliverySlots.error} onRetry={() => void deliverySlots.refetch()} />
        ) : !deliverySlots.data ? (
          <Skeleton className="h-40" />
        ) : deliverySlots.data.every((o) => !o.available) ? (
          <p className="text-sm text-muted-foreground">No delivery slots are open for this pickup. Choose a different pickup slot.</p>
        ) : (
          <SlotGrid name="delivery-slot" legend="Delivery slot" options={deliverySlots.data} value={delivery} onChange={onDelivery} />
        )}
        {deliveryGone ? <p className="text-xs text-destructive">The chosen delivery slot is no longer available. Choose another.</p> : null}
      </div>
    </div>
  );
}

function SlotGrid({
  name,
  legend,
  options,
  value,
  onChange,
  allowFull = false,
}: {
  name: string;
  legend: string;
  options: SlotOption[];
  value: SlotChoice | null;
  onChange: (s: SlotChoice) => void;
  allowFull?: boolean;
}) {
  const days = new Map<string, SlotOption[]>();
  for (const o of options) days.set(o.date, [...(days.get(o.date) ?? []), o]);

  return (
    <fieldset className="grid gap-2">
      <legend className="sr-only">{legend}</legend>
      {[...days].map(([day, slots]) => (
        <div key={day} className="grid items-center gap-x-3 gap-y-1.5 sm:grid-cols-[7.5rem_minmax(0,1fr)]">
          <div className="text-sm font-medium">{calendarDate(day)}</div>
          <div className="grid grid-cols-3 gap-2">
            {slots.map((o) => {
              const id = `${name}-${o.date}-${o.slot}`;
              return (
                <Label
                  key={id}
                  htmlFor={id}
                  className="cursor-pointer flex-col items-start gap-0.5 rounded-lg border px-2 py-1.5 font-normal leading-tight sm:px-2.5 transition-colors hover:bg-accent/40 has-checked:border-primary has-checked:bg-primary/10 has-disabled:cursor-not-allowed has-disabled:border-dashed has-disabled:opacity-45 has-disabled:hover:bg-transparent has-focus-visible:ring-3 has-focus-visible:ring-ring/50"
                >
                  <input
                    type="radio"
                    id={id}
                    name={name}
                    className="sr-only"
                    checked={value?.date === o.date && value.slot === o.slot}
                    disabled={!o.available && !(allowFull && o.reason === "FULL")}
                    onChange={() => onChange({ date: o.date, slot: o.slot, label: o.label })}
                  />
                  <span className="text-xs text-muted-foreground">{SLOT_NAME[o.slot]}</span>
                  <span className="tabular text-xs font-medium sm:text-sm">{o.label}</span>
                  {o.reason === "FULL" ? <span className="text-xs font-semibold text-destructive">Full</span> : null}
                  <span className="sr-only">
                    , {calendarDate(o.date)}
                    {o.reason === "FULL" ? ", full" : o.available ? "" : ", not available"}
                  </span>
                </Label>
              );
            })}
          </div>
        </div>
      ))}
    </fieldset>
  );
}

/**
 * Pickup windows hold a set number of orders. A full one is shown as Full and cannot be chosen, unless staff switch this on and type
 * why: the reason stays on the order and in the audit log.
 */
function FullWindowOverride({
  allow,
  onAllow,
  selectedFull,
  reason,
  onReason,
}: {
  allow: boolean;
  onAllow: (allow: boolean) => void;
  selectedFull: boolean;
  reason: string;
  onReason: (reason: string) => void;
}) {
  const short = selectedFull && reason.trim().length > 0 && reason.trim().length < CAPACITY_REASON_MIN;
  return (
    <div className="grid gap-3 rounded-lg border border-dashed p-3">
      <div className="flex items-start gap-2">
        <Checkbox id="allow-full-windows" className="mt-0.5" checked={allow} onCheckedChange={(v) => onAllow(v === true)} />
        <div className="grid gap-0.5">
          <Label htmlFor="allow-full-windows" className="leading-snug">
            Book into a full window anyway
          </Label>
          <p className="text-xs text-muted-foreground">Some windows are full. Switch this on to choose one; you will need to say why.</p>
        </div>
      </div>
      {allow && selectedFull ? (
        <div className="grid gap-1.5 sm:max-w-md">
          <Label htmlFor="capacity-override-reason">Why is this window being overbooked?</Label>
          <Input
            id="capacity-override-reason"
            autoComplete="off"
            maxLength={CAPACITY_REASON_MAX}
            placeholder="e.g. Customer is only free that evening"
            value={reason}
            aria-invalid={short || undefined}
            aria-describedby="capacity-override-reason-hint"
            onChange={(e) => onReason(e.target.value)}
          />
          <p id="capacity-override-reason-hint" className={short ? "text-xs text-destructive" : "text-xs text-muted-foreground"}>
            {short ? `Write at least ${CAPACITY_REASON_MIN} characters.` : "Kept on the order and in the audit log."}
          </p>
        </div>
      ) : null}
    </div>
  );
}
