"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { BellRing, RefreshCw } from "lucide-react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { istToday } from "@/lib/format";
import { cn } from "@/lib/utils";
import { daysAgo, pick, type DeliveryApp, type DeliveryStatus, type FollowUp } from "./_components/delivery-meta";
import { DeliveryRow } from "./_components/delivery-row";

const PAGE_SIZE = 25;

const OUTCOMES = ["problems", "NO_DEVICE", "FAILED", "PARTIAL", "SENT"] as const;
const OUTCOME_LABEL: Record<(typeof OUTCOMES)[number], string> = {
  problems: "Anything not delivered",
  NO_DEVICE: "No phone registered",
  FAILED: "Not delivered",
  PARTIAL: "Reached some phones",
  SENT: "Delivered (for checking)",
};
const APPS = ["all", "CUSTOMER", "PARTNER", "ADMIN"] as const;
const APP_FILTER_LABEL: Record<(typeof APPS)[number], string> = {
  all: "All apps",
  CUSTOMER: "Customer app",
  PARTNER: "Partner app",
  ADMIN: "Staff app",
};
const FOLLOW_UPS: readonly FollowUp[] = ["OPEN", "DONE", "ALL"];
const FOLLOW_UP_LABEL: Record<FollowUp, string> = { OPEN: "Not followed up yet", DONE: "Followed up", ALL: "Both" };
const PERIODS = ["14", "30", "all"] as const;
const PERIOD_LABEL: Record<(typeof PERIODS)[number], string> = { "14": "Last 14 days", "30": "Last 30 days", all: "Any time" };

function Alerts() {
  const params = useSearchParams();
  const router = useRouter();
  const path = usePathname();
  const status = pick(params.get("status"), OUTCOMES, "problems");
  const app = pick(params.get("app"), APPS, "all");
  const followUp = pick(params.get("followUp"), FOLLOW_UPS, "OPEN");
  // 14 days matches the dashboard count, so the number there and the list here agree.
  const period = pick(params.get("period"), PERIODS, "14");
  const search = params.get("q") ?? "";
  const page = Number(params.get("page") ?? 1) || 1;

  function change(values: Record<string, string | null>) {
    const next = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(values)) {
      if (value === null || value === "") next.delete(key);
      else next.set(key, value);
    }
    if (!("page" in values)) next.delete("page");
    router.replace(`${path}?${next}`, { scroll: false });
  }

  const query = {
    page,
    pageSize: PAGE_SIZE,
    followUp,
    ...(status !== "problems" ? { status: status as DeliveryStatus } : {}),
    ...(app !== "all" ? { app: app as DeliveryApp } : {}),
    ...(period !== "all" ? { from: daysAgo(istToday(), Number(period)) } : {}),
    ...(search ? { orderNumber: search } : {}),
  };
  const alerts = useQuery({
    queryKey: ["notification-deliveries", query],
    queryFn: () => unwrap(api.GET("/v1/admin/notification-deliveries", { params: { query } })),
    placeholderData: keepPreviousData,
    refetchInterval: 30_000,
  });
  const filtered = status !== "problems" || app !== "all" || followUp !== "OPEN" || period !== "14" || search !== "";

  return (
    <>
      <PageHeader
        title="Undelivered alerts"
        description="Order updates and staff alerts that did not reach someone's phone. Retry them, or call the person and mark it followed up."
        actions={
          <Button variant="outline" onClick={() => void alerts.refetch()} disabled={alerts.isFetching}>
            <RefreshCw className={cn(alerts.isFetching && "animate-spin")} /> Refresh
          </Button>
        }
      />
      <PageBody className="gap-4">
        <div className="flex flex-wrap items-end gap-3">
          <div className="grid gap-1.5">
            <Label htmlFor="alert-status">What happened</Label>
            <Select value={status} onValueChange={(v) => change({ status: v === "problems" ? null : v })}>
              <SelectTrigger id="alert-status" className="w-56">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {OUTCOMES.map((value) => (
                  <SelectItem key={value} value={value}>
                    {OUTCOME_LABEL[value]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="alert-app">App</Label>
            <Select value={app} onValueChange={(v) => change({ app: v === "all" ? null : v })}>
              <SelectTrigger id="alert-app" className="w-44">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {APPS.map((value) => (
                  <SelectItem key={value} value={value}>
                    {APP_FILTER_LABEL[value]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="alert-follow-up">Follow-up</Label>
            <Select value={followUp} onValueChange={(v) => change({ followUp: v === "OPEN" ? null : v })}>
              <SelectTrigger id="alert-follow-up" className="w-48">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {FOLLOW_UPS.map((value) => (
                  <SelectItem key={value} value={value}>
                    {FOLLOW_UP_LABEL[value]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="alert-period">When</Label>
            <Select value={period} onValueChange={(v) => change({ period: v === "14" ? null : v })}>
              <SelectTrigger id="alert-period" className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {PERIODS.map((value) => (
                  <SelectItem key={value} value={value}>
                    {PERIOD_LABEL[value]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <form
            className="grid gap-1.5"
            key={search}
            onSubmit={(e) => {
              e.preventDefault();
              change({ q: String(new FormData(e.currentTarget).get("q") ?? "").trim() });
            }}
          >
            <Label htmlFor="alert-order">Order number</Label>
            <div className="flex gap-2">
              <Input id="alert-order" name="q" defaultValue={search} placeholder="Search order number" maxLength={30} className="w-48" />
              <Button variant="outline">Search</Button>
            </div>
          </form>
          {filtered ? (
            <Button variant="ghost" onClick={() => router.replace(path, { scroll: false })}>
              Clear filters
            </Button>
          ) : null}
        </div>
        <p role="status" className="text-sm text-muted-foreground">
          {alerts.isFetching ? "Updating…" : "This list refreshes every 30 seconds."}
        </p>

        {alerts.isError ? (
          <ErrorState error={alerts.error} onRetry={() => void alerts.refetch()} />
        ) : !alerts.data ? (
          <TableSkeleton />
        ) : alerts.data.items.length === 0 ? (
          filtered ? (
            <EmptyState
              icon={BellRing}
              title="No alerts match these filters"
              description="Try another outcome, a longer period, or clear the filters."
              action={
                <Button variant="outline" onClick={() => router.replace(path, { scroll: false })}>
                  Clear filters
                </Button>
              }
            />
          ) : (
            <EmptyState
              icon={BellRing}
              title="Every alert has reached its person"
              description="When an order update or staff alert cannot be delivered to someone's phone, it appears here so you can retry it or call them."
            />
          )
        ) : (
          <>
            <div className={cn("rounded-lg border bg-card transition-opacity", alerts.isPlaceholderData && "opacity-60")}>
              <Table>
                <caption className="sr-only">Alerts that did not reach the person, newest first</caption>
                <TableHeader>
                  <TableRow>
                    <TableHead>Who</TableHead>
                    <TableHead>What was not delivered</TableHead>
                    <TableHead>Why</TableHead>
                    <TableHead className="text-right">
                      <span className="sr-only">Actions</span>
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {alerts.data.items.map((d) => (
                    <DeliveryRow key={d.id} delivery={d} />
                  ))}
                </TableBody>
              </Table>
            </div>
            <Pager page={page} pageSize={PAGE_SIZE} total={alerts.data.total} onPage={(p) => change({ page: String(p) })} />
          </>
        )}
      </PageBody>
    </>
  );
}

export default function NotificationDeliveriesPage() {
  return (
    <Suspense>
      <Alerts />
    </Suspense>
  );
}
