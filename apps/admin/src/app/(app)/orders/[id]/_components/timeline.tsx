import { StatusBadge } from "@/components/status";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { Order } from "@/lib/api/types";
import { dateTime } from "@/lib/format";

const ACTOR: Record<string, string> = {
  CUSTOMER: "Customer",
  DRIVER: "Partner",
  ADMIN: "Admin",
  SUPER_ADMIN: "Admin",
};

/** Every status change and edit, oldest first. */
export function Timeline({ order }: { order: Order }) {
  const events = order.events ?? [];
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">History</CardTitle>
      </CardHeader>
      <CardContent>
        <ol className="relative grid gap-5 border-l pl-5">
          {events.map((e, i) => {
            const edit = e.fromStatus === e.toStatus;
            return (
              <li key={i} className="relative">
                <span className="absolute -left-[25px] top-1 size-2.5 rounded-full border-2 border-background bg-primary ring-1 ring-border" />
                <div className="flex flex-wrap items-center gap-2">
                  {edit ? <span className="text-sm font-medium">Order edited</span> : <StatusBadge status={e.toStatus} />}
                  <span className="text-xs text-muted-foreground">
                    {dateTime(e.createdAt)}
                    {e.actorRole ? ` · ${ACTOR[e.actorRole] ?? e.actorRole}` : " · Automatic"}
                  </span>
                </div>
                {e.note ? <p className="mt-1 text-sm text-muted-foreground">{e.note}</p> : null}
              </li>
            );
          })}
        </ol>
      </CardContent>
    </Card>
  );
}
