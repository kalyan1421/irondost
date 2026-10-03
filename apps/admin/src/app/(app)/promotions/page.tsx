"use client";

import { useQuery } from "@tanstack/react-query";
import { BadgePercent, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { EmptyState, ErrorState, PageBody, PageHeader, TableSkeleton } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Promotion } from "@/lib/api/types";
import { dateTime, rupees } from "@/lib/format";
import { PromotionDialog } from "./_components/promotion-dialog";
import { discountLabel, promotionState, StateChip } from "./_components/promotion-meta";

type DialogState = { promotion?: Promotion } | null;

export default function PromotionsPage() {
  const promotions = useQuery({
    queryKey: ["promotions"],
    queryFn: () => unwrap(api.GET("/v1/admin/promotions")),
    // States depend on the clock; refetching keeps Running / Scheduled / Ended current.
    refetchInterval: 60_000,
  });
  const [dialog, setDialog] = useState<DialogState>(null);
  const now = promotions.dataUpdatedAt;

  return (
    <>
      <PageHeader
        title="Promotions"
        description="Promo codes customers enter at checkout. Running promotions also appear on the app home screen."
        actions={
          <Button onClick={() => setDialog({})}>
            <Plus /> New promotion
          </Button>
        }
      />
      <PageBody className="gap-4">
        {promotions.isError ? (
          <ErrorState error={promotions.error} onRetry={() => void promotions.refetch()} />
        ) : !promotions.data ? (
          <TableSkeleton />
        ) : promotions.data.length === 0 ? (
          <EmptyState
            icon={BadgePercent}
            title="No promotions yet"
            description="Promo codes appear here with their discount, limits and dates. Create the first one with New promotion."
            action={
              <Button onClick={() => setDialog({})}>
                <Plus /> New promotion
              </Button>
            }
          />
        ) : (
          <div className="rounded-lg border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Code</TableHead>
                  <TableHead>Title</TableHead>
                  <TableHead>Discount</TableHead>
                  <TableHead className="text-right">Minimum order</TableHead>
                  <TableHead className="text-right">Per customer</TableHead>
                  <TableHead>Valid (IST)</TableHead>
                  <TableHead>State</TableHead>
                  <TableHead className="text-right">
                    <span className="sr-only">Actions</span>
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {promotions.data.map((p) => (
                  <PromotionRow key={p.id} promotion={p} now={now} onEdit={() => setDialog({ promotion: p })} />
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </PageBody>
      {dialog ? <PromotionDialog promotion={dialog.promotion} onClose={() => setDialog(null)} /> : null}
    </>
  );
}

function PromotionRow({ promotion: p, now, onEdit }: { promotion: Promotion; now: number; onEdit: () => void }) {
  const remove = useApiMutation(
    () => unwrap(api.DELETE("/v1/admin/promotions/{id}", { params: { path: { id: p.id } } })),
    {
      invalidate: [["promotions"]],
      success: (r) => (r.deleted ? `${p.code} deleted` : `${p.code} has been used in orders, so it was paused instead of deleted.`),
    },
  );

  return (
    <TableRow>
      <TableCell className="font-mono font-medium">{p.code}</TableCell>
      <TableCell className="min-w-44 max-w-64 whitespace-normal">
        <div className="font-medium">{p.title}</div>
        {p.description ? <div className="line-clamp-1 text-xs text-muted-foreground">{p.description}</div> : null}
      </TableCell>
      <TableCell className="whitespace-nowrap">{discountLabel(p)}</TableCell>
      <TableCell className="tabular text-right">
        {p.minOrderPaise > 0 ? rupees(p.minOrderPaise) : <span className="text-muted-foreground">None</span>}
      </TableCell>
      <TableCell className="tabular text-right">
        {p.perCustomerLimit ? (
          `${p.perCustomerLimit} ${p.perCustomerLimit === 1 ? "use" : "uses"}`
        ) : (
          <span className="text-muted-foreground">Unlimited</span>
        )}
      </TableCell>
      <TableCell className="whitespace-nowrap">
        <div className="text-sm">{dateTime(p.validFrom)}</div>
        <div className="text-xs text-muted-foreground">to {dateTime(p.validTo)}</div>
      </TableCell>
      <TableCell>
        <StateChip state={promotionState(p, now)} />
      </TableCell>
      <TableCell className="text-right">
        <div className="flex justify-end gap-1">
          <Button size="icon-sm" variant="ghost" aria-label={`Edit ${p.code}`} onClick={onEdit}>
            <Pencil />
          </Button>
          <ConfirmDialog
            destructive
            title={`Delete ${p.code}?`}
            confirmLabel="Delete promotion"
            description="Customers can no longer use this code. If any order has already used it, the promotion is paused instead of deleted so past orders keep their discount details."
            trigger={
              <Button size="icon-sm" variant="ghost" aria-label={`Delete ${p.code}`}>
                <Trash2 />
              </Button>
            }
            onConfirm={() => remove.mutateAsync(undefined)}
          />
        </div>
      </TableCell>
    </TableRow>
  );
}
