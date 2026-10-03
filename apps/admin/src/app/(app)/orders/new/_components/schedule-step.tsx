"use client";

import { ErrorState } from "@/components/page";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import type { SlotOption, TimeSlot } from "@/lib/api/types";
import { calendarDate } from "@/lib/format";

export type SlotChoice = { date: string; slot: TimeSlot; label: string };

type SlotsQuery = { data?: SlotOption[]; isError: boolean; error: unknown; refetch: () => unknown };

const SLOT_NAME: Record<TimeSlot, string> = { MORNING: "Morning", NOON: "Afternoon", EVENING: "Evening" };

/** True when `choice` is still one of the bookable options. */
export function isBookable(choice: SlotChoice | null, options: SlotOption[] | undefined): boolean {
  return Boolean(choice && options?.some((o) => o.date === choice.date && o.slot === choice.slot && o.available));
}

/** Pickup slot first; delivery options depend on it. */
export function ScheduleStep({
  pickupSlots,
  deliverySlots,
  pickup,
  delivery,
  onPickup,
  onDelivery,
}: {
  pickupSlots: SlotsQuery;
  deliverySlots: SlotsQuery;
  pickup: SlotChoice | null;
  delivery: SlotChoice | null;
  onPickup: (s: SlotChoice) => void;
  onDelivery: (s: SlotChoice) => void;
}) {
  const pickupGone = pickup !== null && pickupSlots.data !== undefined && !isBookable(pickup, pickupSlots.data);
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
          <SlotGrid name="pickup-slot" legend="Pickup slot" options={pickupSlots.data} value={pickup} onChange={onPickup} />
        )}
        {pickupGone ? <p className="text-xs text-destructive">The chosen pickup slot is no longer available. Choose another.</p> : null}
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
}: {
  name: string;
  legend: string;
  options: SlotOption[];
  value: SlotChoice | null;
  onChange: (s: SlotChoice) => void;
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
                    disabled={!o.available}
                    onChange={() => onChange({ date: o.date, slot: o.slot, label: o.label })}
                  />
                  <span className="text-xs text-muted-foreground">{SLOT_NAME[o.slot]}</span>
                  <span className="tabular text-xs font-medium sm:text-sm">{o.label}</span>
                  <span className="sr-only">
                    , {calendarDate(o.date)}
                    {o.available ? "" : ", not available"}
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
