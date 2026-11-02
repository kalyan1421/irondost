"use client";

import { useQuery } from "@tanstack/react-query";
import { Bell } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import { SidebarMenuBadge, SidebarMenuButton, SidebarMenuItem } from "@/components/ui/sidebar";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import { relativeTime } from "@/lib/format";
import { cn } from "@/lib/utils";

/**
 * What the API sends staff: a new order, "no partner found", "refund needed", "refund failed". Without this the only
 * alert was a toast while a tab happened to be open.
 */
export function NotificationsMenu() {
  const [open, setOpen] = useState(false);
  const router = useRouter();
  const inbox = useQuery({
    queryKey: ["notifications"],
    queryFn: () => unwrap(api.GET("/v1/me/notifications", { params: { query: { pageSize: 30 } } })),
    refetchInterval: 60_000,
  });
  const read = useApiMutation(
    (id: string) => unwrap(api.POST("/v1/me/notifications/{id}/read", { params: { path: { id } } })),
    { invalidate: [["notifications"]] },
  );
  const readAll = useApiMutation(() => unwrap(api.POST("/v1/me/notifications/read-all")), {
    invalidate: [["notifications"]],
  });
  const unread = inbox.data?.unread ?? 0;

  return (
    <SidebarMenuItem>
      <Sheet
        open={open}
        onOpenChange={(o) => {
          setOpen(o);
          if (o) void inbox.refetch();
        }}
      >
        <SheetTrigger asChild>
          <SidebarMenuButton tooltip="Alerts">
            <Bell />
            <span>Alerts</span>
          </SidebarMenuButton>
        </SheetTrigger>
        {unread > 0 ? <SidebarMenuBadge className="bg-primary text-primary-foreground">{unread > 99 ? "99+" : unread}</SidebarMenuBadge> : null}
        <SheetContent side="right" className="w-full gap-0 sm:max-w-md">
          <SheetHeader>
            <SheetTitle>Alerts</SheetTitle>
            <SheetDescription>New orders, orders with no partner, and refunds that need you.</SheetDescription>
          </SheetHeader>
          <div className="flex items-center justify-between px-4 pb-2 text-sm text-muted-foreground">
            <span>{unread > 0 ? `${unread} unread` : "All caught up"}</span>
            <Button variant="ghost" size="sm" disabled={unread === 0 || readAll.isPending} onClick={() => readAll.mutate(undefined)}>
              Mark all read
            </Button>
          </div>
          <ul className="flex-1 divide-y overflow-y-auto border-t">
            {inbox.data?.items.length === 0 ? <li className="px-4 py-10 text-center text-sm text-muted-foreground">Nothing yet.</li> : null}
            {inbox.data?.items.map((n) => {
              const orderId = (n.data as { orderId?: string } | null)?.orderId;
              return (
                <li key={n.id}>
                  <button
                    type="button"
                    className={cn("flex w-full flex-col gap-0.5 px-4 py-3 text-left hover:bg-accent/50", !n.readAt && "bg-accent/30")}
                    onClick={() => {
                      if (!n.readAt) read.mutate(n.id);
                      if (orderId) {
                        setOpen(false);
                        router.push(`/orders/${orderId}`);
                      }
                    }}
                  >
                    <span className="flex items-center gap-2 text-sm font-medium">
                      {!n.readAt ? <span className="size-2 shrink-0 rounded-full bg-primary" aria-label="Unread" /> : null}
                      {n.title}
                      <span className="ml-auto text-xs font-normal text-muted-foreground">{relativeTime(n.createdAt)}</span>
                    </span>
                    <span className="text-sm text-muted-foreground">{n.body}</span>
                  </button>
                </li>
              );
            })}
          </ul>
        </SheetContent>
      </Sheet>
    </SidebarMenuItem>
  );
}
