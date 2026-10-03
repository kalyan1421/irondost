"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, Pencil, Plus } from "lucide-react";
import { useEffect, useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, TableSkeleton } from "@/components/page";
import { ActiveDot } from "@/components/status";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { api, unwrap } from "@/lib/api/client";
import type { Driver } from "@/lib/api/types";
import { dateTime, phone, relativeTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import { PartnerDialog } from "./_components/partner-dialog";

type Filter = "all" | "online" | "inactive";

const FILTERS: { key: Filter; label: string; match: (d: Driver) => boolean }[] = [
  { key: "all", label: "All", match: () => true },
  { key: "online", label: "Online", match: (d) => d.isActive && d.isOnline },
  { key: "inactive", label: "Inactive accounts", match: (d) => !d.isActive },
];

/** Dispatch's default for ignoring old locations, used until settings load. */
const DEFAULT_LOCATION_MAX_AGE_MIN = 15;

/** An online partner whose app has stopped sending locations is skipped by dispatch. */
function locationProblem(d: Driver, maxAgeMinutes: number, now: number): string | null {
  if (!d.isActive || !d.isOnline) return null;
  if (!d.locationUpdatedAt) return "No location yet";
  const ageMs = now - new Date(d.locationUpdatedAt).getTime();
  return ageMs > maxAgeMinutes * 60_000 ? "Stale location" : null;
}

/** Current time, refreshed on an interval so "5 min ago" and stale flags keep up. */
function useNow(intervalMs: number): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), intervalMs);
    return () => clearInterval(t);
  }, [intervalMs]);
  return now;
}

export default function DriversPage() {
  const drivers = useQuery({
    queryKey: ["drivers"],
    queryFn: () => unwrap(api.GET("/v1/admin/drivers")),
    refetchInterval: 30_000,
  });
  // Same thresholds dispatch uses; any admin can read them.
  const settings = useQuery({ queryKey: ["settings"], queryFn: () => unwrap(api.GET("/v1/admin/settings")) });
  const maxAge = settings.data?.driverLocationMaxAgeMinutes ?? DEFAULT_LOCATION_MAX_AGE_MIN;
  const maxLegs = settings.data?.driverMaxActiveLegs ?? null;

  const now = useNow(30_000);
  const [filter, setFilter] = useState<Filter>("all");
  // undefined: closed · null: adding · Driver: editing
  const [dialog, setDialog] = useState<Driver | null | undefined>(undefined);

  const all = drivers.data ?? [];
  const active = all.filter((d) => d.isActive).length;
  const online = all.filter((d) => d.isActive && d.isOnline).length;
  const current = FILTERS.find((f) => f.key === filter) ?? FILTERS[0];
  const rows = all.filter(current.match);

  return (
    <>
      <PageHeader
        title="Delivery partners"
        description={
          drivers.data
            ? `${online} online of ${active} active ${active === 1 ? "partner" : "partners"}`
            : "People who pick up and deliver orders."
        }
        actions={
          <Button onClick={() => setDialog(null)}>
            <Plus /> Add partner
          </Button>
        }
      />
      <PageBody className="gap-4">
        <Tabs value={filter} onValueChange={(v) => setFilter(v as Filter)}>
          <TabsList className="h-auto flex-wrap">
            {FILTERS.map((f) => (
              <TabsTrigger key={f.key} value={f.key}>
                {f.label}
                {drivers.data ? (
                  <span className="tabular text-xs text-muted-foreground">{all.filter(f.match).length}</span>
                ) : null}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>

        {drivers.isError ? (
          <ErrorState error={drivers.error} onRetry={() => void drivers.refetch()} />
        ) : !drivers.data ? (
          <TableSkeleton />
        ) : all.length === 0 ? (
          <EmptyState
            title="No delivery partners yet"
            description="Add a partner with their mobile number. They sign in to the partner app with a one-time code."
            action={
              <Button onClick={() => setDialog(null)}>
                <Plus /> Add partner
              </Button>
            }
          />
        ) : rows.length === 0 ? (
          <EmptyState
            title={filter === "online" ? "No partners are online" : "No inactive accounts"}
            description={
              filter === "online"
                ? "Partners show up here when they go online in the partner app."
                : "Partners you deactivate show up here."
            }
          />
        ) : (
          <div className="rounded-lg border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Partner</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Active tasks</TableHead>
                  <TableHead>Location updated</TableHead>
                  <TableHead>Vehicle</TableHead>
                  <TableHead>Account</TableHead>
                  <TableHead>Last login</TableHead>
                  <TableHead>
                    <span className="sr-only">Actions</span>
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((d) => {
                  const problem = locationProblem(d, maxAge, now);
                  const atLimit = maxLegs !== null && d.isActive && d.activeLegs >= maxLegs;
                  return (
                    <TableRow key={d.id} className={cn(!d.isActive && "text-muted-foreground")}>
                      <TableCell>
                        <div className="font-medium">{d.name ?? "Unnamed partner"}</div>
                        <a
                          href={`tel:${d.phone}`}
                          className="tabular text-xs text-muted-foreground hover:text-foreground hover:underline"
                        >
                          {phone(d.phone)}
                        </a>
                      </TableCell>
                      <TableCell>
                        <ActiveDot active={d.isActive && d.isOnline} on="Online" off="Offline" />
                      </TableCell>
                      <TableCell className="text-right">
                        <div className={cn("tabular", d.activeLegs === 0 && "text-muted-foreground")}>{d.activeLegs}</div>
                        {atLimit ? <div className="text-xs text-muted-foreground">At limit, no new offers</div> : null}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {d.locationUpdatedAt ? (
                          <span title={dateTime(d.locationUpdatedAt)}>{relativeTime(d.locationUpdatedAt)}</span>
                        ) : (
                          <span className="text-muted-foreground">Never</span>
                        )}
                        {problem ? (
                          <div className="mt-0.5 flex items-center gap-1 text-xs">
                            <AlertTriangle className="size-3 shrink-0 text-warning" aria-hidden />
                            <span>{problem}, not offered orders</span>
                          </div>
                        ) : null}
                      </TableCell>
                      <TableCell className="font-mono text-sm">
                        {d.vehicleNumber || <span className="font-sans text-muted-foreground">—</span>}
                      </TableCell>
                      <TableCell>
                        {d.isActive ? (
                          <span className="text-sm text-muted-foreground">Active</span>
                        ) : (
                          <Badge variant="outline">Inactive</Badge>
                        )}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {d.lastLoginAt ? (
                          <span title={dateTime(d.lastLoginAt)}>{relativeTime(d.lastLoginAt)}</span>
                        ) : (
                          <span className="text-muted-foreground">Never</span>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          variant="ghost"
                          size="sm"
                          aria-label={`Edit ${d.name ?? "partner"}`}
                          onClick={() => setDialog(d)}
                        >
                          <Pencil /> Edit
                        </Button>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
      </PageBody>
      {dialog !== undefined ? (
        <PartnerDialog key={dialog?.id ?? "new"} driver={dialog} onClose={() => setDialog(undefined)} />
      ) : null}
    </>
  );
}
