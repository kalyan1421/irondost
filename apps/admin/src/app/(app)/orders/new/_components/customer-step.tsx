"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { AlertTriangle, Phone, Search, UserPlus } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { ErrorState } from "@/components/page";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import type { User } from "@/lib/api/types";
import { phone, relativeTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import { AddCustomerDialog } from "@/app/(app)/customers/_components/add-customer-dialog";
import { useDebounced } from "@/hooks/use-debounced";

const RESULTS = 6;

/** Pick who the order is for: the chosen customer, or a search to find or add one. */
export function CustomerStep({
  customer,
  customerId,
  onSelect,
}: {
  customer: { data?: User; isError: boolean; error: unknown; refetch: () => unknown };
  customerId: string | null;
  onSelect: (id: string | null) => void;
}) {
  if (!customerId) return <CustomerSearch onSelect={onSelect} />;
  if (customer.isError) {
    return (
      <div className="grid gap-3">
        <ErrorState error={customer.error} onRetry={() => void customer.refetch()} />
        <Button variant="outline" className="justify-self-start" onClick={() => onSelect(null)}>
          Choose another customer
        </Button>
      </div>
    );
  }
  if (!customer.data) return <Skeleton className="h-16" />;

  const c = customer.data;
  return (
    <div className="grid gap-3">
      <div className="flex flex-wrap items-center gap-3 rounded-lg border bg-muted/30 p-3">
        <div className="min-w-0 flex-1">
          <Link href={`/customers/${c.id}`} className="font-medium hover:underline">
            {c.name ?? "Unnamed customer"}
          </Link>
          <a
            href={`tel:${c.phone}`}
            className="tabular mt-0.5 flex w-fit items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
          >
            <Phone className="size-3.5" /> {phone(c.phone)}
          </a>
        </div>
        <Button variant="ghost" size="sm" onClick={() => onSelect(null)}>
          Change customer
        </Button>
      </div>
      {!c.isActive ? (
        <Alert variant="destructive">
          <AlertTriangle />
          <AlertDescription>
            This customer is inactive, so orders cannot be placed for them. Reactivate them from their{" "}
            <Link href={`/customers/${c.id}`} className="underline">
              profile
            </Link>{" "}
            first.
          </AlertDescription>
        </Alert>
      ) : null}
    </div>
  );
}

function CustomerSearch({ onSelect }: { onSelect: (id: string) => void }) {
  const [search, setSearch] = useState("");
  const q = useDebounced(search.trim(), 300);
  const [adding, setAdding] = useState(false);
  const searching = q.length >= 2;

  const query = { page: 1, pageSize: RESULTS, search: q };
  const results = useQuery({
    queryKey: ["customers", query],
    queryFn: () => unwrap(api.GET("/v1/admin/customers", { params: { query } })),
    enabled: searching,
    placeholderData: keepPreviousData,
  });

  const looksLikePhone = /^[+\d\s()-]+$/.test(q);

  return (
    <div className="grid gap-3">
      <div className="grid gap-1.5">
        <Label htmlFor="customer-search">Find the customer</Label>
        <div className="flex flex-wrap gap-2">
          <div className="relative min-w-56 flex-1">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              id="customer-search"
              type="search"
              autoComplete="off"
              placeholder="Phone number or name"
              className="pl-8"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              autoFocus
            />
          </div>
          <Button variant="outline" onClick={() => setAdding(true)}>
            <UserPlus /> New customer
          </Button>
        </div>
      </div>

      {!searching ? (
        <p className="text-sm text-muted-foreground">Type at least 2 digits or letters. Matching customers appear here.</p>
      ) : results.isError ? (
        <ErrorState error={results.error} onRetry={() => void results.refetch()} />
      ) : !results.data ? (
        <Skeleton className="h-24" />
      ) : results.data.items.length === 0 ? (
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-dashed p-3 text-sm">
          <span className="text-muted-foreground">No customer matches “{q}”.</span>
          <Button size="sm" onClick={() => setAdding(true)}>
            <UserPlus /> Add as new customer
          </Button>
        </div>
      ) : (
        <div className={cn("grid gap-2 transition-opacity", results.isPlaceholderData && "opacity-60")}>
          <ul className="grid gap-1.5" aria-label="Matching customers">
            {results.data.items.map((c) => (
              <li key={c.id}>
                <button
                  type="button"
                  onClick={() => onSelect(c.id)}
                  className="flex w-full items-center gap-3 rounded-lg border px-3 py-2 text-left transition-colors outline-none hover:bg-accent/50 focus-visible:ring-3 focus-visible:ring-ring/50"
                >
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-medium">{c.name ?? "Unnamed customer"}</span>
                    <span className="tabular block text-xs text-muted-foreground">{phone(c.phone)}</span>
                  </span>
                  {!c.isActive ? <Badge variant="secondary">Inactive</Badge> : null}
                  <span className="shrink-0 text-right text-xs text-muted-foreground">
                    <span className="tabular block">
                      {c.orderCount} {c.orderCount === 1 ? "order" : "orders"}
                    </span>
                    {c.lastOrderAt ? <span className="block">Last order {relativeTime(c.lastOrderAt)}</span> : null}
                  </span>
                </button>
              </li>
            ))}
          </ul>
          {results.data.total > results.data.items.length ? (
            <p className="text-xs text-muted-foreground">
              Showing {results.data.items.length} of {results.data.total}. Type more of the number or name to narrow it down.
            </p>
          ) : null}
        </div>
      )}

      {adding ? (
        <AddCustomerDialog
          initialPhone={searching && looksLikePhone ? q : undefined}
          initialName={searching && !looksLikePhone ? q : undefined}
          onClose={() => setAdding(false)}
          onCreated={(c) => {
            setAdding(false);
            onSelect(c.id);
          }}
        />
      ) : null}
    </div>
  );
}
