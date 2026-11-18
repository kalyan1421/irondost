"use client";

import { useQueryClient } from "@tanstack/react-query";
import { CheckCheck } from "lucide-react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Button } from "@/components/ui/button";
import { TableCell, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { AreaInterestItem } from "@/lib/api/types";
import { dateTime, phone, relativeTime, telHref } from "@/lib/format";
import { cn } from "@/lib/utils";
import { BAND_LABEL, km } from "./area-meta";

const REFRESH = [["area-interest"]];

export function RequestRow({ item }: { item: AreaInterestItem }) {
  const queryClient = useQueryClient();
  const who = item.customerName ?? "this customer";
  const open = item.notifiedAt === null;

  const told = useApiMutation(
    async () => {
      try {
        return await unwrap(api.POST("/v1/admin/area-interest/{id}/told", { params: { path: { id: item.id } } }));
      } catch (err) {
        // Someone else may have just marked it, or it is gone: reload so this row is not out of date.
        await Promise.all(REFRESH.map((queryKey) => queryClient.invalidateQueries({ queryKey })));
        throw err;
      }
    },
    { invalidate: REFRESH, success: `Marked ${who} as told` },
  );

  return (
    <TableRow className={cn(!open && "text-muted-foreground")}>
      <TableCell className="min-w-36 whitespace-normal">
        <div className="font-medium text-foreground">{item.customerName ?? "No name"}</div>
        {item.customerPhone ? (
          <a
            href={telHref(item.customerPhone)}
            className="tabular text-sm underline-offset-4 hover:underline focus-visible:underline"
            aria-label={`Call ${who} on ${phone(item.customerPhone)}`}
          >
            {phone(item.customerPhone)}
          </a>
        ) : (
          <div className="text-sm">{phone(null)}</div>
        )}
      </TableCell>
      <TableCell className="min-w-32 whitespace-normal">
        <div className="text-foreground">{item.locality}</div>
        <div className="tabular text-xs">PIN {item.pincode}</div>
      </TableCell>
      <TableCell className="whitespace-normal">
        <div className="tabular text-foreground">{km(item.distanceKm)}</div>
        <div className="text-xs">{BAND_LABEL[item.band]}</div>
      </TableCell>
      <TableCell className="min-w-28 whitespace-normal">
        <time dateTime={item.createdAt} title={dateTime(item.createdAt)} className="tabular text-sm">
          {relativeTime(item.createdAt)}
        </time>
        {item.notifiedAt ? (
          <p className="mt-0.5 text-xs">
            Told <time dateTime={item.notifiedAt} title={dateTime(item.notifiedAt)}>{relativeTime(item.notifiedAt)}</time>
          </p>
        ) : null}
      </TableCell>
      <TableCell className="whitespace-normal">
        {open ? (
          <div className="ml-auto flex w-36 justify-end">
            <ConfirmDialog
              title="Mark as told?"
              description={`Use this once you have let ${who} know that IronDost now picks up from ${item.locality}. The request leaves the waiting list, and they can ask again later.`}
              confirmLabel="Mark as told"
              trigger={
                <Button size="sm" variant="outline" className="w-full justify-start" disabled={told.isPending} aria-label={`Mark ${who} in ${item.locality} as told`}>
                  <CheckCheck />
                  {told.isPending ? "Saving…" : "Mark as told"}
                </Button>
              }
              onConfirm={() => told.mutateAsync(undefined)}
            />
          </div>
        ) : null}
      </TableCell>
    </TableRow>
  );
}
