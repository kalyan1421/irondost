"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, Undo2 } from "lucide-react";
import { useState } from "react";
import { FormField } from "@/components/form-field";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Order, Payment, Refund, RefundMethod, RefundStatus } from "@/lib/api/types";
import { dateTime, paiseToInput, rupees, toPaise } from "@/lib/format";
import { cn } from "@/lib/utils";

const NOTE_MIN = 3;
const NOTE_MAX = 500;

const METHOD_LABEL: Record<RefundMethod, string> = {
  RAZORPAY: "Razorpay",
  CASH: "Cash",
  BANK_TRANSFER: "Bank transfer / UPI",
};

const STATUS_META: Record<RefundStatus, { label: string; className: string }> = {
  PENDING: {
    label: "Pending",
    className: "bg-amber-100 text-amber-900 ring-amber-600/20 dark:bg-amber-400/10 dark:text-amber-300 dark:ring-amber-400/20",
  },
  PROCESSED: {
    label: "Refunded",
    className: "bg-emerald-100 text-emerald-900 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-300 dark:ring-emerald-400/20",
  },
  FAILED: {
    label: "Failed",
    className: "bg-red-100 text-red-900 ring-red-600/20 dark:bg-red-400/10 dark:text-red-300 dark:ring-red-400/20",
  },
};

/** The order's payments; shared (by query key) with the payments card. */
export function useOrderPayments(orderId: string) {
  return useQuery({
    queryKey: ["order", orderId, "payments"],
    queryFn: () => unwrap(api.GET("/v1/admin/orders/{id}/payments", { params: { path: { id: orderId } } })),
  });
}

const isOnline = (p: Payment) => p.provider === "RAZORPAY" && p.status === "CAPTURED";

/** What can still go back through Razorpay: captured online payments minus Razorpay refunds that did not fail. */
function onlineRefundable(payments: Payment[], refunds: Refund[]): number {
  const paid = payments.filter(isOnline).reduce((sum, p) => sum + p.amountPaise, 0);
  const back = refunds.filter((r) => r.method === "RAZORPAY" && r.status !== "FAILED").reduce((sum, r) => sum + r.amountPaise, 0);
  return Math.max(0, paid - back);
}

/** Opens the refund dialog. Renders nothing when there is nothing left to refund. */
export function RefundButton({ order, variant = "outline" }: { order: Order; variant?: "outline" | "default" }) {
  const [open, setOpen] = useState(false);
  if ((order.refundablePaise ?? 0) <= 0) return null;
  return (
    <>
      <Button size="sm" variant={variant} onClick={() => setOpen(true)}>
        <Undo2 /> Refund
      </Button>
      {open ? <RefundDialog order={order} onClose={() => setOpen(false)} /> : null}
    </>
  );
}

/** Cancelled after the customer paid: money is owed back. */
export function RefundDueBanner({ order }: { order: Order }) {
  const due = order.refundablePaise ?? 0;
  if (order.status !== "CANCELLED" || due <= 0) return null;
  return (
    <div
      role="status"
      className="flex flex-wrap items-center gap-x-3 gap-y-2 rounded-lg border border-amber-300/70 bg-amber-50/60 px-4 py-3 dark:border-amber-400/30 dark:bg-amber-400/5"
    >
      <AlertTriangle className="size-4 shrink-0 text-amber-600 dark:text-amber-300" />
      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium">Paid {rupees(order.paidPaise)} but cancelled. Refund due.</p>
        {order.refundedPaise > 0 ? (
          <p className="tabular text-xs text-muted-foreground">
            {rupees(order.refundedPaise)} refunded so far · {rupees(due)} still to refund
          </p>
        ) : null}
      </div>
      <RefundButton order={order} variant="default" />
    </div>
  );
}

export function RefundStatusBadge({ status }: { status: RefundStatus }) {
  const meta = STATUS_META[status];
  return (
    <span className={cn("inline-flex items-center whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset", meta.className)}>
      {meta.label}
    </span>
  );
}

/** Refunds on an order, oldest first, for the payments card. */
export function RefundList({ refunds }: { refunds: Refund[] }) {
  return (
    <div className="grid gap-2 border-t pt-3">
      <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Refunds</div>
      <ul className="grid gap-3">
        {refunds.map((r) => (
          <li key={r.id} className="grid gap-1 text-sm">
            <div className="flex items-start justify-between gap-3">
              <span className="flex flex-wrap items-center gap-x-2 gap-y-1">
                {METHOD_LABEL[r.method]}
                <RefundStatusBadge status={r.status} />
              </span>
              <span className={cn("tabular font-medium", r.status === "FAILED" && "text-muted-foreground line-through")}>
                −{rupees(r.amountPaise)}
              </span>
            </div>
            <p className="whitespace-pre-line break-words text-muted-foreground">“{r.note}”</p>
            <span className="text-xs text-muted-foreground">
              {r.createdBy?.name ?? "Staff"} · {dateTime(r.createdAt)}
              {r.method === "RAZORPAY" && r.status === "PROCESSED" && r.processedAt ? ` · processed ${dateTime(r.processedAt)}` : ""}
            </span>
            {r.status === "FAILED" ? (
              <span className="text-xs text-destructive">
                {r.failureReason ?? "The refund failed"}. The money did not reach the customer; refund it another way.
              </span>
            ) : null}
          </li>
        ))}
      </ul>
    </div>
  );
}

