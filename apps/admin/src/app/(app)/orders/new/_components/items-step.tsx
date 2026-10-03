"use client";

import { useQuery } from "@tanstack/react-query";
import { EmptyState, ErrorState } from "@/components/page";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import type { CatalogItem } from "@/lib/api/types";
import { rupees } from "@/lib/format";
import { cn } from "@/lib/utils";
import { Stepper } from "../../[id]/_components/items-card";

const UNIT: Record<CatalogItem["unit"], string> = { PIECE: "piece", PAIR: "pair", SET: "set", KG: "kg" };

export function useActiveCatalog() {
  return useQuery({ queryKey: ["catalog", "public"], queryFn: () => unwrap(api.GET("/v1/catalog")) });
}

/** The active catalogue grouped by category, with a quantity stepper per item. */
export function ItemsStep({ qty, onChange }: { qty: Record<string, number>; onChange: (itemId: string, quantity: number) => void }) {
  const catalog = useActiveCatalog();

  if (catalog.isError) return <ErrorState error={catalog.error} onRetry={() => void catalog.refetch()} />;
  if (!catalog.data) return <Skeleton className="h-48" />;

  const categories = catalog.data
    .filter((c) => c.isActive)
    .map((c) => ({ ...c, items: c.items.filter((i) => i.isActive) }))
    .filter((c) => c.items.length > 0);

  if (categories.length === 0) {
    return <EmptyState title="The catalogue is empty" description="Items added and switched on in Catalogue appear here." />;
  }

  return (
    <div className="@container grid gap-6">
      {categories.map((cat) => (
        <div key={cat.id} className="grid gap-2">
          <h3 className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{cat.name}</h3>
          <div className="grid gap-x-6 gap-y-1 @xl:grid-cols-2">
            {cat.items.map((i) => {
              const q = qty[i.id] ?? 0;
              return (
                <div key={i.id} className={cn("flex items-center gap-3 rounded-md px-2 py-1.5", q > 0 && "bg-accent/60")}>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm">{i.name}</div>
                    <div className="tabular text-xs text-muted-foreground">
                      {rupees(i.effectivePricePaise)}
                      {i.offerPricePaise != null && i.offerPricePaise < i.pricePaise ? (
                        <>
                          {" "}
                          <span className="sr-only">instead of</span>
                          <s>{rupees(i.pricePaise)}</s>
                        </>
                      ) : null}{" "}
                      per {UNIT[i.unit]}
                    </div>
                  </div>
                  <Stepper value={q} onChange={(v) => onChange(i.id, v)} label={i.name} />
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
