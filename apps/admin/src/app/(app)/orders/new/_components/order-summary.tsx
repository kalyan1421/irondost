"use client";

import { AlertTriangle, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { errorMessage } from "@/lib/api/client";
import type { Address, PaymentMethod, Quote, User } from "@/lib/api/types";
import { phone, rupees, slot } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { SlotChoice } from "./schedule-step";

/** Why the promo code in `quote` was not applied, in words, or null if it was (or none was given). */
export function promoMessage(quote: Quote, code: string): string | null {
  switch (quote.promoError) {
    case "PROMO_NOT_FOUND":
      return `There is no promo code ${code}. Check the spelling.`;
    case "PROMO_EXPIRED":
      return `${code} is not active right now.`;
    case "PROMO_LIMIT_REACHED":
      return `This customer has already used ${code} as many times as allowed.`;
    case "PROMO_MIN_ORDER":
      return quote.promoShortfallPaise
        ? `Add ${rupees(quote.promoShortfallPaise)} more to use ${code}.`
        : `The order is below the minimum value for ${code}.`;
    default:
      return null;
  }
}

export function OrderSummary({
  customer,
  address,
  hasItems,
  quote,
  promoCode,
  pickup,
  delivery,
  paymentMethod,
  missing,
  canPlace,
  placing,
  onPlace,
}: {
  customer: User | undefined;
  address: Address | undefined;
  hasItems: boolean;
  quote: { data?: Quote; error: unknown; updating: boolean };
  promoCode: string;
  pickup: SlotChoice | null;
  delivery: SlotChoice | null;
  paymentMethod: PaymentMethod;
  missing: string[];
  canPlace: boolean;
  placing: boolean;
  onPlace: () => void;
}) {
  const q = quote.data;
  const promoProblem = q && promoCode ? promoMessage(q, promoCode) : null;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Order summary</CardTitle>
      </CardHeader>
      <CardContent className="grid gap-4">
        <dl className="grid gap-2 text-sm">
          <SummaryLine label="Customer">
            {customer ? (
              <>
                {customer.name ?? "Unnamed customer"}
                <span className="tabular block text-xs text-muted-foreground">{phone(customer.phone)}</span>
              </>
            ) : (
              <Pending />
            )}
          </SummaryLine>
          <SummaryLine label="Address">{address ? <span className="line-clamp-2">{address.formatted}</span> : <Pending />}</SummaryLine>
          <SummaryLine label="Pickup">{pickup ? slot(pickup.date, pickup.label) : <Pending />}</SummaryLine>
          <SummaryLine label="Delivery">{delivery ? slot(delivery.date, delivery.label) : <Pending />}</SummaryLine>
          <SummaryLine label="Payment">{paymentMethod === "COD" ? "Cash on delivery" : "Online, in the app"}</SummaryLine>
        </dl>

        <div className="border-t pt-4" aria-live="polite">
          {!hasItems ? (
            <p className="text-sm text-muted-foreground">Add items to see the price.</p>
          ) : !customer ? (
            <p className="text-sm text-muted-foreground">Choose a customer to see the price.</p>
          ) : quote.error && !q ? (
            <p className="text-sm text-destructive">{errorMessage(quote.error)}</p>
          ) : !q ? (
            <div className="grid gap-2">
              <Skeleton className="h-4" />
              <Skeleton className="h-4 w-2/3" />
              <Skeleton className="h-6" />
            </div>
          ) : (
            <div className={cn("grid gap-3 transition-opacity", quote.updating && "opacity-60")}>
              <ul className="grid gap-1.5 text-sm">
                {q.lines.map((l) => (
                  <li key={l.catalogItemId} className="flex justify-between gap-3">
                    <span className="min-w-0">
                      <span className="tabular text-muted-foreground">{l.quantity} ×</span> {l.name}
                    </span>
                    <span className="tabular shrink-0">{rupees(l.lineTotalPaise)}</span>
                  </li>
                ))}
              </ul>
              <dl className="grid gap-1.5 border-t pt-3 text-sm">
                <Money label="Subtotal" value={rupees(q.subtotalPaise)} />
                {q.discountPaise > 0 ? (
                  <Money
                    label={`Discount${q.promoCode ? ` (${q.promoCode})` : ""}`}
                    value={`− ${rupees(q.discountPaise)}`}
                    className="text-success"
                  />
                ) : null}
                <Money label="Delivery fee" value={q.deliveryFeePaise > 0 ? rupees(q.deliveryFeePaise) : "Free"} />
                <Money label="Total" value={rupees(q.totalPaise)} strong />
              </dl>
              {quote.updating ? (
                <p className="flex items-center gap-1.5 text-xs text-muted-foreground">
                  <Loader2 className="size-3 animate-spin" /> Updating the price
                </p>
              ) : null}
              {quote.error ? <p className="text-sm text-destructive">{errorMessage(quote.error)}</p> : null}
              {promoProblem ? <Notice>{promoProblem} Remove the code to place the order without it.</Notice> : null}
              {q.minOrderShortfallPaise ? (
                <Notice>Add {rupees(q.minOrderShortfallPaise)} more to reach the minimum order value.</Notice>
              ) : null}
            </div>
          )}
        </div>
      </CardContent>
      <CardFooter className="flex-col items-stretch gap-3">
        <Button size="lg" disabled={!canPlace} onClick={onPlace}>
          {placing ? "Placing order…" : q && hasItems && customer ? `Place order for ${rupees(q.totalPaise)}` : "Place order"}
        </Button>
        {missing.length > 0 ? (
          <div className="text-xs text-muted-foreground">
            <p>To place the order:</p>
            <ul className="mt-1 list-disc pl-4">
              {missing.map((m) => (
                <li key={m}>{m}</li>
              ))}
            </ul>
          </div>
        ) : null}
      </CardFooter>
    </Card>
  );
}

function SummaryLine({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-[5rem_minmax(0,1fr)] gap-2">
      <dt className="text-muted-foreground">{label}</dt>
      <dd>{children}</dd>
    </div>
  );
}

function Pending() {
  return <span className="text-muted-foreground">Not chosen</span>;
}

function Money({ label, value, strong, className }: { label: string; value: string; strong?: boolean; className?: string }) {
  return (
    <div className={cn("flex justify-between gap-3", strong && "text-base font-semibold", className)}>
      <dt className={cn(!strong && "text-muted-foreground")}>{label}</dt>
      <dd className="tabular">{value}</dd>
    </div>
  );
}

function Notice({ children }: { children: React.ReactNode }) {
  return (
    <p className="flex items-start gap-1.5 rounded-md bg-amber-50 p-2 text-xs text-amber-800 dark:bg-amber-400/10 dark:text-amber-300">
      <AlertTriangle className="mt-px size-3.5 shrink-0" />
      <span>{children}</span>
    </p>
  );
}
