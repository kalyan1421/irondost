"use client";

import { AlertTriangle } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { components } from "@/lib/api/schema";
import type { Driver } from "@/lib/api/types";
import { phone } from "@/lib/format";
import { isValidMobile, MobileInput, toLocalMobile } from "@/components/mobile-input";

type CreateBody = components["schemas"]["CreateDriverDto"];
type UpdateBody = components["schemas"]["UpdateDriverDto"];

interface Draft {
  mobile: string;
  name: string;
  vehicle: string;
  licence: string;
  isActive: boolean;
}

function draftFrom(driver: Driver | null): Draft {
  return {
    mobile: driver ? toLocalMobile(driver.phone) : "",
    name: driver?.name ?? "",
    vehicle: driver?.vehicleNumber ?? "",
    licence: driver?.licenseNumber ?? "",
    isActive: driver?.isActive ?? true,
  };
}

/** Registration numbers are stored upper-case without surrounding spaces. */
function clean(value: string): string {
  return value.trim().toUpperCase();
}

function errorsOf(d: Draft) {
  return {
    mobile: isValidMobile(d.mobile)
      ? null
      : d.mobile
        ? "Enter a 10-digit mobile number starting with 6, 7, 8 or 9."
        : "Enter the partner's mobile number.",
    name: d.name.trim().length >= 2 ? null : "Enter the partner's name (at least 2 letters).",
  };
}

/** Only the fields that differ from the saved partner. */
function changesOf(driver: Driver, d: Draft): UpdateBody {
  const body: UpdateBody = {};
  if (d.mobile !== toLocalMobile(driver.phone)) body.phone = d.mobile;
  if (d.name.trim() !== (driver.name ?? "")) body.name = d.name.trim();
  if (clean(d.vehicle) !== (driver.vehicleNumber ?? "")) body.vehicleNumber = clean(d.vehicle);
  if (clean(d.licence) !== (driver.licenseNumber ?? "")) body.licenseNumber = clean(d.licence);
  if (d.isActive !== driver.isActive) body.isActive = d.isActive;
  return body;
}

