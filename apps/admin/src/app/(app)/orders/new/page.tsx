"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { ArrowLeft, X } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useMemo, useState } from "react";
import { PageBody, PageHeader } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { components } from "@/lib/api/schema";
import type { PaymentMethod } from "@/lib/api/types";
import { rupees } from "@/lib/format";
import { cn } from "@/lib/utils";
import { useCustomer, useCustomerAddresses } from "@/app/(app)/customers/_components/queries";
import { useDebounced } from "@/hooks/use-debounced";
import { AddressStep } from "./_components/address-step";
import { CustomerStep } from "./_components/customer-step";
import { ItemsStep } from "./_components/items-step";
import { OrderSummary, promoMessage } from "./_components/order-summary";
import { INSTRUCTIONS_MAX, PaymentStep } from "./_components/payment-step";
import { isBookable, ScheduleStep, type SlotChoice } from "./_components/schedule-step";
import { Section } from "./_components/section";

type PlaceOrderBody = components["schemas"]["AdminPlaceOrderDto"];

const SLOT_DAYS = 7;

function NewOrderForm() {
  const router = useRouter();
  const params = useSearchParams();
  const customerId = params.get("customer");

  const [addressChoice, setAddressChoice] = useState<string | null>(null);
  const [qty, setQty] = useState<Record<string, number>>({});
  const [promo, setPromo] = useState("");
  const [pickup, setPickup] = useState<SlotChoice | null>(null);
  const [delivery, setDelivery] = useState<SlotChoice | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  const [instructions, setInstructions] = useState("");

  // ── Customer and address ──
  const customer = useCustomer(customerId);
  const addresses = useCustomerAddresses(customerId);
  const addressList = addresses.data ?? [];
  // The primary address is used until another one is picked.
  const address = addressList.find((a) => a.id === addressChoice) ?? addressList.find((a) => a.isPrimary) ?? addressList[0];

  function selectCustomer(id: string | null) {
    setAddressChoice(null);
    router.replace(id ? `/orders/new?customer=${id}` : "/orders/new", { scroll: false });
  }

  // ── Items, promo and the server's price ──
  const lines = useMemo(
    () =>
      Object.entries(qty)
        .filter(([, n]) => n > 0)
        .map(([catalogItemId, quantity]) => ({ catalogItemId, quantity })),
    [qty],
  );
  const promoCode = promo.trim().toUpperCase();
  const request = useMemo(() => ({ items: lines, ...(promoCode ? { promoCode } : {}) }), [lines, promoCode]);
  const debounced = useDebounced(request, 400);
  const quote = useQuery({
    queryKey: ["quote", customerId, debounced],
    queryFn: () =>
      unwrap(
        api.POST("/v1/admin/orders/quote/{customerId}", { params: { path: { customerId: customerId ?? "" } }, body: debounced }),
      ),
    enabled: Boolean(customerId) && debounced.items.length > 0,
    placeholderData: keepPreviousData,
  });
  const quoteCurrent =
    quote.isSuccess && !quote.isPlaceholderData && !quote.isFetching && JSON.stringify(debounced) === JSON.stringify(request);
  const quoteUpdating = Boolean(customerId) && lines.length > 0 && !quoteCurrent && !quote.isError;

  // ── Schedule ──
  const pickupSlots = useQuery({
    queryKey: ["schedule", "pickup-slots", SLOT_DAYS],
    queryFn: () => unwrap(api.GET("/v1/schedule/pickup-slots", { params: { query: { days: SLOT_DAYS } } })),
  });
  const deliverySlots = useQuery({
    queryKey: ["schedule", "delivery-slots", SLOT_DAYS, pickup?.date, pickup?.slot],
    queryFn: () =>
      unwrap(
        api.GET("/v1/schedule/delivery-slots", {
          params: { query: { days: SLOT_DAYS, pickupDate: pickup?.date ?? "", pickupSlot: pickup?.slot ?? "MORNING" } },
        }),
      ),
    enabled: Boolean(pickup),
  });
  const pickupOk = isBookable(pickup, pickupSlots.data);
  const deliveryOk = isBookable(delivery, deliverySlots.data);

  // ── Placing ──
  const place = useApiMutation((body: PlaceOrderBody) => unwrap(api.POST("/v1/admin/orders", { body })), {
    invalidate: [["orders"], ["dashboard"], ["customers"]],
    success: (o) => `Order ${o.orderNumber} placed`,
    onSuccess: (o) => router.push(`/orders/${o.id}`),
  });

  const c = customer.data;
  const missing: string[] = [];
  if (!customerId) missing.push("Choose a customer");
  else if (c && !c.isActive) missing.push("Reactivate this customer, or choose another");
  if (customerId && !address) missing.push("Choose or add an address");
  if (lines.length === 0) missing.push("Add at least one item");
  if (!pickupOk) missing.push("Choose a pickup slot");
  if (!deliveryOk) missing.push("Choose a delivery slot");

  const canPlace =
    missing.length === 0 &&
    Boolean(c?.isActive && address) &&
    quoteCurrent &&
    quote.data?.canPlaceOrder === true &&
    instructions.length <= INSTRUCTIONS_MAX &&
    !place.isPending &&
    !place.isSuccess;

  function submit() {
    if (!canPlace || !customerId || !address || !pickup || !delivery) return;
    const note = instructions.trim();
    place.mutate(
      {
        customerId,
        items: lines,
        ...(promoCode ? { promoCode } : {}),
        pickupDate: pickup.date,
        pickupSlot: pickup.slot,
        deliveryDate: delivery.date,
        deliverySlot: delivery.slot,
        pickupAddressId: address.id,
        paymentMethod,
        ...(note ? { instructions: note } : {}),
      },
      {
        // Slots, prices or promo limits may have changed since the form was filled in.
        onError: () => {
          void pickupSlots.refetch();
          if (pickup) void deliverySlots.refetch();
          void quote.refetch();
        },
      },
    );
  }

  // ── Promo status, next to the field ──
  let promoStatus: { text: string; tone: "muted" | "ok" | "bad" } = {
    text: "Checked against the customer's past orders once items are added.",
    tone: "muted",
  };
  if (promoCode && customerId && lines.length > 0) {
    if (!quoteCurrent || !quote.data) promoStatus = { text: "Checking the code…", tone: "muted" };
    else if (quote.data.promoCode === promoCode)
      promoStatus = { text: `Applied. Saves ${rupees(quote.data.discountPaise)}.`, tone: "ok" };
    else promoStatus = { text: promoMessage(quote.data, promoCode) ?? "This code cannot be applied.", tone: "bad" };
  }
  const promoApplied = promoStatus.tone === "ok";

  const back = (
    <Link href="/orders" className="mb-1 inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-3" /> Orders
    </Link>
  );

  return (
    <>
      <PageHeader back={back} title="New order" description="Book a pickup for a customer who called in." />
      <PageBody>
        <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_20rem] xl:grid-cols-[minmax(0,1fr)_24rem]">
          <div className="flex min-w-0 flex-col gap-6">
            <Section step={1} title="Customer" done={Boolean(c?.isActive)}>
              <CustomerStep customer={customer} customerId={customerId} onSelect={selectCustomer} />
            </Section>

            <Section step={2} title="Address" done={Boolean(address)}>
              <AddressStep customerId={customerId} addresses={addresses} value={address?.id ?? null} onChange={setAddressChoice} />
            </Section>

            <Section
              step={3}
              title="Items"
              done={lines.length > 0}
              description="Prices come from the current catalogue. The total is worked out by the server."
              action={
                lines.length > 0 ? (
                  <Button variant="ghost" size="sm" onClick={() => setQty({})}>
                    Clear items
                  </Button>
                ) : null
              }
            >
              <ItemsStep qty={qty} onChange={(id, n) => setQty((prev) => ({ ...prev, [id]: n }))} />
            </Section>

            <Section step={4} title="Promo code" description="Optional." done={promoApplied}>
              <div className="grid gap-1.5 sm:max-w-xs">
                <Label htmlFor="promo-code">Code</Label>
                <div className="flex gap-2">
                  <Input
                    id="promo-code"
                    autoComplete="off"
                    placeholder="e.g. FIRST50"
                    maxLength={20}
                    className="font-mono uppercase"
                    value={promo}
                    aria-invalid={promoStatus.tone === "bad" || undefined}
                    aria-describedby="promo-status"
                    onChange={(e) => setPromo(e.target.value.replace(/\s/g, "").toUpperCase())}
                  />
                  {promo ? (
                    <Button variant="ghost" size="icon" aria-label="Remove promo code" onClick={() => setPromo("")}>
                      <X />
                    </Button>
                  ) : null}
                </div>
                <p
                  id="promo-status"
                  aria-live="polite"
                  className={cn(
                    "text-xs",
                    promoStatus.tone === "muted" && "text-muted-foreground",
                    promoStatus.tone === "ok" && "text-success",
                    promoStatus.tone === "bad" && "text-destructive",
                  )}
                >
                  {promoCode ? promoStatus.text : "Leave empty if the customer has no code."}
                </p>
              </div>
            </Section>

            <Section step={5} title="Pickup and delivery" done={pickupOk && deliveryOk}>
              <ScheduleStep
                pickupSlots={pickupSlots}
                deliverySlots={deliverySlots}
                pickup={pickup}
                delivery={delivery}
                onPickup={(s) => {
                  setPickup(s);
                  setDelivery(null);
                }}
                onDelivery={setDelivery}
              />
            </Section>

            <Section step={6} title="Payment and instructions">
              <PaymentStep
                method={paymentMethod}
                onMethod={setPaymentMethod}
                instructions={instructions}
                onInstructions={setInstructions}
              />
            </Section>
          </div>

          <div className="min-w-0 lg:sticky lg:top-4">
            <OrderSummary
              customer={c}
              address={address}
              hasItems={lines.length > 0}
              quote={{ data: quote.data, error: quote.isError ? quote.error : null, updating: quoteUpdating }}
              promoCode={promoCode}
              pickup={pickupOk ? pickup : null}
              delivery={deliveryOk ? delivery : null}
              paymentMethod={paymentMethod}
              missing={missing}
              canPlace={canPlace}
              placing={place.isPending || place.isSuccess}
              onPlace={submit}
            />
          </div>
        </div>
      </PageBody>
    </>
  );
}

export default function NewOrderPage() {
  return (
    <Suspense>
      <NewOrderForm />
    </Suspense>
  );
}
