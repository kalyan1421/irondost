"use client";

import { AlertTriangle, Pencil, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Field } from "@/components/page";
import { ActiveDot } from "@/components/status";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { api, explainErrors, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { User } from "@/lib/api/types";
import { date, phone } from "@/lib/format";
import { EMAIL_RE } from "../../_components/add-customer-dialog";
import { isValidMobile, MOBILE_HINT, MobileInput, toLocalMobile } from "@/components/mobile-input";

export function ProfileCard({ customer }: { customer: User }) {
  const [editing, setEditing] = useState(false);
  const router = useRouter();

  // For a customer who asked us to delete their account because they cannot open the app (the website's delete-account page).
  const remove = useApiMutation(
    () =>
      explainErrors(unwrap(api.DELETE("/v1/admin/customers/{id}", { params: { path: { id: customer.id } } })), {
        ACTIVE_ORDERS: "This customer has orders in progress. Deliver or cancel them first, then delete the account.",
      }),
    {
      invalidate: [["customers"]],
      success: "Account deleted",
      onSuccess: () => router.replace("/customers"),
    },
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Profile</CardTitle>
        <CardAction className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => setEditing(true)}>
            <Pencil /> Edit profile
          </Button>
          <ConfirmDialog
            destructive
            title="Delete this customer's account?"
            confirmLabel="Delete account"
            description="Use this when the customer has asked us to delete their account and cannot do it in the app. Check it is them first, for example by calling the number on the account. Their name, number, email, addresses and notifications are erased and they are signed out. Past orders stay in the records without their details. This cannot be undone."
            trigger={
              <Button variant="outline" size="sm" className="text-destructive">
                <Trash2 /> Delete account
              </Button>
            }
            onConfirm={() => remove.mutateAsync(undefined)}
          />
        </CardAction>
      </CardHeader>
      <CardContent>
        <dl className="grid gap-4 sm:grid-cols-2">
          <Field label="Name">{customer.name ?? <span className="text-muted-foreground">Not given yet</span>}</Field>
          <Field label="Mobile">
            <a href={`tel:${customer.phone}`} className="tabular hover:underline">
              {phone(customer.phone)}
            </a>
          </Field>
          <Field label="Email">
            {customer.email ? (
              <a href={`mailto:${customer.email}`} className="break-all hover:underline">
                {customer.email}
              </a>
            ) : (
              <span className="text-muted-foreground">Not given</span>
            )}
          </Field>
          <Field label="Customer since">{date(customer.createdAt)}</Field>
          <Field label="Status" className="sm:col-span-2">
            <ActiveDot active={customer.isActive} on="Active" off="Inactive: cannot sign in or get new orders" />
          </Field>
        </dl>
      </CardContent>
      {editing ? <EditProfileDialog customer={customer} onClose={() => setEditing(false)} /> : null}
    </Card>
  );
}

function EditProfileDialog({ customer, onClose }: { customer: User; onClose: () => void }) {
  const [name, setName] = useState(customer.name ?? "");
  const [email, setEmail] = useState(customer.email ?? "");
  const [mobile, setMobile] = useState(toLocalMobile(customer.phone));
  const [active, setActive] = useState(customer.isActive);
  const [phoneTouched, setPhoneTouched] = useState(false);

  const nameOk = name.trim().length >= 2;
  const phoneOk = isValidMobile(mobile);
  const trimmedEmail = email.trim();
  const emailOk = trimmedEmail === "" || EMAIL_RE.test(trimmedEmail);
  const phoneChanged = phoneOk && `+91${mobile}` !== customer.phone;
  const valid = nameOk && phoneOk && emailOk;

  const save = useApiMutation(
    () =>
      unwrap(
        api.PATCH("/v1/admin/customers/{id}", {
          params: { path: { id: customer.id } },
          body: {
            name: name.trim(),
            isActive: active,
            ...(trimmedEmail !== (customer.email ?? "") ? { email: trimmedEmail || null } : {}),
            ...(phoneChanged ? { phone: mobile } : {}),
          },
        }),
      ),
    {
      invalidate: [["customer", customer.id], ["customers"]],
      success: "Profile updated",
      onSuccess: onClose,
    },
  );

  const showPhoneError = !phoneOk && (phoneTouched || mobile.length === 10);

  return (
    <Dialog open onOpenChange={(o) => !o && !save.isPending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Edit profile</DialogTitle>
          <DialogDescription>{customer.name ?? phone(customer.phone)}</DialogDescription>
        </DialogHeader>
        <form
          className="grid gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            if (valid && !save.isPending) save.mutate(undefined);
          }}
        >
          <div className="grid gap-1.5">
            <Label htmlFor="profile-name">Name</Label>
            <Input id="profile-name" autoComplete="off" maxLength={80} value={name} onChange={(e) => setName(e.target.value)} />
            {!nameOk && name.length > 0 ? <p className="text-xs text-destructive">Enter at least 2 characters.</p> : null}
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="profile-phone">Mobile number</Label>
            <MobileInput
              id="profile-phone"
              value={mobile}
              onChange={setMobile}
              onBlur={() => setPhoneTouched(true)}
              invalid={showPhoneError}
            />
            {showPhoneError ? <p className="text-xs text-destructive">{MOBILE_HINT}</p> : null}
          </div>
          {phoneChanged ? (
            <Alert>
              <AlertTriangle />
              <AlertDescription>
                Changing the number signs this customer out of the app. They sign in again with an OTP sent to the new number.
              </AlertDescription>
            </Alert>
          ) : null}
          <div className="grid gap-1.5">
            <Label htmlFor="profile-email">
              Email <span className="font-normal text-muted-foreground">(optional)</span>
            </Label>
            <Input
              id="profile-email"
              type="email"
              autoComplete="off"
              placeholder="name@example.com"
              value={email}
              aria-invalid={!emailOk || undefined}
              onChange={(e) => setEmail(e.target.value)}
            />
            {!emailOk ? (
              <p className="text-xs text-destructive">
                Enter a valid email address.
              </p>
            ) : null}
          </div>
          <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
            <div className="grid gap-1">
              <Label htmlFor="profile-active">Active</Label>
              <p className="text-xs text-muted-foreground">Inactive customers cannot sign in to the app, and new orders cannot be placed for them.</p>
            </div>
            <Switch id="profile-active" checked={active} onCheckedChange={setActive} />
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose} disabled={save.isPending}>
              Close
            </Button>
            <Button type="submit" disabled={!valid || save.isPending}>
              {save.isPending ? "Saving…" : "Save profile"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
