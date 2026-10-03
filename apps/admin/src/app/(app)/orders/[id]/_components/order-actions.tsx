"use client";

import { Ban } from "lucide-react";
import { useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Order, OrderStatus } from "@/lib/api/types";
import { rupees } from "@/lib/format";
import { ACTION_LABEL } from "@/lib/order-status";

/** Statuses an admin moves an order *forward* to from the header. Assignment lives in the partners card. */
const FORWARD: OrderStatus[] = ["PICKED_UP", "PROCESSING", "READY_FOR_DELIVERY", "OUT_FOR_DELIVERY", "DELIVERED"];

export function useChangeStatus(order: Order) {
  return useApiMutation(
    (vars: { status: OrderStatus; note?: string }) =>
      unwrap(api.POST("/v1/admin/orders/{id}/status", { params: { path: { id: order.id } }, body: vars })),
    {
      invalidate: [["order", order.id], ["orders"], ["dashboard"]],
      success: (o) => `Order ${o.orderNumber} updated`,
    },
  );
}

export function OrderActions({ order }: { order: Order }) {
  const change = useChangeStatus(order);
  const [reason, setReason] = useState("");

  // READY_FOR_DELIVERY is only a forward step when coming from the workshop.
  const forward = order.allowedNextStatuses.filter(
    (s) => FORWARD.includes(s) && !(s === "READY_FOR_DELIVERY" && order.status !== "PROCESSING"),
  );
  const canCancel = order.allowedNextStatuses.includes("CANCELLED");
  const due = order.amountDuePaise;

  return (
    <>
      {canCancel ? (
        <ConfirmDialog
          destructive
          title={`Cancel order ${order.orderNumber}?`}
          confirmLabel="Cancel order"
          description={
            <span className="grid gap-3">
              <span>The customer and any assigned partner are notified. This cannot be undone.</span>
              <span className="grid gap-1.5 text-foreground">
                <Label htmlFor="cancel-reason">Reason</Label>
                <Textarea
                  id="cancel-reason"
                  placeholder="e.g. Customer called to cancel"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </span>
            </span>
          }
          trigger={
            <Button variant="outline">
              <Ban /> Cancel
            </Button>
          }
          onConfirm={() => change.mutateAsync({ status: "CANCELLED", note: reason.trim() || undefined })}
        />
      ) : null}
      {forward.map((s) =>
        s === "DELIVERED" ? (
          <ConfirmDialog
            key={s}
            title="Mark as delivered?"
            confirmLabel="Mark delivered"
            description={
              due > 0
                ? `${rupees(due)} is still unpaid. Record the payment in the Payments panel once it is collected.`
                : "The customer will be told their clothes have arrived."
            }
            trigger={<Button>{ACTION_LABEL[s]}</Button>}
            onConfirm={() => change.mutateAsync({ status: s })}
          />
        ) : (
          <Button key={s} disabled={change.isPending} onClick={() => change.mutate({ status: s })}>
            {ACTION_LABEL[s] ?? s}
          </Button>
        ),
      )}
    </>
  );
}
