"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, Phone, UserRoundCheck } from "lucide-react";
import { useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { DispatchLeg, Driver, Order } from "@/lib/api/types";
import { phone, relativeTime } from "@/lib/format";
import { cn } from "@/lib/utils";

type LegState = "waiting" | "assignable" | "assigned" | "in-progress" | "done" | "closed";

function legState(order: Order, leg: DispatchLeg): LegState {
  const s = order.status;
  if (s === "CANCELLED") return "closed";
  if (leg === "PICKUP") {
    if (s === "PENDING") return "assignable";
    if (s === "PICKUP_ASSIGNED") return "assigned";
    return "done";
  }
  if (["PENDING", "PICKUP_ASSIGNED", "PICKED_UP", "PROCESSING"].includes(s)) return "waiting";
  if (s === "READY_FOR_DELIVERY") return "assignable";
  if (s === "DELIVERY_ASSIGNED") return "assigned";
  if (s === "OUT_FOR_DELIVERY") return "in-progress";
  return "done";
}

export function PartnersCard({ order }: { order: Order }) {
  const [assigning, setAssigning] = useState<DispatchLeg | null>(null);
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Delivery partners</CardTitle>
      </CardHeader>
      <CardContent className="grid gap-4">
        <LegRow order={order} leg="PICKUP" onAssign={() => setAssigning("PICKUP")} />
        <div className="border-t" />
        <LegRow order={order} leg="DELIVERY" onAssign={() => setAssigning("DELIVERY")} />
      </CardContent>
      {assigning ? <AssignDialog order={order} leg={assigning} onClose={() => setAssigning(null)} /> : null}
    </Card>
  );
}

function LegRow({ order, leg, onAssign }: { order: Order; leg: DispatchLeg; onAssign: () => void }) {
  const state = legState(order, leg);
  const person = leg === "PICKUP" ? order.pickupDriver : order.deliveryDriver;
  const title = leg === "PICKUP" ? "Pickup" : "Delivery";

  const unassign = useApiMutation(
    () => unwrap(api.POST("/v1/admin/orders/{id}/unassign", { params: { path: { id: order.id } }, body: { leg } })),
    { invalidate: [["order", order.id], ["orders"], ["drivers"]], success: "Partner removed. Looking for another partner." },
  );

  const failed = state === "assignable" && order.dispatchFailedAt;

  return (
    <div className="grid gap-2">
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{title}</span>
        {state === "assignable" ? (
          <Button size="sm" onClick={onAssign}>
            <UserRoundCheck /> Assign
          </Button>
        ) : state === "assigned" || state === "in-progress" ? (
          <div className="flex gap-1">
            {state === "assigned" ? (
              <Button size="sm" variant="ghost" onClick={onAssign}>
                Reassign
              </Button>
            ) : null}
            <ConfirmDialog
              title={`Remove ${person?.name ?? "this partner"} from the ${title.toLowerCase()}?`}
              description="The order goes back to automatic dispatch and the partner is notified."
              confirmLabel="Remove partner"
              trigger={
                <Button size="sm" variant="ghost" className="text-muted-foreground">
                  Unassign
                </Button>
              }
              onConfirm={() => unassign.mutateAsync(undefined)}
            />
          </div>
        ) : null}
      </div>
      {person ? (
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
          <span className="font-medium">{person.name ?? "Partner"}</span>
          <a href={`tel:${person.phone}`} className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
            <Phone className="size-3.5" /> {phone(person.phone)}
          </a>
          {state === "in-progress" ? <span className="text-xs text-blue-700 dark:text-blue-300">On the way</span> : null}
        </div>
      ) : (
        <p className="text-sm text-muted-foreground">
          {state === "waiting"
            ? "Assigned once the order is ready for delivery."
            : state === "closed"
              ? "Not assigned."
              : "Looking for a partner automatically."}
        </p>
      )}
      {failed ? (
        <p className="flex items-start gap-1.5 rounded-md bg-amber-50 p-2 text-xs text-amber-800 dark:bg-amber-400/10 dark:text-amber-300">
          <AlertTriangle className="mt-px size-3.5 shrink-0" />
          No partner accepted (flagged {relativeTime(order.dispatchFailedAt!)}). Retrying every few minutes. Assign one now to be sure.
        </p>
      ) : null}
    </div>
  );
}

function AssignDialog({ order, leg, onClose }: { order: Order; leg: DispatchLeg; onClose: () => void }) {
  const drivers = useQuery({ queryKey: ["drivers"], queryFn: () => unwrap(api.GET("/v1/admin/drivers")) });
  const current = leg === "PICKUP" ? order.pickupDriver?.id : order.deliveryDriver?.id;
  const [selected, setSelected] = useState<string | null>(null);

  const assign = useApiMutation(
    (driverId: string) =>
      unwrap(api.POST("/v1/admin/orders/{id}/assign", { params: { path: { id: order.id } }, body: { leg, driverId } })),
    {
      invalidate: [["order", order.id], ["orders"], ["drivers"], ["dashboard"]],
      success: (o) => `Assigned to ${(leg === "PICKUP" ? o.pickupDriver : o.deliveryDriver)?.name ?? "partner"}`,
      onSuccess: onClose,
    },
  );

  // Online partners first, then the least busy.
  const list: Driver[] = (drivers.data ?? [])
    .filter((d) => d.isActive && d.id !== current)
    .sort((a, b) => Number(b.isOnline) - Number(a.isOnline) || a.activeLegs - b.activeLegs || (a.name ?? "").localeCompare(b.name ?? ""));

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[calc(100dvh-2rem)] grid-rows-[auto_minmax(0,1fr)_auto] sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Assign {leg === "PICKUP" ? "pickup" : "delivery"} partner</DialogTitle>
          <DialogDescription>
            {order.orderNumber} · {leg === "PICKUP" ? order.pickupAddress.area ?? order.pickupAddress.city : order.deliveryAddress.area ?? order.deliveryAddress.city}
          </DialogDescription>
        </DialogHeader>
        {drivers.data ? (
          list.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">No other active partners. Add partners on the Delivery partners page.</p>
          ) : (
            <ScrollArea className="min-h-0">
              <div role="radiogroup" className="grid gap-1.5 pr-3">
                {list.map((d) => (
                  <button
                    key={d.id}
                    type="button"
                    role="radio"
                    aria-checked={selected === d.id}
                    onClick={() => setSelected(d.id)}
                    className={cn(
                      "flex items-center gap-3 rounded-lg border px-3 py-2.5 text-left transition-colors hover:bg-accent/50",
                      selected === d.id && "border-primary bg-primary/5 ring-1 ring-primary",
                    )}
                  >
                    <span className={cn("size-2 shrink-0 rounded-full", d.isOnline ? "bg-success" : "bg-muted-foreground/40")} />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-medium">{d.name ?? phone(d.phone)}</span>
                      <span className="block text-xs text-muted-foreground">
                        {d.isOnline ? "Online" : "Offline"}
                        {d.locationUpdatedAt ? ` · seen ${relativeTime(d.locationUpdatedAt)}` : ""}
                      </span>
                    </span>
                    <span className="tabular shrink-0 text-xs text-muted-foreground">{d.activeLegs} active</span>
                  </button>
                ))}
              </div>
            </ScrollArea>
          )
        ) : (
          <Skeleton className="h-40" />
        )}
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button disabled={!selected || assign.isPending} onClick={() => selected && assign.mutate(selected)}>
            Assign partner
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
