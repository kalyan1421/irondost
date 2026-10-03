"use client";

import { MapPin, Plus } from "lucide-react";
import { useState } from "react";
import { ErrorState } from "@/components/page";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import type { Address } from "@/lib/api/types";
import { AddressDialog } from "@/app/(app)/customers/_components/address-dialog";

/** The API allows up to this many saved addresses per customer. */
const MAX_ADDRESSES = 10;

/** Choose where the clothes are picked up from and delivered back to, or add a new address inline. */
export function AddressStep({
  customerId,
  addresses,
  value,
  onChange,
}: {
  customerId: string | null;
  addresses: { data?: Address[]; isError: boolean; error: unknown; refetch: () => unknown };
  value: string | null;
  onChange: (addressId: string) => void;
}) {
  const [adding, setAdding] = useState(false);

  if (!customerId) return <p className="text-sm text-muted-foreground">Choose a customer first. Their saved addresses appear here.</p>;
  if (addresses.isError) return <ErrorState error={addresses.error} onRetry={() => void addresses.refetch()} />;
  if (!addresses.data) return <Skeleton className="h-20" />;

  const list = addresses.data;
  const dialog = adding ? (
    <AddressDialog
      customerId={customerId}
      firstAddress={list.length === 0}
      onClose={() => setAdding(false)}
      onSaved={(a) => onChange(a.id)}
    />
  ) : null;

  if (list.length === 0) {
    return (
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-dashed p-4">
        <p className="flex items-start gap-2 text-sm text-muted-foreground">
          <MapPin className="mt-0.5 size-4 shrink-0" />
          This customer has no saved addresses. Add the pickup address to continue.
        </p>
        <Button size="sm" onClick={() => setAdding(true)}>
          <Plus /> Add address
        </Button>
        {dialog}
      </div>
    );
  }

  return (
    <div className="grid gap-3">
      <fieldset className="grid gap-2 sm:grid-cols-2">
        <legend className="sr-only">Pickup and delivery address</legend>
        {list.map((a) => {
          const id = `order-address-${a.id}`;
          return (
            <Label
              key={a.id}
              htmlFor={id}
              className="cursor-pointer items-start gap-3 rounded-lg border p-3 font-normal leading-normal transition-colors hover:bg-accent/40 has-checked:border-primary has-checked:bg-primary/5 has-focus-visible:ring-3 has-focus-visible:ring-ring/50"
            >
              <input
                type="radio"
                id={id}
                name="order-address"
                className="mt-1 accent-primary outline-none"
                checked={value === a.id}
                onChange={() => onChange(a.id)}
              />
              <span className="grid min-w-0 gap-1">
                <span className="flex flex-wrap items-center gap-1.5 font-medium">
                  {a.label}
                  {a.isPrimary ? <Badge variant="secondary">Primary</Badge> : null}
                </span>
                <span className="text-sm text-muted-foreground">{a.formatted}</span>
              </span>
            </Label>
          );
        })}
      </fieldset>
      <div className="flex flex-wrap items-center gap-3">
        <Button variant="outline" size="sm" disabled={list.length >= MAX_ADDRESSES} onClick={() => setAdding(true)}>
          <Plus /> Add another address
        </Button>
        <span className="text-xs text-muted-foreground">The clothes are delivered back to the same address.</span>
      </div>
      {dialog}
    </div>
  );
}
