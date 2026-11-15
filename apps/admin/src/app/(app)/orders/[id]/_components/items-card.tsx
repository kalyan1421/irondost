"use client";

import { useQuery } from "@tanstack/react-query";
import { Minus, Pencil, Plus } from "lucide-react";
import { useMemo, useState } from "react";
import { useGuardedClose } from "@/hooks/use-unsaved-changes";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableFooter, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, ApiError, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Order } from "@/lib/api/types";
import { ErrorState } from "@/components/page";
import { useDebounced } from "@/hooks/use-debounced";
import { quantitySummary, rupees, travelCharge } from "@/lib/format";

const EDITABLE = ["PENDING", "PICKUP_ASSIGNED", "PICKED_UP", "PROCESSING"];

const PRICE_REQUEST_STATUS: Record<NonNullable<Order["adjustments"]>[number]["status"], string> = {
  APPROVED: "Approved",
  DECLINED: "Declined",
  EXPIRED: "Expired",
  PENDING_CUSTOMER: "Waiting for the customer",
};

export function ItemsCard({ order }: { order: Order }) {
  const [editing, setEditing] = useState(false);
  const count = quantitySummary(order.items);
  const pending = order.adjustments?.find((a) => a.status === 'PENDING_CUSTOMER');
  const latest = order.adjustments?.[0];
  const editable = EDITABLE.includes(order.status) && !pending;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          Items <span className="tabular font-normal text-muted-foreground">· {count}</span>
        </CardTitle>
        {editable ? (
          <CardAction>
            <Button variant="outline" size="sm" onClick={() => setEditing(true)}>
              <Pencil /> Edit items
            </Button>
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="px-0">
        {latest ? <div role="status" className="mx-6 mb-4 grid gap-1 rounded-md border p-3 text-sm">
          <p className="font-medium">{pending ? 'Waiting for customer approval' : `Price request: ${PRICE_REQUEST_STATUS[latest.status]}`}</p>
          <p>{rupees(latest.oldTotalPaise)} → {rupees(latest.newTotalPaise)} · {latest.reason}</p>
          <p>{pending ? 'The accepted bill is unchanged. Collection and delivery steps wait for the decision.' : latest.status === 'APPROVED' ? 'The customer approved this bill.' : 'The original bill stands. Continue with the agreed items, contact the customer, or cancel the order.'}</p>
        </div> : null}
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="pl-6">Item</TableHead>
              <TableHead className="text-right">Qty</TableHead>
              <TableHead className="text-right">Rate</TableHead>
              <TableHead className="pr-6 text-right">Amount</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {order.items.map((i) => (
              <TableRow key={i.id}>
                <TableCell className="pl-6">{i.name}</TableCell>
                <TableCell className="tabular text-right">{i.quantity}</TableCell>
                <TableCell className="tabular text-right text-muted-foreground">{rupees(i.unitPricePaise)}</TableCell>
                <TableCell className="tabular pr-6 text-right">{rupees(i.lineTotalPaise)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
          <TableFooter className="bg-transparent">
            <SummaryRow label="Subtotal" value={rupees(order.subtotalPaise)} />
            {order.discountPaise > 0 ? (
              <SummaryRow label={`Discount${order.promoCode ? ` (${order.promoCode})` : ""}`} value={`− ${rupees(order.discountPaise)}`} />
            ) : null}
            <SummaryRow
              label={order.travelChargeKept && order.deliveryFeePaise > 0 ? "Travel charge (kept: partner had already travelled)" : "Travel charge"}
              value={travelCharge(order.deliveryFeePaise)}
            />
            <SummaryRow label="Total" value={rupees(order.totalPaise)} strong />
          </TableFooter>
        </Table>
      </CardContent>
      {editing ? <EditItemsDialog order={order} onClose={() => setEditing(false)} /> : null}
    </Card>
  );
}

function SummaryRow({ label, value, strong }: { label: string; value: string; strong?: boolean }) {
  return (
    <TableRow className="border-0 hover:bg-transparent">
      <TableCell colSpan={3} className={`pl-6 text-right ${strong ? "font-semibold" : "font-normal text-muted-foreground"}`}>
        {label}
      </TableCell>
      <TableCell className={`tabular pr-6 text-right ${strong ? "font-semibold" : "font-normal"}`}>{value}</TableCell>
    </TableRow>
  );
}

/** Change quantities (e.g. after counting clothes at pickup). The API reprices with the order's promotion. */
function EditItemsDialog({ order, onClose }: { order: Order; onClose: () => void }) {
  const catalog = useQuery({ queryKey: ["catalog", "admin"], queryFn: () => unwrap(api.GET("/v1/admin/catalog")) });
  const [qty, setQty] = useState<Record<string, number>>(() =>
    Object.fromEntries(order.items.filter((i) => i.catalogItemId).map((i) => [i.catalogItemId!, i.quantity])),
  );
  const [note, setNote] = useState("");
  const [revision, setRevision] = useState(order.revision);
  const lines = useMemo(() => Object.entries(qty).filter(([, q]) => q > 0).map(([catalogItemId, quantity]) => ({ catalogItemId, quantity })), [qty]);
  const quotedLines = useDebounced(lines, 300);
  const preview = useQuery({
    queryKey: ['item-edit-quote', order.id, revision, quotedLines],
    queryFn: () => unwrap(api.POST('/v1/admin/orders/{id}/items/quote', { params: { path: { id: order.id } }, body: { items: quotedLines, expectedRevision: revision } })),
    enabled: quotedLines.length > 0,
  });
  const quoteCurrent = preview.isSuccess && !preview.isFetching && JSON.stringify(lines) === JSON.stringify(quotedLines);
  const requiresApproval = preview.data?.requiresApproval === true;

  const save = useApiMutation(
    () =>
      unwrap(
        api.PUT("/v1/admin/orders/{id}/items", {
          params: { path: { id: order.id } },
          body: {
            items: lines,
            expectedRevision: revision,
            note: note.trim() || undefined,
          },
        }),
      ),
    { invalidate: [["order", order.id], ["orders"]], success: (o) => o.adjustments?.some((a) => a.status === "PENDING_CUSTOMER") ? "Approval requested. The accepted bill is unchanged." : "Items updated", onSuccess: onClose },
  );


  const conflict = (save.error instanceof ApiError && save.error.code === "ORDER_CHANGED") || (preview.error instanceof ApiError && preview.error.code === "ORDER_CHANGED");
  const latest = useQuery({ queryKey: ["order-reconcile", order.id], queryFn: () => unwrap(api.GET("/v1/admin/orders/{id}", { params: { path: { id: order.id } } })), enabled: conflict, staleTime: 0 });
  const fingerprint = JSON.stringify({ qty, note });
  const [initialFields] = useState(fingerprint);
  const close = useGuardedClose(fingerprint !== initialFields, save.isPending, onClose);

  return (
    <Dialog open onOpenChange={(o) => !o && close()}>
      <DialogContent className="max-h-[calc(100dvh-2rem)] grid-rows-[auto_minmax(0,1fr)_auto_auto] sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Edit items</DialogTitle>
          <DialogDescription>Booked items keep their accepted rates. New items use today&apos;s price. Any increase needs the customer&apos;s approval.</DialogDescription>
        </DialogHeader>
        {catalog.isError ? <ErrorState error={catalog.error} onRetry={() => void catalog.refetch()} /> : catalog.data ? (
          <ScrollArea className="min-h-0 pr-3">
            <div className="grid gap-5">
              {catalog.data.map((cat) => {
                const items = cat.items.filter((i) => i.isActive || qty[i.id]);
                if (items.length === 0) return null;
                return (
                  <div key={cat.id} className="grid gap-2">
                    <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{cat.name}</div>
                    {items.map((i) => (
                      <div key={i.id} className="flex items-center gap-3">
                        <div className="min-w-0 flex-1">
                          <div className="truncate text-sm">{i.name}</div>
                          <div className="tabular text-xs text-muted-foreground">{rupees(preview.data?.lines.find((l) => l.catalogItemId === i.id)?.unitPricePaise ?? order.items.find((l) => l.catalogItemId === i.id)?.unitPricePaise ?? i.effectivePricePaise)} per {i.unit.toLowerCase()}{i.unit === "KG" ? " (whole kg increments)" : ""}</div>
                        </div>
                        <Stepper value={qty[i.id] ?? 0} onChange={(v) => setQty((q) => ({ ...q, [i.id]: v }))} label={i.name} />
                      </div>
                    ))}
                  </div>
                );
              })}
            </div>
          </ScrollArea>
        ) : (
          <Skeleton className="h-48" />
        )}
        <div className="grid gap-1.5">
          <Label htmlFor="items-note">Reason for the changed count</Label>
          <Input id="items-note" placeholder="e.g. 2 extra shirts counted at pickup" value={note} onChange={(e) => setNote(e.target.value)} />
        </div>
        {conflict ? <div role="alert" className="grid gap-2 rounded-md border border-warning p-3 text-sm">
          <p className="font-medium">Someone changed this bill while you were editing. Your quantities are kept.</p>
          {latest.isError ? <ErrorState error={latest.error} onRetry={() => void latest.refetch()} /> : !latest.data ? <p>Loading the current bill…</p> : <>
            <p>Current accepted total: {rupees(latest.data.totalPaise)}</p>
            <ul className="list-inside list-disc">{latest.data.items.map((item) => <li key={item.id}>{item.name}: {item.quantity} {item.unit.toLowerCase()} × {rupees(item.unitPricePaise)}</li>)}</ul>
            <p>Compare these with your quantities above. Continuing refreshes the server preview before you can save.</p>
            <Button variant="outline" disabled={latest.data.adjustments?.some((a) => a.status === "PENDING_CUSTOMER")} onClick={() => { setRevision(latest.data!.revision); save.reset(); }}>Review my draft against this bill</Button>
            {latest.data.adjustments?.some((a) => a.status === "PENDING_CUSTOMER") ? <p>A price request is already awaiting the customer. Close this editor until it is decided.</p> : null}
          </>}
        </div> : null}
        {preview.isError && !conflict ? <ErrorState error={preview.error} onRetry={() => void preview.refetch()} /> : null}
        {preview.data ? <div role="status" className="grid gap-1 border-t pt-3 text-sm">
          <p>Accepted total: {rupees(preview.data.oldTotalPaise)}</p>
          <p>
            Items {rupees(preview.data.subtotalPaise)} · Discount {rupees(preview.data.discountPaise)} · Travel charge{" "}
            {preview.data.deliveryFeePaise === preview.data.oldDeliveryFeePaise
              ? travelCharge(preview.data.deliveryFeePaise)
              : `${travelCharge(preview.data.oldDeliveryFeePaise)} → ${travelCharge(preview.data.deliveryFeePaise)}`}
          </p>
          <p className="font-medium">Proposed total: {rupees(preview.data.newTotalPaise)} ({preview.data.newTotalPaise >= preview.data.oldTotalPaise ? '+' : '−'}{rupees(Math.abs(preview.data.newTotalPaise - preview.data.oldTotalPaise))})</p>
          {requiresApproval ? <p>The accepted total stays unchanged until the customer approves.</p> : null}
        </div> : null}
        <DialogFooter>
          <Button variant="ghost" onClick={close}>Close</Button>
          <Button disabled={conflict || !quoteCurrent || !catalog.data || save.isPending || (requiresApproval && !note.trim())} onClick={() => save.mutate(undefined)}>
            {save.isPending ? 'Saving…' : requiresApproval ? 'Request customer approval' : 'Save items'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export function Stepper({ value, onChange, label }: { value: number; onChange: (v: number) => void; label: string }) {
  return (
    <div className="flex items-center gap-1">
      <Button variant="outline" size="icon" className="size-8" aria-label={`Fewer ${label}`} disabled={value <= 0} onClick={() => onChange(Math.max(0, value - 1))}>
        <Minus />
      </Button>
      <Input
        aria-label={`${label} quantity`}
        inputMode="numeric"
        className="tabular h-8 w-12 text-center"
        value={value}
        onChange={(e) => {
          const n = Number(e.target.value.replace(/\D/g, ""));
          onChange(Number.isFinite(n) ? Math.min(500, n) : 0);
        }}
      />
      <Button variant="outline" size="icon" className="size-8" aria-label={`More ${label}`} onClick={() => onChange(Math.min(500, value + 1))}>
        <Plus />
      </Button>
    </div>
  );
}