/** Adds a partner (no `driver`) or edits one. */
export function PartnerDialog({ driver, onClose }: { driver: Driver | null; onClose: () => void }) {
  const [draft, setDraft] = useState<Draft>(() => draftFrom(driver));
  const [tried, setTried] = useState(false);
  const set = (patch: Partial<Draft>) => setDraft((d) => ({ ...d, ...patch }));

  const create = useApiMutation((body: CreateBody) => unwrap(api.POST("/v1/admin/drivers", { body })), {
    invalidate: [["drivers"], ["dashboard"]],
    success: (u) => `${u.name ?? "Partner"} added. They can sign in to the partner app now.`,
    onSuccess: onClose,
  });
  const update = useApiMutation(
    ({ id, body }: { id: string; body: UpdateBody }) =>
      unwrap(api.PATCH("/v1/admin/drivers/{id}", { params: { path: { id } }, body })),
    {
      invalidate: [["drivers"], ["dashboard"]],
      success: (u, { body }) =>
        body.isActive === false
          ? `${u.name ?? "Partner"} deactivated`
          : body.isActive === true
            ? `${u.name ?? "Partner"} reactivated`
            : `Changes saved for ${u.name ?? "the partner"}`,
      onSuccess: onClose,
    },
  );

  const errors = errorsOf(draft);
  const valid = !errors.mobile && !errors.name;
  const changes = driver ? changesOf(driver, draft) : null;
  const hasChanges = changes ? Object.keys(changes).length > 0 : true;
  const deactivating = driver?.isActive === true && !draft.isActive;
  const phoneChanged = Boolean(driver && changes?.phone);
  const pending = create.isPending || update.isPending;
  const who = driver?.name ?? "this partner";

  function submit(e: React.FormEvent) {
    e.preventDefault();
    setTried(true);
    if (!valid) return;
    if (!driver) {
      create.mutate({
        phone: draft.mobile,
        name: draft.name.trim(),
        ...(clean(draft.vehicle) ? { vehicleNumber: clean(draft.vehicle) } : {}),
        ...(clean(draft.licence) ? { licenseNumber: clean(draft.licence) } : {}),
      });
    } else if (changes && hasChanges) {
      update.mutate({ id: driver.id, body: changes });
    }
  }

  const showMobileError = Boolean(errors.mobile) && (tried || draft.mobile.length === 10);
  const showNameError = Boolean(errors.name) && tried;

  return (
    <Dialog open onOpenChange={(o) => !o && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={submit} noValidate className="grid gap-4">
          <DialogHeader>
            <DialogTitle>{driver ? `Edit ${driver.name ?? "partner"}` : "Add delivery partner"}</DialogTitle>
            <DialogDescription>
              {driver
                ? `${phone(driver.phone)} · changes apply straight away.`
                : "They sign in to the partner app with a one-time code (OTP) sent to this number. There is no password to share."}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-1.5">
            <Label htmlFor="partner-mobile">Mobile number</Label>
            <MobileInput
              id="partner-mobile"
              value={draft.mobile}
              onChange={(mobile) => set({ mobile })}
              invalid={showMobileError}
              describedBy={showMobileError ? "partner-mobile-error" : undefined}
              autoFocus={!driver}
            />
            {showMobileError ? (
              <p id="partner-mobile-error" className="text-xs text-destructive">
                {errors.mobile}
              </p>
            ) : null}
          </div>

          <div className="grid gap-1.5">
            <Label htmlFor="partner-name">Name</Label>
            <Input
              id="partner-name"
              placeholder="e.g. Ravi Kumar"
              maxLength={80}
              value={draft.name}
              onChange={(e) => set({ name: e.target.value })}
              aria-invalid={showNameError || undefined}
              aria-describedby={showNameError ? "partner-name-error" : undefined}
            />
            {showNameError ? (
              <p id="partner-name-error" className="text-xs text-destructive">
                {errors.name}
              </p>
            ) : null}
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <Label htmlFor="partner-vehicle">Vehicle number (optional)</Label>
              <Input
                id="partner-vehicle"
                placeholder="TS09AB1234"
                maxLength={20}
                autoComplete="off"
                className="font-mono uppercase"
                value={draft.vehicle}
                onChange={(e) => set({ vehicle: e.target.value })}
              />
            </div>
            <div className="grid gap-1.5">
              <Label htmlFor="partner-licence">Licence number (optional)</Label>
              <Input
                id="partner-licence"
                maxLength={30}
                autoComplete="off"
                className="font-mono uppercase"
                value={draft.licence}
                onChange={(e) => set({ licence: e.target.value })}
              />
            </div>
          </div>

          {driver ? (
            <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
              <div className="grid gap-1">
                <Label htmlFor="partner-active">Account active</Label>
                <p id="partner-active-hint" className="text-xs text-muted-foreground">
                  Inactive partners cannot sign in to the partner app or receive orders.
                </p>
              </div>
              <Switch
                id="partner-active"
                checked={draft.isActive}
                onCheckedChange={(isActive) => set({ isActive })}
                aria-describedby="partner-active-hint"
              />
            </div>
          ) : null}

          {deactivating ? (
            <Notice>
              Deactivating takes {who} offline straight away and signs them out of the partner app.
              {driver && driver.activeLegs > 0
                ? ` Their ${driver.activeLegs} active ${driver.activeLegs === 1 ? "task stays" : "tasks stay"} assigned to them, so reassign ${driver.activeLegs === 1 ? "it" : "them"} from the order page.`
                : null}
            </Notice>
          ) : null}
          {phoneChanged ? (
            <Notice>
              Changing the number signs {who} out of the partner app. They sign in again with an OTP sent to the new number.
            </Notice>
          ) : null}

          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose} disabled={pending}>
              Cancel
            </Button>
            <Button type="submit" disabled={pending || !hasChanges}>
              {pending ? "Saving…" : !driver ? "Add partner" : deactivating ? "Save and deactivate" : "Save changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function Notice({ children }: { children: React.ReactNode }) {
  return (
    <div role="status" className="flex gap-2 rounded-lg border border-warning/40 bg-warning/10 p-3 text-sm">
      <AlertTriangle className="mt-0.5 size-4 shrink-0 text-warning" />
      <p>{children}</p>
    </div>
  );
}
