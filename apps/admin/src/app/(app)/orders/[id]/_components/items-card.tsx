"use client";

import { useQuery } from "@tanstack/react-query";
import { Minus, Pencil, Plus } from "lucide-react";
import { useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableFooter, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Order } from "@/lib/api/types";
import { rupees } from "@/lib/format";

const EDITABLE = ["PENDING", "PICKUP_ASSIGNED", "PICKED_UP", "PROCESSING"];

export function ItemsCard({ order }: { order: Order }) {
  const [editing, setEditing] = useState(false);
  const count = order.items.reduce((n, i) => n + i.quantity, 0);
  const editable = EDITABLE.includes(order.status);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          Items <span className="tabular font-normal text-muted-foreground">· {count} pieces</span>
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
            {order.deliveryFeePaise > 0 ? <SummaryRow label="Delivery fee" value={rupees(order.deliveryFeePaise)} /> : null}
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

  const save = useApiMutation(
    () =>
      unwrap(
        api.PUT("/v1/admin/orders/{id}/items", {
          params: { path: { id: order.id } },
          body: {
            items: Object.entries(qty)
              .filter(([, q]) => q > 0)
              .map(([catalogItemId, quantity]) => ({ catalogItemId, quantity })),
            note: note.trim() || undefined,
          },
        }),
      ),
    { invalidate: [["order", order.id], ["orders"]], success: "Items updated", onSuccess: onClose },
  );

  const prices = useMemo(() => {
    const m = new Map<string, number>();
    for (const c of catalog.data ?? []) for (const i of c.items) m.set(i.id, i.effectivePricePaise);
    return m;
  }, [catalog.data]);
  const subtotal = Object.entries(qty).reduce((n, [id, q]) => n + (prices.get(id) ?? 0) * q, 0);
  const anyItems = Object.values(qty).some((q) => q > 0);

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[calc(100dvh-2rem)] grid-rows-[auto_minmax(0,1fr)_auto_auto] sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Edit items</DialogTitle>
          <DialogDescription>Prices come from the current catalogue. The order&apos;s promotion is applied again on save.</DialogDescription>
        </DialogHeader>
        {catalog.data ? (
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
                          <div className="tabular text-xs text-muted-foreground">{rupees(i.effectivePricePaise)} each</div>
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
          <Label htmlFor="items-note">Note for the timeline (optional)</Label>
          <Input id="items-note" placeholder="e.g. 2 extra shirts counted at pickup" value={note} onChange={(e) => setNote(e.target.value)} />
        </div>
        <DialogFooter className="items-center sm:justify-between">
          <span className="tabular text-sm text-muted-foreground">Subtotal before discount: {rupees(subtotal)}</span>
          <Button disabled={!anyItems || save.isPending} onClick={() => save.mutate(undefined)}>
            Save items
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
