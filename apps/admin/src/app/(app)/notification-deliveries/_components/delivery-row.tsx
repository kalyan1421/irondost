"use client";

import { useQueryClient } from "@tanstack/react-query";
import { CheckCheck, RotateCw } from "lucide-react";
import Link from "next/link";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Button } from "@/components/ui/button";
import { TableCell, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import { dateTime, phone, relativeTime, telHref } from "@/lib/format";
import { cn } from "@/lib/utils";
import { APP_LABEL, kindLabel, STATUS_META, type Delivery } from "./delivery-meta";

/** The lists these actions change: this page, and the dashboard's count. */
const REFRESH = [["notification-deliveries"], ["dashboard"]];

export function DeliveryRow({ delivery: d }: { delivery: Delivery }) {
  const queryClient = useQueryClient();
  const who = d.recipient.name ?? "this person";
  const open = d.handledAt === null && d.status !== "SENT";
  const id = d.id;

  // A refused action (already delivered, already retried by someone else) means this row is out of date: reload it.
  const refreshOnError = async <T,>(call: Promise<T>): Promise<T> => {
    try {
      return await call;
    } catch (err) {
      await Promise.all(REFRESH.map((queryKey) => queryClient.invalidateQueries({ queryKey })));
      throw err;
    }
  };

  const retry = useApiMutation(
    () => refreshOnError(unwrap(api.POST("/v1/admin/notification-deliveries/{id}/retry", { params: { path: { id } } }))),
    {
      invalidate: REFRESH,
      onSuccess: (result) => {
        if (result.status === "SENT") toast.success(`Delivered to ${who}`);
        else toast.warning(`Still not delivered: ${result.reason}.`);
      },
    },
  );
  const followUp = useApiMutation(
    () => refreshOnError(unwrap(api.POST("/v1/admin/notification-deliveries/{id}/handled", { params: { path: { id } } }))),
    { invalidate: REFRESH, success: "Marked as followed up" },
  );
  const busy = retry.isPending || followUp.isPending;
  const meta = STATUS_META[d.status];

  return (
    <TableRow className={cn(!open && "text-muted-foreground")}>
      <TableCell className="min-w-36 whitespace-normal">
        <div className="font-medium text-foreground">{d.recipient.name ?? "No name"}</div>
        {d.recipient.phone ? (
          <a
            href={telHref(d.recipient.phone)}
            className="tabular text-sm underline-offset-4 hover:underline focus-visible:underline"
            aria-label={`Call ${who} on ${phone(d.recipient.phone)}`}
          >
            {phone(d.recipient.phone)}
          </a>
        ) : (
          <div className="text-sm">{phone(null)}</div>
        )}
        <div className="mt-0.5 text-xs">{APP_LABEL[d.app]}</div>
      </TableCell>
      <TableCell className="min-w-36 max-w-56 whitespace-normal">
        <div className="font-medium text-foreground">{d.title}</div>
        {kindLabel(d.type) !== d.title ? <div className="text-xs">{kindLabel(d.type)}</div> : null}
        {d.orderId && d.orderNumber ? (
          <Link href={`/orders/${d.orderId}`} className="font-mono text-xs underline underline-offset-4">
            Order {d.orderNumber}
          </Link>
        ) : null}
        <div className="mt-0.5 text-xs">
          <time dateTime={d.createdAt} title={dateTime(d.createdAt)} className="tabular">
            {relativeTime(d.createdAt)}
          </time>
        </div>
      </TableCell>
      <TableCell className="min-w-44 max-w-64 whitespace-normal">
        <span
          className={cn(
            "inline-flex items-center whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
            meta.className,
          )}
        >
          {meta.label}
        </span>
        <p className="mt-1 text-sm">{d.reason}</p>
        {d.status === "FAILED" || d.status === "PARTIAL" ? (
          <p className="tabular text-xs">
            {d.failedCount} of {d.deviceCount} {d.deviceCount === 1 ? "phone" : "phones"} refused it
          </p>
        ) : null}
        {d.handledAt ? (
          <p className="mt-1 text-xs">
            Followed up{d.handledByName ? ` by ${d.handledByName}` : ""} {relativeTime(d.handledAt)}
          </p>
        ) : null}
      </TableCell>
      <TableCell className="whitespace-normal">
        {open ? (
          <div className="ml-auto flex w-36 flex-col gap-2">
            <ConfirmDialog
              title="Send this alert again?"
              description={
                <>
                  &ldquo;{d.title}&rdquo; will be sent to {who} on the {APP_LABEL[d.app].toLowerCase()} one more time.
                  {d.status === "PARTIAL" ? " Phones that already received it may show it twice." : ""} The result is recorded here.
                </>
              }
              confirmLabel="Send again"
              trigger={
                <Button size="sm" variant="outline" className="w-full justify-start" disabled={busy || !d.canRetry} aria-label={`Send "${d.title}" to ${who} again`}>
                  <RotateCw className={cn(retry.isPending && "animate-spin")} />
                  {retry.isPending ? "Sending…" : "Retry"}
                </Button>
              }
              onConfirm={() => retry.mutateAsync(undefined)}
            />
            <ConfirmDialog
              title="Mark as followed up?"
              description={`Use this once you have called ${who} or sorted it out another way. It leaves the open list and the dashboard count.`}
              confirmLabel="Mark followed up"
              trigger={
                <Button size="sm" variant="outline" className="w-full justify-start" disabled={busy} aria-label={`Mark "${d.title}" for ${who} as followed up`}>
                  <CheckCheck />
                  {followUp.isPending ? "Saving…" : "Mark followed up"}
                </Button>
              }
              onConfirm={() => followUp.mutateAsync(undefined)}
            />
            {!d.canRetry && d.retryBlockedReason ? (
              <p className="text-xs text-muted-foreground">{d.retryBlockedReason}</p>
            ) : null}
          </div>
        ) : null}
      </TableCell>
    </TableRow>
  );
}
