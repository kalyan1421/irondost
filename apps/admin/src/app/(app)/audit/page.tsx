"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { ScrollText, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from "@/components/page";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { useAuth } from "@/lib/auth/auth-provider";
import { dateTime } from "@/lib/format";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 30;

/** "order.status_changed" → "Order status changed" */
function describe(action: string): string {
  const text = action.replace(/[._]/g, " ");
  return text.charAt(0).toUpperCase() + text.slice(1);
}

export default function AuditPage() {
  const { isSuperAdmin } = useAuth();
  const [page, setPage] = useState(1);
  const [filters, setFilters] = useState({ entity: "", entityId: "", actorId: "", action: "", from: "", to: "" });
  const query = { page, pageSize: PAGE_SIZE, ...Object.fromEntries(Object.entries(filters).filter(([, value]) => value)) };
  const log = useQuery({
    queryKey: ["audit", query],
    queryFn: () => unwrap(api.GET("/v1/admin/audit", { params: { query } })),
    placeholderData: keepPreviousData,
    enabled: isSuperAdmin,
  });

  if (!isSuperAdmin) {
    return (
      <>
        <PageHeader title="Audit log" />
        <PageBody>
          <EmptyState
            icon={ShieldCheck}
            title="Only super admins can see the audit log"
            description="Ask a super admin if you need to know who changed an order, a price or a setting."
          />
        </PageBody>
      </>
    );
  }

  return (
    <>
      <PageHeader title="Audit log" description="Who changed what in the admin, newest first." />
      <PageBody className="gap-4">
        <form className="grid items-end gap-3 sm:grid-cols-2 lg:grid-cols-4" onSubmit={(event) => {
          event.preventDefault(); const data = new FormData(event.currentTarget);
          setFilters({ entity: String(data.get("entity") ?? "").trim(), entityId: String(data.get("entityId") ?? "").trim(), actorId: String(data.get("actorId") ?? "").trim(), action: String(data.get("action") ?? "").trim(), from: String(data.get("from") ?? ""), to: String(data.get("to") ?? "") }); setPage(1);
        }} key={JSON.stringify(filters)}>
          {([ ["entity", "Record type", "order, issue, user…"], ["entityId", "Record ID", "Exact ID"], ["actorId", "Staff ID", "Exact staff ID"], ["action", "Action", "order.items_updated…"], ["from", "From date (IST)", ""], ["to", "To date (IST)", ""] ] as const).map(([name, label, placeholder]) => <div key={name} className="grid gap-1.5"><Label htmlFor={`audit-${name}`}>{label}</Label><Input id={`audit-${name}`} name={name} type={name === "from" || name === "to" ? "date" : "text"} placeholder={placeholder} defaultValue={filters[name]} maxLength={100} /></div>)}
          <div className="flex gap-2"><Button>Apply filters</Button><Button type="button" variant="outline" onClick={() => { setFilters({ entity: "", entityId: "", actorId: "", action: "", from: "", to: "" }); setPage(1); }}>Clear</Button></div>
        </form>
        {log.isError ? (
          <ErrorState error={log.error} onRetry={() => void log.refetch()} />
        ) : !log.data ? (
          <TableSkeleton />
        ) : log.data.items.length === 0 ? (
          <EmptyState icon={ScrollText} title="No changes match these filters" description="Clear the filters to see all recorded changes." />
        ) : (
          <>
            <div className={cn("rounded-lg border bg-card transition-opacity", log.isPlaceholderData && "opacity-60")}>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>When</TableHead>
                    <TableHead>Who</TableHead>
                    <TableHead>What</TableHead>
                    <TableHead>Record</TableHead>
                    <TableHead>Details</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {log.data.items.map((e) => (
                    <TableRow key={e.id}>
                      <TableCell className="tabular whitespace-nowrap text-muted-foreground">{dateTime(e.createdAt)}</TableCell>
                      <TableCell>{e.actorName ?? "System"}</TableCell>
                      <TableCell className="font-medium">{describe(e.action)}</TableCell>
                      <TableCell>
                        {(e.entity === "order" || e.entity === "issue") && e.entityId ? (
                          <Link href={`/${e.entity === "issue" ? "issues" : "orders"}/${e.entityId}`} className="underline-offset-4 hover:underline">
                            {e.entity === "issue" ? "Report" : "Order"}
                          </Link>
                        ) : (
                          <span className="capitalize text-muted-foreground">{e.entity.replace(/_/g, " ")}</span>
                        )}
                      </TableCell>
                      <TableCell className="min-w-56 max-w-lg text-xs text-muted-foreground">
                        <details><summary className="cursor-pointer rounded py-2 font-medium focus-visible:outline-2">View full change</summary>
                          <p className="mt-2 break-all">Record ID: {e.entityId ?? "—"} · Staff ID: {e.actorId ?? "System"}</p>
                          <pre className="mt-2 max-h-80 overflow-auto whitespace-pre-wrap break-all rounded bg-muted p-3">{JSON.stringify(e.data, null, 2) ?? "No additional details"}</pre>
                        </details>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
            <Pager page={page} pageSize={PAGE_SIZE} total={log.data.total} onPage={setPage} />
          </>
        )}
      </PageBody>
    </>
  );
}
