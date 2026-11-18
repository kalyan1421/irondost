"use client";

import { CircleCheck, MapPinOff, Pencil, RotateCw, TriangleAlert } from "lucide-react";
import { useState } from "react";
import { AddressDialog } from "@/app/(app)/customers/_components/address-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import type { Address, AddressCheck } from "@/lib/api/types";

/** The shortest reason staff must type to book an address outside the service area. */
export const REASON_MIN = 5;
export const REASON_MAX = 300;

/** What the area check means for placing this order. */
export type AreaState = "checking" | "unknown" | "inside" | "needs-location" | "outside";

export function areaState(check: { data?: AddressCheck; isError: boolean }): AreaState {
  if (check.data) {
    if (!check.data.served) return "outside";
    return check.data.verified ? "inside" : "needs-location";
  }
  return check.isError ? "unknown" : "checking";
}

/** Why a phone order for this address cannot be placed yet, or null when the area allows it. */
export function areaBlocker(state: AreaState, reason: string): string | null {
  if (state === "needs-location") return "Add a map pin to the address, or use a PIN code we serve";
  if (state === "outside" && reason.trim().length < REASON_MIN) return "Type why you are booking an address outside the service area";
  return null;
}

/**
 * Under the address list: says whether the chosen address is inside the service area. A phone order needs a map pin or a served PIN
 * code. An address outside the area can still be booked, but only with a typed reason that stays on the order and in the audit log.
 */
export function AreaNotice({
  customerId,
  address,
  check,
  reason,
  onReason,
}: {
  customerId: string | null;
  address: Address | undefined;
  check: { data?: AddressCheck; isError: boolean; isFetching: boolean; refetch: () => unknown };
  reason: string;
  onReason: (reason: string) => void;
}) {
  const [editing, setEditing] = useState(false);
  if (!customerId || !address) return null;

  const state = areaState(check);
  const edit = (
    <Button type="button" variant="outline" size="sm" onClick={() => setEditing(true)}>
      <Pencil /> Edit address
    </Button>
  );
  const dialog = editing ? <AddressDialog customerId={customerId} address={address} onClose={() => setEditing(false)} /> : null;

  if (state === "checking") {
    return (
      <div aria-live="polite" className="grid gap-1.5">
        <Skeleton className="h-4 w-56" />
        <span className="sr-only">Checking the address against the service area</span>
      </div>
    );
  }

  if (state === "unknown") {
    return (
      <p role="status" className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
        <TriangleAlert className="size-4 shrink-0" />
        Could not check the service area. The server checks again when you place the order.
        <Button type="button" variant="ghost" size="sm" onClick={() => void check.refetch()} disabled={check.isFetching}>
          <RotateCw className={check.isFetching ? "animate-spin" : undefined} /> Try again
        </Button>
      </p>
    );
  }

  const area = check.data!;
  const distance = area.distanceKm !== null ? `${area.distanceKm} km from the centre` : null;

  if (state === "inside") {
    return (
      <p role="status" className="flex items-center gap-2 text-sm text-muted-foreground">
        <CircleCheck className="size-4 shrink-0 text-success" />
        Inside the service area{distance ? `, ${distance}` : ", by PIN code"}.
      </p>
    );
  }

  if (state === "needs-location") {
    return (
      <div role="alert" className="grid gap-3 rounded-lg border border-destructive/40 bg-destructive/5 p-3 text-sm">
        <p className="flex items-start gap-2 font-medium text-destructive">
          <MapPinOff className="mt-0.5 size-4 shrink-0" />
          This address cannot be checked against the service area.
        </p>
        <p>
          It has no map pin, and its PIN code {address.pincode} is not on the served list. Add a map pin to the address, or use a PIN code we serve, to place
          the order.
        </p>
        <div>{edit}</div>
        {dialog}
      </div>
    );
  }

  // Outside: bookable only with a reason.
  const short = reason.trim().length > 0 && reason.trim().length < REASON_MIN;
  const why =
    area.reason === "OUTSIDE_RADIUS"
      ? `${distance ?? "Beyond the distance limit"}, past the limit.`
      : `PIN code ${address.pincode} is not one of the served PIN codes${distance ? `, and the place is ${distance}` : ""}.`;
  return (
    <div className="grid gap-3 rounded-lg border border-warning/50 bg-warning/5 p-3 text-sm">
      <div role="status" className="grid gap-1">
        <p className="flex items-start gap-2 font-medium">
          <TriangleAlert className="mt-0.5 size-4 shrink-0" />
          This address is outside the service area.
        </p>
        <p className="text-muted-foreground">{why} Customers cannot book here. You can place the order for them if you say why.</p>
      </div>
      <div className="grid gap-1.5 sm:max-w-md">
        <Label htmlFor="outside-area-reason">Why are you booking it anyway?</Label>
        <Input
          id="outside-area-reason"
          autoComplete="off"
          maxLength={REASON_MAX}
          placeholder="e.g. Regular customer, our partner passes that way"
          value={reason}
          aria-invalid={short || undefined}
          aria-describedby="outside-area-reason-hint"
          onChange={(e) => onReason(e.target.value)}
        />
        <p id="outside-area-reason-hint" className={short ? "text-xs text-destructive" : "text-xs text-muted-foreground"}>
          {short ? `Write at least ${REASON_MIN} characters.` : "Kept on the order and in the audit log."}
        </p>
      </div>
      <div>{edit}</div>
      {dialog}
    </div>
  );
}
