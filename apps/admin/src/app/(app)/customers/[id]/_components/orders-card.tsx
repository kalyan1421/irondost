"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { ErrorState, Pager, TableSkeleton } from "@/components/page";
import { StatusBadge } from "@/components/status";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { calendarDate, relativeTime, rupees } from "@/lib/format";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 10;

export function CustomerOrdersCard({ customerId }: { customerId: string }) {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const query = { customerId, page, pageSize: PAGE_SIZE };
  const orders = useQuery({
    queryKey: ["orders", query],
    queryFn: () => unwrap(api.GET("/v1/admin/orders", { params: { query } })),
    placeholderData: keepPreviousData,
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          Orders
          {orders.data && orders.data.total > 0 ? (
            <span className="tabular font-normal text-muted-foreground"> · {orders.data.total}</span>
          ) : null}
        </CardTitle>
      </CardHeader>
      <CardContent className={cn(orders.data && orders.data.items.length > 0 && "px-0")}>
        {orders.isError ? (
          <ErrorState error={orders.error} onRetry={() => void orders.refetch()} />
        ) : !orders.data ? (
          <TableSkeleton rows={4} />
        ) : orders.data.items.length === 0 ? (
          <p className="rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
            No orders yet. Orders this customer places in the app, or that you place for them by phone, appear here.
          </p>
        ) : (
          <div className={cn("transition-opacity", orders.isPlaceholderData && "opacity-60")}>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-4">Order</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Pickup</TableHead>
                  <TableHead className="pr-4 text-right">Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {orders.data.items.map((o) => (
                  <TableRow key={o.id} className="cursor-pointer" onClick={() => router.push(`/orders/${o.id}`)}>
                    <TableCell className="pl-4">
                      <Link
                        href={`/orders/${o.id}`}
                        className="font-mono font-medium hover:underline"
                        onClick={(e) => e.stopPropagation()}
                      >
                        {o.orderNumber}
                      </Link>
                      <div className="text-xs text-muted-foreground">
                        {relativeTime(o.createdAt)}
                        {o.source === "ADMIN" ? " · by phone" : ""}
                      </div>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={o.status} />
                    </TableCell>
                    <TableCell className="whitespace-nowrap">
                      <div>{calendarDate(o.pickupDate)}</div>
                      <div className="text-xs text-muted-foreground">{o.pickupSlotLabel}</div>
                    </TableCell>
                    <TableCell className="tabular pr-4 text-right font-medium">{rupees(o.totalPaise)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            <div className="px-4 pt-3">
              <Pager page={orders.data.page} pageSize={orders.data.pageSize} total={orders.data.total} onPage={setPage} />
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
