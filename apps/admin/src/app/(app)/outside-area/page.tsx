"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { MapPinOff, RefreshCw } from "lucide-react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { relativeTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import { BAND_HINT, BAND_LABEL, BANDS, km, pick, STATUS_LABEL, STATUSES } from "./_components/area-meta";
import { RequestRow } from "./_components/request-row";

const PAGE_SIZE = 25;

function Waiting() {
  const params = useSearchParams();
  const router = useRouter();
  const path = usePathname();
  const status = pick(params.get("status"), STATUSES, "OPEN");
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

  const query = { page, pageSize: PAGE_SIZE, status };
  const list = useQuery({
    queryKey: ["area-interest", query],
    queryFn: () => unwrap(api.GET("/v1/admin/area-interest", { params: { query } })),
    placeholderData: keepPreviousData,
    refetchInterval: 60_000,
  });
  const data = list.data;
  const bandCount = (band: (typeof BANDS)[number]) => data?.bands.find((b) => b.band === band)?.count ?? 0;

  return (
    <>
      <PageHeader
        title="Outside the area"
        description="Customers who asked to be told when IronDost reaches them. When you start serving a place, call them and mark them as told."
        actions={
          <Button variant="outline" onClick={() => void list.refetch()} disabled={list.isFetching}>
            <RefreshCw className={cn(list.isFetching && "animate-spin")} /> Refresh
          </Button>
        }
      />
      <PageBody className="gap-6">
        {list.isError && !data ? (
          <ErrorState error={list.error} onRetry={() => void list.refetch()} />
        ) : !data ? (
          <div className="grid gap-4">
            <Skeleton className="h-24" />
            <Skeleton className="h-48" />
            <TableSkeleton />
          </div>
        ) : (
          <>
            <section aria-labelledby="demand-heading" className="grid gap-3">
              <h2 id="demand-heading" className="text-base font-medium">
                Waiting now: <span className="tabular">{data.openTotal}</span> {data.openTotal === 1 ? "customer" : "customers"}
              </h2>
              <ul className="grid gap-3 sm:grid-cols-3 xl:grid-cols-5">
                {BANDS.map((band) => (
                  <li key={band}>
                    <Card size="sm" className={cn(bandCount(band) === 0 && "opacity-60")}>
                      <CardHeader>
                        <CardDescription>{BAND_LABEL[band]}</CardDescription>
                        <CardTitle className="tabular text-2xl">{bandCount(band)}</CardTitle>
                      </CardHeader>
                      <CardContent className="text-xs text-muted-foreground">{BAND_HINT[band]}</CardContent>
                    </Card>
                  </li>
                ))}
              </ul>
            </section>

            <section aria-labelledby="areas-heading" className="grid gap-3">
              <h2 id="areas-heading" className="text-base font-medium">
                By PIN code and place
              </h2>
              {data.areas.length === 0 ? (
                <EmptyState
                  icon={MapPinOff}
                  title="Nobody is waiting"
                  description="When a customer outside the area taps “Tell me when you’re here”, they appear here, grouped by PIN code and place."
                />
              ) : (
                <div className="rounded-lg border bg-card">
                  <Table>
                    <caption className="sr-only">Customers waiting to be told, by PIN code, place and distance from the centre</caption>
                    <TableHeader>
                      <TableRow>
                        <TableHead>PIN code</TableHead>
                        <TableHead>Place</TableHead>
                        <TableHead>Distance</TableHead>
                        <TableHead className="text-right">Waiting</TableHead>
                        <TableHead className="text-right">Latest</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {data.areas.map((a) => (
                        <TableRow key={`${a.pincode}|${a.locality}|${a.band}`}>
                          <TableCell className="tabular font-medium">{a.pincode}</TableCell>
                          <TableCell>{a.locality}</TableCell>
                          <TableCell>
                            {BAND_LABEL[a.band]}
                            {a.nearestKm !== null ? <span className="tabular text-xs text-muted-foreground"> · nearest {km(a.nearestKm)}</span> : null}
                          </TableCell>
                          <TableCell className="tabular text-right font-medium">{a.count}</TableCell>
                          <TableCell className="text-right text-muted-foreground">{relativeTime(a.newestAt)}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </section>

            <section aria-labelledby="requests-heading" className="grid gap-3">
              <div className="flex flex-wrap items-end justify-between gap-3">
                <h2 id="requests-heading" className="text-base font-medium">
                  Requests, newest first
                </h2>
                <div className="grid gap-1.5">
                  <Label htmlFor="area-status">Show</Label>
                  <Select value={status} onValueChange={(v) => change({ status: v === "OPEN" ? null : v })}>
                    <SelectTrigger id="area-status" className="w-48">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {STATUSES.map((value) => (
                        <SelectItem key={value} value={value}>
                          {STATUS_LABEL[value]}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              {list.isError ? <ErrorState error={list.error} onRetry={() => void list.refetch()} /> : null}
              {data.items.length === 0 ? (
                status === "OPEN" ? (
                  <p role="status" className="text-sm text-muted-foreground">
                    No open requests.
                  </p>
                ) : (
                  <EmptyState
                    icon={MapPinOff}
                    title={status === "TOLD" ? "Nobody has been told yet" : "No requests yet"}
                    description={status === "TOLD" ? "Customers you mark as told stay here as a record." : "Requests appear here when a customer outside the area asks to be told."}
                  />
                )
              ) : (
                <>
                  <div className={cn("rounded-lg border bg-card transition-opacity", list.isPlaceholderData && "opacity-60")}>
                    <Table>
                      <caption className="sr-only">Customers who asked to be told when IronDost reaches them, newest first</caption>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Customer</TableHead>
                          <TableHead>Place</TableHead>
                          <TableHead>From the centre</TableHead>
                          <TableHead>Asked</TableHead>
                          <TableHead className="text-right">
                            <span className="sr-only">Actions</span>
                          </TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {data.items.map((item) => (
                          <RequestRow key={item.id} item={item} />
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                  <Pager page={page} pageSize={PAGE_SIZE} total={data.total} onPage={(p) => change({ page: String(p) })} />
                </>
              )}
            </section>
          </>
        )}
      </PageBody>
    </>
  );
}

export default function OutsideAreaPage() {
  return (
    <Suspense>
      <Waiting />
    </Suspense>
  );
}
