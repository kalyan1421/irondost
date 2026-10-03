"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { AlertTriangle, Plus, Search, X } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from "@/components/page";
import { PaymentBadge, StatusBadge } from "@/components/status";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { api, unwrap } from "@/lib/api/client";
import type { OrderStatus } from "@/lib/api/types";
import { calendarDate, phone, relativeTime, rupees } from "@/lib/format";
import { ORDER_STATUSES, ORDER_TABS, STATUS } from "@/lib/order-status";
import { cn } from "@/lib/utils";
import { useDebounced } from "@/hooks/use-debounced";

const PAGE_SIZE = 25;


function OrdersBoard() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  const singleStatus = params.get("status") as OrderStatus | null;
  const tab = singleStatus ? null : (params.get("tab") ?? "active");
  const attention = params.get("attention") === "1";
  const page = Number(params.get("page") ?? "1") || 1;
  const pickupFrom = params.get("from") ?? "";
  const pickupTo = params.get("to") ?? "";
  const [search, setSearch] = useState(params.get("q") ?? "");
  const q = useDebounced(search.trim(), 300);

  function update(next: Record<string, string | null>) {
    const sp = new URLSearchParams(params.toString());
    for (const [k, v] of Object.entries(next)) {
      if (v === null || v === "") sp.delete(k);
      else sp.set(k, v);
    }
    if (!("page" in next)) sp.delete("page");
    router.replace(`${pathname}?${sp.toString()}`, { scroll: false });
  }

  useEffect(() => {
    if ((params.get("q") ?? "") !== q) update({ q: q || null });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  const statuses: OrderStatus[] = singleStatus && ORDER_STATUSES.includes(singleStatus)
    ? [singleStatus]
    : (ORDER_TABS.find((t) => t.key === tab)?.statuses ?? []);

  const query = {
    page,
    pageSize: PAGE_SIZE,
    ...(statuses.length ? { status: statuses } : {}),
    ...(q ? { search: q } : {}),
    ...(attention ? { dispatchFailed: true } : {}),
    ...(pickupFrom ? { pickupFrom } : {}),
    ...(pickupTo ? { pickupTo } : {}),
  };
  const orders = useQuery({
    queryKey: ["orders", query],
    queryFn: () => unwrap(api.GET("/v1/admin/orders", { params: { query } })),
    placeholderData: keepPreviousData,
  });

  const filtered = Boolean(q || attention || pickupFrom || pickupTo || singleStatus);

  return (
    <>
      <PageHeader
        title="Orders"
        description="Every order, from booking to doorstep."
        actions={
          <Button asChild>
            <Link href="/orders/new">
              <Plus /> New order
            </Link>
          </Button>
        }
      />
      <PageBody className="gap-4">
        <div className="flex flex-col gap-3">
          <Tabs value={tab ?? ""} onValueChange={(v) => update({ tab: v, status: null })}>
            <div className="-mx-4 overflow-x-auto px-4 md:mx-0 md:px-0">
              <TabsList className="w-max">
                {ORDER_TABS.map((t) => (
                  <TabsTrigger key={t.key} value={t.key}>
                    {t.label}
                  </TabsTrigger>
                ))}
              </TabsList>
            </div>
          </Tabs>
          <div className="flex flex-wrap items-end gap-3">
            <div className="relative min-w-56 flex-1 sm:max-w-xs">
              <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                aria-label="Search orders"
                placeholder="Order number, phone or name"
                className="pl-8"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <div className="grid gap-1">
              <Label htmlFor="from" className="text-xs text-muted-foreground">Pickup from</Label>
              <Input id="from" type="date" className="w-40" value={pickupFrom} onChange={(e) => update({ from: e.target.value })} />
            </div>
            <div className="grid gap-1">
              <Label htmlFor="to" className="text-xs text-muted-foreground">Pickup to</Label>
              <Input id="to" type="date" className="w-40" value={pickupTo} onChange={(e) => update({ to: e.target.value })} />
            </div>
            <Button
              variant={attention ? "default" : "outline"}
              onClick={() => update({ attention: attention ? null : "1" })}
              aria-pressed={attention}
            >
              <AlertTriangle /> Needs a partner
            </Button>
            {singleStatus ? (
              <Button variant="secondary" onClick={() => update({ status: null })}>
                {STATUS[singleStatus]?.label ?? singleStatus} <X />
              </Button>
            ) : null}
            {filtered ? (
              <Button
                variant="ghost"
                onClick={() => {
                  setSearch("");
                  router.replace(`${pathname}?tab=${tab ?? "active"}`);
                }}
              >
                Clear filters
              </Button>
            ) : null}
          </div>
        </div>

        {orders.isError ? (
          <ErrorState error={orders.error} onRetry={() => void orders.refetch()} />
        ) : !orders.data ? (
          <TableSkeleton />
        ) : orders.data.items.length === 0 ? (
          <EmptyState
            title={filtered ? "No orders match these filters" : "No orders here yet"}
            description={filtered ? "Try a different search or clear the filters." : "Orders placed in the app or by phone appear here."}
          />
        ) : (
          <div className={cn("rounded-lg border bg-card transition-opacity", orders.isPlaceholderData && "opacity-60")}>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Order</TableHead>
                  <TableHead>Customer</TableHead>
                  <TableHead>Pickup</TableHead>
                  <TableHead>Delivery</TableHead>
                  <TableHead className="text-right">Amount</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Partner</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {orders.data.items.map((o) => {
                  const partner = o.deliveryDriver ?? o.pickupDriver;
                  return (
                    <TableRow
                      key={o.id}
                      className="cursor-pointer"
                      onClick={() => router.push(`/orders/${o.id}`)}
                    >
                      <TableCell>
                        <Link href={`/orders/${o.id}`} className="font-mono font-medium hover:underline" onClick={(e) => e.stopPropagation()}>
                          {o.orderNumber}
                        </Link>
                        <div className="text-xs text-muted-foreground">{relativeTime(o.createdAt)}{o.source === "ADMIN" ? " · by phone" : ""}</div>
                      </TableCell>
                      <TableCell>
                        <div className="font-medium">{o.customer?.name ?? "—"}</div>
                        <div className="text-xs text-muted-foreground">{o.customer ? phone(o.customer.phone) : ""}</div>
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        <div>{calendarDate(o.pickupDate)}</div>
                        <div className="text-xs text-muted-foreground">{o.pickupSlotLabel}</div>
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        <div>{calendarDate(o.deliveryDate)}</div>
                        <div className="text-xs text-muted-foreground">{o.deliverySlotLabel}</div>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="tabular font-medium">{rupees(o.totalPaise)}</div>
                        <div className="flex justify-end gap-1 text-xs text-muted-foreground">
                          {o.paymentMethod === "COD" ? "Cash" : "Online"} · <PaymentBadge status={o.paymentStatus} />
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col items-start gap-1">
                          <StatusBadge status={o.status} />
                          {o.dispatchFailedAt ? (
                            <span className="inline-flex items-center gap-1 text-xs text-amber-700 dark:text-amber-300">
                              <AlertTriangle className="size-3" /> No partner found
                            </span>
                          ) : null}
                        </div>
                      </TableCell>
                      <TableCell className="text-sm">{partner?.name ?? <span className="text-muted-foreground">—</span>}</TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
        {orders.data ? (
          <Pager page={orders.data.page} pageSize={orders.data.pageSize} total={orders.data.total} onPage={(p) => update({ page: String(p) })} />
        ) : null}
      </PageBody>
    </>
  );
}

export default function OrdersPage() {
  return (
    <Suspense>
      <OrdersBoard />
    </Suspense>
  );
}
