"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { ArrowLeft, X } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { PageBody, PageHeader } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, ApiError, unwrap } from "@/lib/api/client";
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
import { z } from "zod";
import { useAuth } from "@/lib/auth/auth-provider";
import { useUnsavedChanges } from "@/hooks/use-unsaved-changes";

const slotSchema = z.object({ date: z.string(), slot: z.enum(["MORNING", "NOON", "EVENING"]), label: z.string() });
const bodySchema = z.object({ customerId: z.uuid(), items: z.array(z.object({ catalogItemId: z.uuid(), quantity: z.number().int().min(1).max(500) })),
  pickupAddressId: z.uuid(), pickupDate: z.string(), pickupSlot: z.enum(["MORNING", "NOON", "EVENING"]), deliveryDate: z.string(), deliverySlot: z.enum(["MORNING", "NOON", "EVENING"]),
  paymentMethod: z.enum(["COD", "ONLINE"]), promoCode: z.string().optional(), instructions: z.string().optional() });
const draftSchema = z.object({ version: z.literal(1), customerId: z.string().nullable(), addressChoice: z.string().nullable(), qty: z.record(z.string(), z.number().int().min(0).max(500)),
  promo: z.string(), pickup: slotSchema.nullable(), delivery: slotSchema.nullable(), paymentMethod: z.enum(["COD", "ONLINE"]), instructions: z.string(), attemptKey: z.uuid(), submitted: bodySchema.nullable() });

type PlaceOrderBody = components["schemas"]["AdminPlaceOrderDto"];

const SLOT_DAYS = 7;
const draftVersion = 1;


