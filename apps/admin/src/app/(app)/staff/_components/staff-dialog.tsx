"use client";

import { AlertTriangle, Info } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import { useAuth } from "@/lib/auth/auth-provider";
import type { components } from "@/lib/api/schema";
import type { User } from "@/lib/api/types";
import { phone } from "@/lib/format";
import { isValidMobile, MobileInput } from "@/components/mobile-input";

type CreateBody = components["schemas"]["CreateStaffDto"];
type UpdateBody = components["schemas"]["UpdateStaffDto"];
export type StaffRole = CreateBody["role"];

export const ROLE_LABEL: Record<StaffRole, string> = { ADMIN: "Admin", SUPER_ADMIN: "Super admin" };

export const ROLES_EXPLAINED =
  "Admins run day-to-day operations. Super admins also manage staff, business settings and app versions.";

function staffRole(role: User["role"]): StaffRole {
  return role === "SUPER_ADMIN" ? "SUPER_ADMIN" : "ADMIN";
}

interface Draft {
  mobile: string;
  name: string;
  role: StaffRole;
  isActive: boolean;
}

/** Adds a staff member (no `member`) or edits one. `isSelf` locks role and access. */
export function StaffDialog({
  member,
  isSelf,
  onClose,
}: {
  member: User | null;
  isSelf: boolean;
  onClose: () => void;
}) {
  const { user: me, refreshUser } = useAuth();
  const [draft, setDraft] = useState<Draft>(() => ({
    mobile: "",
    name: member?.name ?? "",
    role: member ? staffRole(member.role) : "ADMIN",
    isActive: member?.isActive ?? true,
  }));
  const [tried, setTried] = useState(false);
  const set = (patch: Partial<Draft>) => setDraft((d) => ({ ...d, ...patch }));

  const create = useApiMutation((body: CreateBody) => unwrap(api.POST("/v1/admin/staff", { body })), {
    invalidate: [["staff"]],
    success: (u) => `${u.name ?? "Staff member"} added as ${ROLE_LABEL[staffRole(u.role)].toLowerCase()}`,
    onSuccess: onClose,
  });
  const update = useApiMutation(
    ({ id, body }: { id: string; body: UpdateBody }) =>
      unwrap(api.PATCH("/v1/admin/staff/{id}", { params: { path: { id } }, body })),
    {
      invalidate: [["staff"]],
      success: (u, { body }) =>
        body.isActive === false
          ? `${u.name ?? "Staff member"} deactivated`
          : body.isActive === true
            ? `${u.name ?? "Staff member"} reactivated`
            : `Changes saved for ${u.name ?? "the staff member"}`,
      onSuccess: (u) => {
        // Editing yourself: refresh the name shown in the sidebar.
        if (u.id === me?.id) void refreshUser();
        onClose();
      },
    },
  );

  const errors = {
    mobile: member
      ? null
      : isValidMobile(draft.mobile)
        ? null
        : draft.mobile
          ? "Enter a 10-digit mobile number starting with 6, 7, 8 or 9."
          : "Enter their mobile number.",
    name: draft.name.trim().length >= 2 ? null : "Enter their name (at least 2 letters).",
  };
  const valid = !errors.mobile && !errors.name;

  const changes: UpdateBody = {};
  if (member) {
    if (draft.name.trim() !== (member.name ?? "")) changes.name = draft.name.trim();
    // You cannot change your own role or access; the API refuses it too.
    if (!isSelf && draft.role !== staffRole(member.role)) changes.role = draft.role;
    if (!isSelf && draft.isActive !== member.isActive) changes.isActive = draft.isActive;
  }
  const hasChanges = member ? Object.keys(changes).length > 0 : true;
  const deactivating = member?.isActive === true && !draft.isActive;
  const pending = create.isPending || update.isPending;
  const who = member?.name ?? "them";

  function submit(e: React.FormEvent) {
    e.preventDefault();
    setTried(true);
    if (!valid) return;
    if (!member) create.mutate({ phone: draft.mobile, name: draft.name.trim(), role: draft.role });
    else if (hasChanges) update.mutate({ id: member.id, body: changes });
  }

  const showMobileError = Boolean(errors.mobile) && (tried || draft.mobile.length === 10);
  const showNameError = Boolean(errors.name) && tried;

  return (
    <Dialog open onOpenChange={(o) => !o && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={submit} noValidate className="grid gap-4">
          <DialogHeader>
            <DialogTitle>{member ? `Edit ${member.name ?? "staff member"}` : "Add staff member"}</DialogTitle>
            <DialogDescription>
              {member
                ? `${phone(member.phone)} · changes apply straight away.`
                : "They sign in to this admin panel with a one-time code (OTP) sent to this number. There is no password to share."}
            </DialogDescription>
          </DialogHeader>

          {!member ? (
            <div className="grid gap-1.5">
              <Label htmlFor="staff-mobile">Mobile number</Label>
              <MobileInput
                id="staff-mobile"
                value={draft.mobile}
                onChange={(mobile) => set({ mobile })}
                invalid={showMobileError}
                describedBy={showMobileError ? "staff-mobile-error" : undefined}
                autoFocus
              />
              {showMobileError ? (
                <p id="staff-mobile-error" className="text-xs text-destructive">
                  {errors.mobile}
                </p>
              ) : null}
            </div>
          ) : null}

          <div className="grid gap-1.5">
            <Label htmlFor="staff-name">Name</Label>
            <Input
              id="staff-name"
              placeholder="e.g. Priya Sharma"
              maxLength={80}
              value={draft.name}
              onChange={(e) => set({ name: e.target.value })}
              aria-invalid={showNameError || undefined}
              aria-describedby={showNameError ? "staff-name-error" : undefined}
            />
            {showNameError ? (
              <p id="staff-name-error" className="text-xs text-destructive">
                {errors.name}
              </p>
            ) : null}
          </div>

          <div className="grid gap-1.5">
            <Label htmlFor="staff-role">Role</Label>
            <Select value={draft.role} onValueChange={(role) => set({ role: role as StaffRole })} disabled={isSelf}>
              <SelectTrigger id="staff-role" className="w-full" aria-describedby="staff-role-hint">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ADMIN">{ROLE_LABEL.ADMIN}</SelectItem>
                <SelectItem value="SUPER_ADMIN">{ROLE_LABEL.SUPER_ADMIN}</SelectItem>
              </SelectContent>
            </Select>
            <p id="staff-role-hint" className="text-xs text-muted-foreground">
              {ROLES_EXPLAINED}
            </p>
          </div>

          {member ? (
            <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
              <div className="grid gap-1">
                <Label htmlFor="staff-active">Account active</Label>
                <p id="staff-active-hint" className="text-xs text-muted-foreground">
                  Inactive staff cannot sign in to the admin panel.
                </p>
              </div>
              <Switch
                id="staff-active"
                checked={draft.isActive}
                onCheckedChange={(isActive) => set({ isActive })}
                disabled={isSelf}
                aria-describedby="staff-active-hint"
              />
            </div>
          ) : null}

          {isSelf ? (
            <p className="flex gap-2 rounded-lg bg-muted p-3 text-sm text-muted-foreground">
              <Info className="mt-0.5 size-4 shrink-0" aria-hidden />
              You cannot change your own role or deactivate yourself. Ask another super admin to do it.
            </p>
          ) : null}
          {deactivating ? (
            <p role="status" className="flex gap-2 rounded-lg border border-warning/40 bg-warning/10 p-3 text-sm">
              <AlertTriangle className="mt-0.5 size-4 shrink-0 text-warning" aria-hidden />
              Deactivating signs {who} out straight away. They cannot use the admin panel until a super admin reactivates them.
            </p>
          ) : null}

          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose} disabled={pending}>
              Cancel
            </Button>
            <Button type="submit" disabled={pending || !hasChanges}>
              {pending ? "Saving…" : !member ? "Add staff member" : deactivating ? "Save and deactivate" : "Save changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
