"use client";

import { Banknote } from "lucide-react";
import { useState } from "react";
import { PaymentBadge } from "@/components/status";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Order } from "@/lib/api/types";
import { dateTime, paiseToInput, rupees, toPaise } from "@/lib/format";
import { RefundButton, RefundList, useOrderPayments } from "./refunds";

export function PaymentsCard({ order }: { order: Order }) {
  const payments = useOrderPayments(order.id);
  const [recording, setRecording] = useState(false);
  const captured = (payments.data ?? []).filter((p) => p.status === "CAPTURED" || p.status === "REFUNDED");
  const refunds = order.refunds ?? [];
  const canRecordCash = order.amountDuePaise > 0 && order.status !== "CANCELLED";
  // Cancelled orders get the refund banner instead.
  const overpaidBy = order.status === "CANCELLED" ? 0 : order.paidPaise - order.refundedPaise - order.totalPaise;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Payment</CardTitle>
        {canRecordCash || (order.refundablePaise ?? 0) > 0 ? (
          <CardAction className="flex flex-wrap justify-end gap-2">
            <RefundButton order={order} />
            {canRecordCash ? (
              <Button size="sm" variant="outline" onClick={() => setRecording(true)}>
                <Banknote /> Record cash
              </Button>
            ) : null}
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="grid gap-4">
        <dl className="grid grid-cols-3 gap-3">
          <div>
            <dt className="text-xs text-muted-foreground">Method</dt>
            <dd className="text-sm font-medium">{order.paymentMethod === "COD" ? "Cash on delivery" : "Online"}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Paid</dt>
            <dd className="tabular text-sm font-medium">{rupees(order.paidPaise)}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Due</dt>
            <dd className="tabular text-sm font-medium">{rupees(order.amountDuePaise)}</dd>
          </div>
          {order.refundedPaise > 0 || refunds.length > 0 ? (
            <div>
              <dt className="text-xs text-muted-foreground">Refunded</dt>
              <dd className="tabular text-sm font-medium">{rupees(order.refundedPaise)}</dd>
            </div>
          ) : null}
        </dl>
        <div className="flex items-center gap-2 text-sm">
          Status: <PaymentBadge status={order.paymentStatus} />
          {overpaidBy > 0 ? (
            <span className="text-xs text-amber-700 dark:text-amber-300">Overpaid by {rupees(overpaidBy)}: refund due</span>
          ) : null}
        </div>
        {captured.length > 0 ? (
          <ul className="grid gap-2 border-t pt-3">
            {captured.map((p) => (
              <li key={p.id} className="flex items-center justify-between gap-3 text-sm">
                <span>
                  {p.provider === "CASH" ? "Cash" : "Razorpay"}
                  <span className="block text-xs text-muted-foreground">
                    {dateTime(p.createdAt)}
                    {p.razorpayPaymentId ? ` · ${p.razorpayPaymentId}` : ""}
                  </span>
                </span>
                <span className="tabular font-medium">{rupees(p.amountPaise)}</span>
              </li>
            ))}
          </ul>
        ) : null}
        {refunds.length > 0 ? <RefundList refunds={refunds} /> : null}
      </CardContent>
      {recording ? <RecordCashDialog order={order} onClose={() => setRecording(false)} /> : null}
    </Card>
  );
}

function RecordCashDialog({ order, onClose }: { order: Order; onClose: () => void }) {
  const [amount, setAmount] = useState(paiseToInput(order.amountDuePaise));
  const paise = toPaise(amount);
  const valid = paise !== null && paise > 0 && paise <= order.amountDuePaise;

  const record = useApiMutation(
    (amountPaise: number) =>
      unwrap(api.POST("/v1/admin/orders/{id}/payments/cash", { params: { path: { id: order.id } }, body: { amountPaise } })),
    {
      invalidate: [["order", order.id], ["orders"], ["dashboard"]],
      success: "Cash payment recorded",
      onSuccess: onClose,
    },
  );

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Record cash payment</DialogTitle>
          <DialogDescription>
            {order.orderNumber} · {rupees(order.amountDuePaise)} due
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-1.5">
          <Label htmlFor="cash-amount">Amount received (₹)</Label>
          <Input id="cash-amount" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus />
          {amount && !valid ? (
            <p className="text-xs text-destructive">Enter an amount up to {rupees(order.amountDuePaise)}.</p>
          ) : null}
        </div>
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button disabled={!valid || record.isPending} onClick={() => paise && record.mutate(paise)}>
            Record {paise && valid ? rupees(paise) : "payment"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
