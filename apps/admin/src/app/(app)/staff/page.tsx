"use client";

import { useQuery } from "@tanstack/react-query";
import { Pencil, Plus, ShieldCheck } from "lucide-react";
import { useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, TableSkeleton } from "@/components/page";
import { ActiveDot } from "@/components/status";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import type { User } from "@/lib/api/types";
import { date, phone } from "@/lib/format";
import { useAuth } from "@/lib/auth/auth-provider";
import { cn } from "@/lib/utils";
import { ROLE_LABEL, ROLES_EXPLAINED, StaffDialog } from "./_components/staff-dialog";

export default function StaffPage() {
  const { isSuperAdmin, user } = useAuth();
  const staff = useQuery({
    queryKey: ["staff"],
    queryFn: () => unwrap(api.GET("/v1/admin/staff")),
    enabled: isSuperAdmin,
  });
  // undefined: closed · null: adding · User: editing
  const [dialog, setDialog] = useState<User | null | undefined>(undefined);

  if (!isSuperAdmin) {
    return (
      <>
        <PageHeader title="Staff" />
        <PageBody>
          <EmptyState
            icon={ShieldCheck}
            title="Only super admins can manage staff"
            description="Ask a super admin if someone needs to be added, removed or given a different role."
          />
        </PageBody>
      </>
    );
  }

  return (
    <>
      <PageHeader
        title="Staff"
        description={ROLES_EXPLAINED}
        actions={
          <Button onClick={() => setDialog(null)}>
            <Plus /> Add staff member
          </Button>
        }
      />
      <PageBody>
        {staff.isError ? (
          <ErrorState error={staff.error} onRetry={() => void staff.refetch()} />
        ) : !staff.data ? (
          <TableSkeleton rows={3} />
        ) : staff.data.length === 0 ? (
          <EmptyState title="No staff yet" description="Add the people who run IronDost day to day." />
        ) : (
          <div className="rounded-lg border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>
                    <span className="sr-only">Actions</span>
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {staff.data.map((m) => {
                  const isSelf = m.id === user?.id;
                  return (
                    <TableRow key={m.id} className={cn(!m.isActive && "text-muted-foreground")}>
                      <TableCell>
                        <span className="font-medium">{m.name ?? "Unnamed"}</span>
                        {isSelf ? (
                          <Badge variant="secondary" className="ml-2">
                            You
                          </Badge>
                        ) : null}
                      </TableCell>
                      <TableCell>
                        <a href={`tel:${m.phone}`} className="tabular text-sm hover:underline">
                          {phone(m.phone)}
                        </a>
                      </TableCell>
                      <TableCell>{m.role === "SUPER_ADMIN" ? ROLE_LABEL.SUPER_ADMIN : ROLE_LABEL.ADMIN}</TableCell>
                      <TableCell>
                        <ActiveDot active={m.isActive} />
                      </TableCell>
                      <TableCell className="whitespace-nowrap">{date(m.createdAt)}</TableCell>
                      <TableCell className="text-right">
                        <Button
                          variant="ghost"
                          size="sm"
                          aria-label={`Edit ${m.name ?? "staff member"}`}
                          onClick={() => setDialog(m)}
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
        <StaffDialog
          key={dialog?.id ?? "new"}
          member={dialog}
          isSelf={dialog?.id === user?.id}
          onClose={() => setDialog(undefined)}
        />
      ) : null}
    </>
  );
}
