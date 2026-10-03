"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { User } from "@/lib/api/types";
import { isValidMobile, MOBILE_HINT, MobileInput, toLocalMobile } from "@/components/mobile-input";

export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Creates a customer for a phone order. They can later sign in to the app
 * with an OTP on this number and see their orders.
 */
export function AddCustomerDialog({
  initialPhone = "",
  initialName = "",
  onClose,
  onCreated,
}: {
  initialPhone?: string;
  initialName?: string;
  onClose: () => void;
  onCreated: (customer: User) => void;
}) {
  const [phone, setPhone] = useState(() => toLocalMobile(initialPhone));
  const [name, setName] = useState(initialName);
  const [email, setEmail] = useState("");
  const [touched, setTouched] = useState({ phone: false, email: false });
  // Start in the name field when a full number was carried over from a search.
  const [phoneComplete] = useState(() => isValidMobile(toLocalMobile(initialPhone)));

  const phoneOk = isValidMobile(phone);
  const nameOk = name.trim().length >= 2;
  const emailOk = email.trim() === "" || EMAIL_RE.test(email.trim());
  const valid = phoneOk && nameOk && emailOk;

  const create = useApiMutation(
    () =>
      unwrap(
        api.POST("/v1/admin/customers", {
          body: { phone, name: name.trim(), ...(email.trim() ? { email: email.trim() } : {}) },
        }),
      ),
    {
      invalidate: [["customers"]],
      success: (c) => `${c.name ?? "Customer"} added`,
      onSuccess: (c) => onCreated(c),
    },
  );

  const showPhoneError = !phoneOk && (touched.phone || phone.length === 10);
  const showEmailError = !emailOk && touched.email;

  return (
    <Dialog open onOpenChange={(o) => !o && !create.isPending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Add customer</DialogTitle>
          <DialogDescription>They can sign in to the app later with an OTP on this number to see their orders.</DialogDescription>
        </DialogHeader>
        <form
          className="grid gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            if (valid && !create.isPending && !create.isSuccess) create.mutate(undefined);
          }}
        >
          <div className="grid gap-1.5">
            <Label htmlFor="new-customer-phone">Mobile number</Label>
            <MobileInput
              id="new-customer-phone"
              value={phone}
              onChange={setPhone}
              onBlur={() => setTouched((t) => ({ ...t, phone: true }))}
              invalid={showPhoneError}
              autoFocus={!phoneComplete}
            />
            {showPhoneError ? <p className="text-xs text-destructive">{MOBILE_HINT}</p> : null}
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="new-customer-name">Name</Label>
            <Input
              id="new-customer-name"
              autoComplete="off"
              placeholder="e.g. Priya Sharma"
              maxLength={80}
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoFocus={phoneComplete}
            />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="new-customer-email">
              Email <span className="font-normal text-muted-foreground">(optional)</span>
            </Label>
            <Input
              id="new-customer-email"
              type="email"
              autoComplete="off"
              placeholder="name@example.com"
              value={email}
              aria-invalid={showEmailError || undefined}
              onBlur={() => setTouched((t) => ({ ...t, email: true }))}
              onChange={(e) => setEmail(e.target.value)}
            />
            {showEmailError ? <p className="text-xs text-destructive">Enter a valid email address, or leave it empty.</p> : null}
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose} disabled={create.isPending}>
              Close
            </Button>
            <Button type="submit" disabled={!valid || create.isPending || create.isSuccess}>
              {create.isPending ? "Adding…" : "Add customer"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
