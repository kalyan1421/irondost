"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Address } from "@/lib/api/types";
import { cn } from "@/lib/utils";

const PINCODE_RE = /^[1-9]\d{5}$/;
const LABELS = ["Home", "Work", "Other"];

type Form = {
  label: string;
  houseNo: string;
  building: string;
  street: string;
  area: string;
  landmark: string;
  city: string;
  state: string;
  pincode: string;
  isPrimary: boolean;
};

function initialForm(a: Address | undefined, firstAddress: boolean): Form {
  return {
    label: a?.label ?? "Home",
    houseNo: a?.houseNo ?? "",
    building: a?.building ?? "",
    street: a?.street ?? "",
    area: a?.area ?? "",
    landmark: a?.landmark ?? "",
    city: a?.city ?? "Hyderabad",
    state: a?.state ?? "Telangana",
    pincode: a?.pincode ?? "",
    isPrimary: a?.isPrimary ?? firstAddress,
  };
}

/** Add a saved address for a customer, or edit one. */
export function AddressDialog({
  customerId,
  address,
  firstAddress = false,
  onClose,
  onSaved,
}: {
  customerId: string;
  /** Omit to add a new address. */
  address?: Address;
  /** The customer has no addresses yet, so this one becomes primary. */
  firstAddress?: boolean;
  onClose: () => void;
  onSaved?: (address: Address) => void;
}) {
  const [f, setF] = useState<Form>(() => initialForm(address, firstAddress));
  const [pincodeTouched, setPincodeTouched] = useState(false);
  const set = <K extends keyof Form>(k: K, v: Form[K]) => setF((prev) => ({ ...prev, [k]: v }));

  const t = {
    label: f.label.trim(),
    houseNo: f.houseNo.trim(),
    building: f.building.trim(),
    street: f.street.trim(),
    area: f.area.trim(),
    landmark: f.landmark.trim(),
    city: f.city.trim(),
    state: f.state.trim(),
    pincode: f.pincode.trim(),
  };
  const pincodeOk = PINCODE_RE.test(t.pincode);
  const valid =
    t.label.length >= 1 && t.houseNo.length >= 1 && t.street.length >= 2 && t.city.length >= 2 && t.state.length >= 2 && pincodeOk;
  // The API never un-sets a primary address directly; another address has to be made primary instead.
  const primaryLocked = firstAddress || Boolean(address?.isPrimary);

  const save = useApiMutation(
    (): Promise<Address> => {
      if (address) {
        // Optional fields are sent even when empty so they can be cleared.
        return unwrap(
          api.PATCH("/v1/admin/customers/{id}/addresses/{addressId}", {
            params: { path: { id: customerId, addressId: address.id } },
            body: { ...t, isPrimary: f.isPrimary },
          }),
        );
      }
      return unwrap(
        api.POST("/v1/admin/customers/{id}/addresses", {
          params: { path: { id: customerId } },
          body: {
            label: t.label,
            houseNo: t.houseNo,
            street: t.street,
            city: t.city,
            state: t.state,
            pincode: t.pincode,
            isPrimary: f.isPrimary,
            ...(t.building ? { building: t.building } : {}),
            ...(t.area ? { area: t.area } : {}),
            ...(t.landmark ? { landmark: t.landmark } : {}),
          },
        }),
      );
    },
    {
      invalidate: [["customer", customerId, "addresses"]],
      success: address ? "Address updated" : "Address added",
      onSuccess: (a) => {
        onSaved?.(a);
        onClose();
      },
    },
  );

  const field = (
    k: Exclude<keyof Form, "isPrimary" | "label">,
    label: string,
    opts: { optional?: boolean; placeholder?: string; maxLength: number; className?: string },
  ) => (
    <div className={cn("grid gap-1.5", opts.className)}>
      <Label htmlFor={`addr-${k}`}>
        {label}
        {opts.optional ? <span className="font-normal text-muted-foreground">(optional)</span> : null}
      </Label>
      <Input
        id={`addr-${k}`}
        autoComplete="off"
        placeholder={opts.placeholder}
        maxLength={opts.maxLength}
        value={f[k]}
        onChange={(e) => set(k, e.target.value)}
      />
    </div>
  );

  return (
    <Dialog open onOpenChange={(o) => !o && !save.isPending && onClose()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{address ? "Edit address" : "Add address"}</DialogTitle>
          <DialogDescription>
            {address
              ? "Changes apply to future orders. Orders already placed keep the address they were booked with."
              : "Pickup partners use this to find the customer, so include a landmark if the place is hard to find."}
          </DialogDescription>
        </DialogHeader>
        <form
          className="grid gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            if (valid && !save.isPending) save.mutate(undefined);
          }}
        >
          <div className="-mx-4 grid max-h-[60vh] gap-4 overflow-y-auto px-4 py-0.5 sm:grid-cols-2">
            {field("houseNo", "House or flat number", { placeholder: "e.g. Flat 302", maxLength: 60 })}
            {field("building", "Building", { optional: true, placeholder: "e.g. Lake View Apartments", maxLength: 100 })}
            {field("street", "Street", { placeholder: "e.g. Road No. 12", maxLength: 150, className: "sm:col-span-2" })}
            {field("area", "Area", { optional: true, placeholder: "e.g. Banjara Hills", maxLength: 100 })}
            {field("landmark", "Landmark", { optional: true, placeholder: "e.g. Opposite City Centre Mall", maxLength: 150 })}
            {field("city", "City", { maxLength: 60 })}
            {field("state", "State", { maxLength: 60 })}
            <div className="grid gap-1.5">
              <Label htmlFor="addr-pincode">PIN code</Label>
              <Input
                id="addr-pincode"
                inputMode="numeric"
                autoComplete="off"
                placeholder="e.g. 500034"
                className="tabular"
                value={f.pincode}
                aria-invalid={(pincodeTouched && !pincodeOk) || undefined}
                onBlur={() => setPincodeTouched(true)}
                onChange={(e) => set("pincode", e.target.value.replace(/\D/g, "").slice(0, 6))}
              />
              {pincodeTouched && !pincodeOk ? <p className="text-xs text-destructive">Enter a 6-digit PIN code.</p> : null}
            </div>
            <div className="grid gap-1.5">
              <Label htmlFor="addr-label">Save as</Label>
              <Input
                id="addr-label"
                autoComplete="off"
                maxLength={30}
                list="addr-label-options"
                value={f.label}
                onChange={(e) => set("label", e.target.value)}
              />
              <datalist id="addr-label-options">
                {LABELS.map((l) => (
                  <option key={l} value={l} />
                ))}
              </datalist>
            </div>
            <div className="grid gap-1 sm:col-span-2">
              <div className="flex items-center gap-2">
                <Checkbox
                  id="addr-primary"
                  checked={primaryLocked || f.isPrimary}
                  disabled={primaryLocked}
                  onCheckedChange={(v) => set("isPrimary", v === true)}
                />
                <Label htmlFor="addr-primary">Make this the primary address</Label>
              </div>
              <p className="pl-6 text-xs text-muted-foreground">
                {firstAddress
                  ? "The first address is always the primary one."
                  : address?.isPrimary
                    ? "This is the primary address. To change it, make another address primary."
                    : "The primary address is picked first for new orders."}
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose} disabled={save.isPending}>
              Close
            </Button>
            <Button type="submit" disabled={!valid || save.isPending}>
              {save.isPending ? "Saving…" : address ? "Save address" : "Add address"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
