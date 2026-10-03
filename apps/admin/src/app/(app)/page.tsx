"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowRight, Plus } from "lucide-react";
import Link from "next/link";
import { EmptyState, ErrorState, PageBody, PageHeader } from "@/components/page";
import { StatusBadge } from "@/components/status";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import type { Dashboard } from "@/lib/api/types";
import { calendarDate, istToday, relativeTime, rupees } from "@/lib/format";
import { ORDER_STATUSES } from "@/lib/order-status";
import { cn } from "@/lib/utils";

export default function DashboardPage() {
  const dashboard = useQuery({
    queryKey: ["dashboard"],
    queryFn: () => unwrap(api.GET("/v1/admin/dashboard")),
    refetchInterval: 60_000,
  });
  const attention = useQuery({
    queryKey: ["orders", { dispatchFailed: true, pageSize: 5 }],
    queryFn: () =>
      unwrap(
        api.GET("/v1/admin/orders", {
          params: { query: { dispatchFailed: true, pageSize: 5, status: ["PENDING", "READY_FOR_DELIVERY"] } },
        }),
      ),
  });

  return (
    <>
      <PageHeader
        title="Today"
        description={calendarDate(istToday())}
        actions={
          <Button asChild>
            <Link href="/orders/new">
              <Plus /> New order
            </Link>
          </Button>
        }
      />
      <PageBody>
        {dashboard.isError ? (
          <ErrorState error={dashboard.error} onRetry={() => void dashboard.refetch()} />
        ) : !dashboard.data ? (
          <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
            {Array.from({ length: 5 }, (_, i) => (
              <Skeleton key={i} className="h-24" />
            ))}
          </div>
        ) : (
          <Kpis d={dashboard.data} />
        )}

        {attention.data && attention.data.total > 0 ? (
          <Card className="border-amber-300/70 bg-amber-50/60 dark:border-amber-400/30 dark:bg-amber-400/5">
            <CardHeader className="flex-row items-center gap-2 space-y-0">
              <AlertTriangle className="size-4 text-amber-600 dark:text-amber-300" />
              <CardTitle className="text-base">No partner found for {attention.data.total} order{attention.data.total === 1 ? "" : "s"}</CardTitle>
              <Button asChild variant="ghost" size="sm" className="ml-auto">
                <Link href="/orders?attention=1">
                  View all <ArrowRight />
                </Link>
              </Button>
            </CardHeader>
            <CardContent className="grid gap-1.5">
              {attention.data.items.map((o) => (
                <Link
                  key={o.id}
                  href={`/orders/${o.id}`}
                  className="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md px-2 py-1.5 text-sm hover:bg-amber-100/70 dark:hover:bg-amber-400/10"
                >
                  <span className="font-mono font-medium">{o.orderNumber}</span>
                  <StatusBadge status={o.status} />
                  <span className="text-muted-foreground">
                    {o.status === "PENDING" ? `Pickup ${calendarDate(o.pickupDate)}, ${o.pickupSlotLabel}` : `Delivery ${calendarDate(o.deliveryDate)}, ${o.deliverySlotLabel}`}
                  </span>
                  <span className="ml-auto text-xs text-muted-foreground">
                    flagged {o.dispatchFailedAt ? relativeTime(o.dispatchFailedAt) : ""}
                  </span>
                </Link>
              ))}
            </CardContent>
          </Card>
        ) : null}

        <div className="grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Orders, last 14 days</CardTitle>
            </CardHeader>
            <CardContent>{dashboard.data ? <DailyChart days={dashboard.data.dailyOrders} /> : <Skeleton className="h-48" />}</CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Pipeline</CardTitle>
            </CardHeader>
            <CardContent>{dashboard.data ? <Pipeline byStatus={dashboard.data.byStatus} /> : <Skeleton className="h-48" />}</CardContent>
          </Card>
        </div>
      </PageBody>
    </>
  );
}