function RefundDialog({ order, onClose }: { order: Order; onClose: () => void }) {
  const payments = useOrderPayments(order.id);
  const refundable = order.refundablePaise ?? 0;
  const hasOnline = (payments.data ?? []).some(isOnline);
  const online = onlineRefundable(payments.data ?? [], order.refunds ?? []);

  const [amount, setAmount] = useState(paiseToInput(refundable));
  const [picked, setPicked] = useState<RefundMethod | null>(null);
  const [note, setNote] = useState("");
  // Back to the card/UPI when it can take the whole refund; cash when nothing was paid online;
  // otherwise (part online, part cash) staff choose.
  const method: RefundMethod | null = picked ?? (online >= refundable ? "RAZORPAY" : online === 0 ? "CASH" : null);

  const paise = toPaise(amount);
  const max = method === "RAZORPAY" ? Math.min(refundable, online) : refundable;
  const amountValid = paise !== null && paise > 0 && paise <= max;
  const amountError =
    amount && !amountValid
      ? method === "RAZORPAY" && paise !== null && paise > online && paise <= refundable
        ? `Only ${rupees(online)} was paid online. Refund the rest by cash or bank transfer.`
        : `Enter an amount up to ${rupees(max)}.`
      : null;
  const trimmedNote = note.trim();
  const noteValid = trimmedNote.length >= NOTE_MIN && trimmedNote.length <= NOTE_MAX;
  const valid = amountValid && noteValid && method !== null && payments.data !== undefined;

  const refund = useApiMutation(
    (body: { amountPaise: number; method: RefundMethod; note: string }) =>
      unwrap(api.POST("/v1/admin/orders/{id}/refunds", { params: { path: { id: order.id } }, body })),
    {
      invalidate: [["order", order.id], ["orders"], ["dashboard"]],
      success: (_o, v) => (v.method === "RAZORPAY" ? `Refund of ${rupees(v.amountPaise)} started` : `Refund of ${rupees(v.amountPaise)} recorded`),
      onSuccess: onClose,
    },
  );

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (valid && paise && method) refund.mutate({ amountPaise: paise, method, note: trimmedNote });
  };

  const methods: { value: RefundMethod; title: string; hint: string; disabled?: boolean }[] = [
    ...(hasOnline
      ? [
          {
            value: "RAZORPAY" as const,
            title: "Razorpay (back to the customer's card/UPI)",
            hint:
              online <= 0
                ? "The online payment has already been refunded."
                : `${online < refundable ? `Up to ${rupees(online)}. ` : ""}Reaches the customer in 7–14 business days.`,
            disabled: online <= 0,
          },
        ]
      : []),
    { value: "CASH", title: "Cash returned", hint: "You have already handed the cash back. This records it." },
    { value: "BANK_TRANSFER", title: "Bank transfer / UPI sent manually", hint: "You have already sent the money. This records it." },
  ];

  return (
    <Dialog open onOpenChange={(o) => !o && !refund.isPending && onClose()}>
      <DialogContent className="max-h-[calc(100dvh-2rem)] grid-rows-[auto_minmax(0,1fr)_auto] sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Refund {order.orderNumber}</DialogTitle>
          <DialogDescription>
            {rupees(order.paidPaise)} paid
            {order.refundedPaise > 0 ? ` · ${rupees(order.refundedPaise)} already refunded` : ""} · up to {rupees(refundable)} can be refunded
          </DialogDescription>
        </DialogHeader>
        <ScrollArea className="min-h-0 pr-3">
          <form id="refund-form" className="grid gap-4 p-0.5" onSubmit={submit} noValidate>
            <FormField id="refund-amount" label="Amount (₹)" error={amountError}>
              {(p) => (
                <Input {...p} className="tabular" inputMode="decimal" value={amount} autoFocus onChange={(e) => setAmount(e.target.value)} />
              )}
            </FormField>
            <fieldset className="grid gap-2">
              <legend className="mb-1.5 text-sm font-medium">Refund by</legend>
              {payments.data ? (
                methods.map((m) => {
                  const id = `refund-method-${m.value}`;
                  return (
                    <Label
                      key={m.value}
                      htmlFor={id}
                      className={cn(
                        "cursor-pointer items-start gap-3 rounded-lg border p-3 font-normal leading-normal transition-colors hover:bg-accent/40 has-checked:border-primary has-checked:bg-primary/5 has-focus-visible:ring-3 has-focus-visible:ring-ring/50",
                        m.disabled && "cursor-not-allowed opacity-60 hover:bg-transparent",
                      )}
                    >
                      <input
                        type="radio"
                        id={id}
                        name="refund-method"
                        className="mt-1 accent-primary outline-none"
                        checked={method === m.value}
                        disabled={m.disabled}
                        onChange={() => setPicked(m.value)}
                      />
                      <span className="grid gap-0.5">
                        <span className="font-medium">{m.title}</span>
                        <span className="text-xs text-muted-foreground">{m.hint}</span>
                      </span>
                    </Label>
                  );
                })
              ) : (
                <Skeleton className="h-36" />
              )}
            </fieldset>
            <div className="grid gap-1">
              <FormField
                id="refund-note"
                label="Note to the customer"
                hint="Shown to the customer in the app and in their notification."
                error={note && !noteValid ? `Write at least ${NOTE_MIN} characters.` : null}
              >
                {(p) => (
                  <Textarea
                    {...p}
                    rows={3}
                    maxLength={NOTE_MAX}
                    placeholder="e.g. Sorry we couldn't pick up your clothes. Your payment is on its way back."
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                  />
                )}
              </FormField>
              <p className="tabular text-right text-xs text-muted-foreground">
                {note.length}/{NOTE_MAX}
              </p>
            </div>
          </form>
        </ScrollArea>
        <DialogFooter>
          <Button variant="ghost" disabled={refund.isPending} onClick={onClose}>
            Close
          </Button>
          <Button type="submit" form="refund-form" disabled={!valid || refund.isPending}>
            {refund.isPending ? "Refunding…" : `Refund ${amountValid && paise ? rupees(paise) : ""}`.trim()}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