function NewOrderForm() {
  const router = useRouter();
  const params = useSearchParams();
  const customerId = params.get("customer");
  const { user } = useAuth();
  const draftKey = `irondost.order.draft.${user?.id}`;
  const [restored, setRestored] = useState(false);
  const [submitted, setSubmitted] = useState<PlaceOrderBody | null>(null);
  const [draftNotice, setDraftNotice] = useState("");
  // A customer switch waiting for the admin to confirm discarding the current draft.
  const [pendingCustomer, setPendingCustomer] = useState<{ id: string | null } | null>(null);

  const [addressChoice, setAddressChoice] = useState<string | null>(null);
  const [qty, setQty] = useState<Record<string, number>>({});
  const [promo, setPromo] = useState("");
  const [pickup, setPickup] = useState<SlotChoice | null>(null);
  const [delivery, setDelivery] = useState<SlotChoice | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  const [instructions, setInstructions] = useState("");
  const [attemptKey, setAttemptKey] = useState(() => crypto.randomUUID());

  useEffect(() => {
    let active = true;
    void Promise.resolve().then(() => {
      if (!active) return;
      try {
        const saved = draftSchema.safeParse(JSON.parse(sessionStorage.getItem(draftKey) ?? "null"));
        // A draft for another customer must not hijack a link that opened this form for someone else, unless it holds an unconfirmed submission.
        if (saved.success && (!customerId || saved.data.customerId === customerId || saved.data.submitted)) {
          const d = saved.data;
          setAddressChoice(d.addressChoice); setQty(d.qty); setPromo(d.promo); setPickup(d.pickup); setDelivery(d.delivery);
          setPaymentMethod(d.paymentMethod); setInstructions(d.instructions); setAttemptKey(d.attemptKey); setSubmitted(d.submitted);
          setDraftNotice("Your draft was restored in this tab. Review it before continuing.");
          if (d.customerId !== customerId) router.replace(d.customerId ? `/orders/new?customer=${d.customerId}` : "/orders/new", { scroll: false });
        }
      } catch { setDraftNotice("Draft recovery is unavailable. Keep this tab open until the order is confirmed."); }
      setRestored(true);
    });
    return () => { active = false; };
    // Restore once when this signed-in form mounts; customer changes are handled below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draftKey]);
  const draft = { version: draftVersion, customerId, addressChoice, qty, promo, pickup, delivery, paymentMethod, instructions, attemptKey, submitted };
  const serializedDraft = JSON.stringify(draft);
  useEffect(() => {
    if (!restored) return;
    try { sessionStorage.setItem(draftKey, serializedDraft); } catch { /* The leave guard still protects this tab. */ }
  }, [draftKey, serializedDraft, restored]);

  // ── Customer and address ──
  const customer = useCustomer(customerId);
  const addresses = useCustomerAddresses(customerId);
  const addressList = addresses.data ?? [];
  // The primary address is used until another one is picked.
  const address = addressList.find((a) => a.id === addressChoice) ?? addressList.find((a) => a.isPrimary) ?? addressList[0];

  function selectCustomer(id: string | null) {
    if (id === customerId) return;
    if (submitted || place.isPending) return;
    if (Object.values(qty).some((n) => n > 0) || instructions || promo || pickup) { setPendingCustomer({ id }); return; }
    switchCustomer(id);
  }
  function switchCustomer(id: string | null) {
    setAddressChoice(null);
    setQty({}); setPromo(''); setPickup(null); setDelivery(null); setInstructions(''); setPaymentMethod('COD');
    setAttemptKey(crypto.randomUUID());
    setDraftNotice('New order started. The previous customer details were cleared.');
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
  const place = useApiMutation(({ body, key }: { body: PlaceOrderBody; key: string }) => unwrap(api.POST("/v1/admin/orders", { body, headers: { 'Idempotency-Key': key } })), {
    invalidate: [["orders"], ["dashboard"], ["customers"]],
    success: (o) => `Order ${o.orderNumber} placed`,
    onSuccess: (o) => { try { sessionStorage.removeItem(draftKey); } catch {} router.push(`/orders/${o.id}`); },
  });

  useUnsavedChanges(!place.isSuccess && (Boolean(submitted) || Object.values(qty).some((n) => n > 0) || Boolean(instructions || promo || pickup)));
  const c = customer.data;
  const missing: string[] = [];
  if (!customerId) missing.push("Choose a customer");
  else if (c && !c.isActive) missing.push("Reactivate this customer, or choose another");
  if (customerId && !address) missing.push("Choose or add an address");
  if (lines.length === 0) missing.push("Add at least one item");
  if (!pickupOk) missing.push("Choose a pickup slot");
  if (!deliveryOk) missing.push("Choose a delivery slot");

  const canPlace =
    restored && !submitted && missing.length === 0 &&
    Boolean(c?.isActive && address) &&
    quoteCurrent &&
    quote.data?.canPlaceOrder === true &&
    instructions.length <= INSTRUCTIONS_MAX &&
    !place.isPending &&
    !place.isSuccess;

  function send(body: PlaceOrderBody, key: string) {
    place.mutate({ body, key }, { onError: (error) => {
      // A transport/5xx failure may have committed. Keep the exact body and key locked for replay.
      // The API replays a committed attempt before it validates, so a 4xx on any attempt (including a retry) means no order exists.
      if (error instanceof ApiError && error.status >= 400 && error.status < 500 && error.code !== "IDEMPOTENCY_KEY_REUSED") {
        setSubmitted(null); setAttemptKey(crypto.randomUUID());
        void pickupSlots.refetch(); if (pickup) void deliverySlots.refetch(); void quote.refetch();
      }
    } });
  }
  function submit() {
    if (!canPlace || !customerId || !address || !pickup || !delivery) return;
    const note = instructions.trim();
    const body: PlaceOrderBody = { customerId, items: lines, ...(promoCode ? { promoCode } : {}), pickupDate: pickup.date, pickupSlot: pickup.slot,
      deliveryDate: delivery.date, deliverySlot: delivery.slot, pickupAddressId: address.id, paymentMethod, ...(note ? { instructions: note } : {}) };
    // Write the intent before sending so a page reload can retry the same request.
    try { sessionStorage.setItem(draftKey, JSON.stringify({ ...draft, submitted: body })); }
    catch { setDraftNotice("Draft saving is unavailable. Keep this tab open until the order is confirmed."); }
    setSubmitted(body); send(body, attemptKey);
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
        {draftNotice ? <p role="status" className="text-sm text-muted-foreground">{draftNotice}</p> : null}
        {submitted && !place.isSuccess ? <div role="status" className="grid gap-3 rounded-lg border border-warning/50 bg-warning/5 p-4">
          <p className="font-medium">{place.isPending ? "Confirming this order…" : "This order has not been confirmed in this tab."}</p>
          <p className="text-sm">Retry sends the same order with the same submission key. If it was already created, you will open that order. Keep the details unchanged until this is resolved.</p>
          <Button className="justify-self-start" disabled={place.isPending} onClick={() => send(submitted, attemptKey)}>{place.isPending ? "Checking…" : "Retry same order"}</Button>
          <Link href="/orders" className="text-sm underline">Review existing orders</Link>
        </div> : null}
        <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_20rem] xl:grid-cols-[minmax(0,1fr)_24rem]">
          <fieldset disabled={!restored || Boolean(submitted) || place.isPending || place.isSuccess} className="flex min-w-0 flex-col gap-6">
            <legend className="sr-only">New order details</legend>
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
          </fieldset>

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
      <ConfirmDialog
        open={pendingCustomer !== null}
        onOpenChange={(o) => { if (!o) setPendingCustomer(null); }}
        title="Start a new order for a different customer?"
        description="This clears the current items, instructions and times."
        confirmLabel="Start new order"
        cancelLabel="Keep this order"
        onConfirm={() => { if (pendingCustomer) switchCustomer(pendingCustomer.id); }}
      />
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
