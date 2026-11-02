"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { ScrollText, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
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

/** The few fields worth showing, without dumping whole payloads into the table. */
function summary(data: unknown): string {
  if (!data || typeof data !== "object") return "";
  const text = JSON.stringify(data);
  return text.length > 140 ? `${text.slice(0, 137)}…` : text;
}

export default function AuditPage() {
  const { isSuperAdmin } = useAuth();
  const [page, setPage] = useState(1);
  const log = useQuery({
    queryKey: ["audit", page],
    queryFn: () => unwrap(api.GET("/v1/admin/audit", { params: { query: { page, pageSize: PAGE_SIZE } } })),
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
        {log.isError ? (
          <ErrorState error={log.error} onRetry={() => void log.refetch()} />
        ) : !log.data ? (
          <TableSkeleton />
        ) : log.data.items.length === 0 ? (
          <EmptyState icon={ScrollText} title="Nothing recorded yet" description="Changes made in the admin show up here." />
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
                        {e.entity === "order" && e.entityId ? (
                          <Link href={`/orders/${e.entityId}`} className="underline-offset-4 hover:underline">
                            Order
                          </Link>
                        ) : (
                          <span className="capitalize text-muted-foreground">{e.entity.replace(/_/g, " ")}</span>
                        )}
                      </TableCell>
                      <TableCell className="max-w-sm truncate font-mono text-xs text-muted-foreground" title={JSON.stringify(e.data)}>
                        {summary(e.data)}
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