function Kpis({ d }: { d: Dashboard }) {
  const items = [
    { label: "Orders placed today", value: d.ordersToday, href: "/orders?tab=all" },
    { label: "Pickups today", value: d.pickupsToday, href: "/orders?tab=pickup" },
    { label: "Deliveries today", value: d.deliveriesToday, href: "/orders?tab=delivery" },
    { label: "Partners online", value: d.driversOnline, href: "/drivers" },
    { label: "Collected today", value: rupees(d.collectedTodayPaise), sub: `${rupees(d.collectedLast7DaysPaise)} in 7 days` },
  ];
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
      {items.map((k) => {
        const body = (
          <>
            <span className="text-xs font-medium text-muted-foreground">{k.label}</span>
            <span className="tabular text-2xl font-semibold tracking-tight">{k.value}</span>
            {k.sub ? <span className="tabular text-xs text-muted-foreground">{k.sub}</span> : null}
          </>
        );
        const cls = "flex flex-col gap-1 rounded-lg border bg-card p-4";
        return k.href ? (
          <Link key={k.label} href={k.href} className={cn(cls, "transition-colors hover:border-primary/40 hover:bg-accent/40")}>
            {body}
          </Link>
        ) : (
          <div key={k.label} className={cls}>
            {body}
          </div>
        );
      })}
    </div>
  );
}

function Pipeline({ byStatus }: { byStatus: Dashboard["byStatus"] }) {
  const counts = byStatus as Record<string, number>;
  const active = ORDER_STATUSES.filter((s) => s !== "DELIVERED" && s !== "CANCELLED");
  const total = active.reduce((n, s) => n + (counts[s] ?? 0), 0);
  if (total === 0) return <EmptyState title="No open orders" description="New orders will show up here." />;
  return (
    <ul className="grid gap-2">
      {active.map((s) => (
        <li key={s}>
          <Link href={`/orders?status=${s}`} className="flex items-center justify-between gap-3 rounded-md px-1 py-1 hover:bg-accent/50">
            <StatusBadge status={s} />
            <span className="tabular text-sm font-medium">{counts[s] ?? 0}</span>
          </Link>
        </li>
      ))}
    </ul>
  );
}

/** Bars to scale: height = orders / max. Hover a bar for the day's order value. */
function DailyChart({ days }: { days: Dashboard["dailyOrders"] }) {
  const max = Math.max(1, ...days.map((d) => d.orders));
  const totalOrders = days.reduce((n, d) => n + d.orders, 0);
  const totalValue = days.reduce((n, d) => n + d.valuePaise, 0);
  return (
    <div>
      <p className="mb-4 text-sm text-muted-foreground">
        <span className="tabular font-medium text-foreground">{totalOrders}</span> orders worth{" "}
        <span className="tabular font-medium text-foreground">{rupees(totalValue)}</span>, not counting cancelled orders
      </p>
      <div className="flex h-44 items-end gap-1.5" role="img" aria-label="Orders per day for the last 14 days">
        {days.map((d) => (
          <div key={d.date} className="group flex h-full flex-1 flex-col items-center justify-end gap-1.5" title={`${calendarDate(d.date)}: ${d.orders} orders, ${rupees(d.valuePaise)}`}>
            <span className="tabular text-[11px] text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100">{d.orders}</span>
            <div
              className={cn("w-full rounded-t-sm bg-chart-1/80 transition-colors group-hover:bg-chart-1", d.orders === 0 && "bg-muted")}
              style={{ height: `${d.orders === 0 ? 2 : (d.orders / max) * 100}%` }}
            />
          </div>
        ))}
      </div>
      <div className="mt-2 flex gap-1.5">
        {days.map((d, i) => (
          <span key={d.date} className="tabular flex-1 text-center text-[10px] text-muted-foreground">
            {i % 2 === 1 || i === days.length - 1 ? Number(d.date.slice(8)) : ""}
          </span>
        ))}
      </div>
    </div>
  );
}
