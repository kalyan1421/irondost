"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { Search, UserPlus } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from "@/components/page";
import { ActiveDot } from "@/components/status";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { date, phone, relativeTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import { AddCustomerDialog } from "./_components/add-customer-dialog";
import { useDebounced } from "@/hooks/use-debounced";

const PAGE_SIZE = 25;

/** What was searched, split into a phone number or a name for prefilling "Add customer". */
function prefillFrom(q: string): { phone?: string; name?: string } {
  if (!q) return {};
  return /^[+\d\s()-]+$/.test(q) ? { phone: q } : { name: q };
}

function CustomersList() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  const page = Number(params.get("page") ?? "1") || 1;
  const [search, setSearch] = useState(params.get("q") ?? "");
  const q = useDebounced(search.trim(), 300);
  const [adding, setAdding] = useState(false);

  function update(next: Record<string, string | null>) {
    const sp = new URLSearchParams(params.toString());
    for (const [k, v] of Object.entries(next)) {
      if (v === null || v === "") sp.delete(k);
      else sp.set(k, v);
    }
    if (!("page" in next)) sp.delete("page");
    router.replace(`${pathname}?${sp.toString()}`, { scroll: false });
  }

  useEffect(() => {
    if ((params.get("q") ?? "") !== q) update({ q: q || null });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  const query = { page, pageSize: PAGE_SIZE, ...(q ? { search: q } : {}) };
  const customers = useQuery({
    queryKey: ["customers", query],
    queryFn: () => unwrap(api.GET("/v1/admin/customers", { params: { query } })),
    placeholderData: keepPreviousData,
  });

  const prefill = prefillFrom(q);

  return (
    <>
      <PageHeader
        title="Customers"
        description="Everyone who has signed up in the app or been added for a phone order."
        actions={
          <Button onClick={() => setAdding(true)}>
            <UserPlus /> Add customer
          </Button>
        }
      />
      <PageBody className="gap-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-56 flex-1 sm:max-w-xs">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Label htmlFor="customer-list-search" className="sr-only">
              Search customers
            </Label>
            <Input
              id="customer-list-search"
              type="search"
              placeholder="Phone number or name"
              className="pl-8"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          {q ? (
            <Button
              variant="ghost"
              onClick={() => {
                setSearch("");
                router.replace(pathname);
              }}
            >
              Clear search
            </Button>
          ) : null}
        </div>

        {customers.isError ? (
          <ErrorState error={customers.error} onRetry={() => void customers.refetch()} />
        ) : !customers.data ? (
          <TableSkeleton />
        ) : customers.data.items.length === 0 ? (
          q ? (
            <EmptyState
              title="No customers match this search"
              description="Check the number or name. If they are new, add them as a customer."
              action={
                <Button variant="outline" onClick={() => setAdding(true)}>
                  <UserPlus /> Add customer
                </Button>
              }
            />
          ) : (
            <EmptyState
              title="No customers yet"
              description="Customers who sign up in the app or are added here for phone orders appear in this list."
            />
          )
        ) : (
          <div className={cn("rounded-lg border bg-card transition-opacity", customers.isPlaceholderData && "opacity-60")}>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Customer</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead className="text-right">Orders</TableHead>
                  <TableHead>Last order</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {customers.data.items.map((c) => (
                  <TableRow key={c.id} className="cursor-pointer" onClick={() => router.push(`/customers/${c.id}`)}>
                    <TableCell>
                      <Link
                        href={`/customers/${c.id}`}
                        className={cn("font-medium hover:underline", !c.name && "text-muted-foreground")}
                        onClick={(e) => e.stopPropagation()}
                      >
                        {c.name ?? "Unnamed customer"}
                      </Link>
                      {c.email ? <div className="text-xs text-muted-foreground">{c.email}</div> : null}
                    </TableCell>
                    <TableCell className="tabular whitespace-nowrap">{phone(c.phone)}</TableCell>
                    <TableCell className="tabular text-right">{c.orderCount}</TableCell>
                    <TableCell className="whitespace-nowrap">
                      {c.lastOrderAt ? relativeTime(c.lastOrderAt) : <span className="text-muted-foreground">No orders yet</span>}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-muted-foreground">{date(c.createdAt)}</TableCell>
                    <TableCell>
                      <ActiveDot active={c.isActive} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
        {customers.data ? (
          <Pager
            page={customers.data.page}
            pageSize={customers.data.pageSize}
            total={customers.data.total}
            onPage={(p) => update({ page: String(p) })}
          />
        ) : null}
      </PageBody>
      {adding ? (
        <AddCustomerDialog
          initialPhone={prefill.phone}
          initialName={prefill.name}
          onClose={() => setAdding(false)}
          onCreated={(c) => router.push(`/customers/${c.id}`)}
        />
      ) : null}
    </>
  );
}

export default function CustomersPage() {
  return (
    <Suspense>
      <CustomersList />
    </Suspense>
  );
}
