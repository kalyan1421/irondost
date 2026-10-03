"use client";

import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, MapPin, Phone } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ErrorState, Field, PageBody, PageHeader } from "@/components/page";
import { StatusBadge } from "@/components/status";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import type { Order, OrderAddress } from "@/lib/api/types";
import { calendarDate, dateTime, phone } from "@/lib/format";
import { ItemsCard } from "./_components/items-card";
import { OrderActions } from "./_components/order-actions";
import { PartnersCard } from "./_components/partners-card";
import { PaymentsCard } from "./_components/payments-card";
import { RefundDueBanner } from "./_components/refunds";
import { Timeline } from "./_components/timeline";

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const order = useQuery({
    queryKey: ["order", id],
    queryFn: () => unwrap(api.GET("/v1/admin/orders/{id}", { params: { path: { id } } })),
  });

  const back = (
    <Link href="/orders" className="mb-1 inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-3" /> Orders
    </Link>
  );

  if (order.isError) {
    return (
      <>
        <PageHeader title="Order" back={back} />
        <PageBody>
          <ErrorState error={order.error} onRetry={() => void order.refetch()} />
        </PageBody>
      </>
    );
  }
  if (!order.data) {
    return (
      <>
        <PageHeader title={<Skeleton className="h-7 w-40" />} back={back} />
        <PageBody>
          <Skeleton className="h-64" />
        </PageBody>
      </>
    );
  }

  const o = order.data;
  return (
    <>
      <PageHeader
        back={back}
        title={
          <span className="flex flex-wrap items-center gap-3">
            <span className="font-mono">{o.orderNumber}</span>
            <StatusBadge status={o.status} />
          </span>
        }
        description={`Placed ${dateTime(o.createdAt)}${o.source === "ADMIN" ? " by phone" : " in the app"}`}
        actions={<OrderActions order={o} />}
      />
      <PageBody>
        <RefundDueBanner order={o} />
        <div className="grid gap-6 xl:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
          <div className="flex min-w-0 flex-col gap-6">
            <ItemsCard order={o} />
            <ScheduleCard order={o} />
            <Timeline order={o} />
          </div>
          <div className="flex min-w-0 flex-col gap-6">
            <CustomerCard order={o} />
            <PartnersCard order={o} />
            <PaymentsCard order={o} />
          </div>
        </div>
      </PageBody>
    </>
  );
}

function CustomerCard({ order }: { order: Order }) {
  const c = order.customer;
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Customer</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col gap-1">
        {c ? (
          <>
            <Link href={`/customers/${c.id}`} className="font-medium hover:underline">
              {c.name ?? "Unnamed customer"}
            </Link>
            <a href={`tel:${c.phone}`} className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground">
              <Phone className="size-3.5" /> {phone(c.phone)}
            </a>
          </>
        ) : (
          <span className="text-sm text-muted-foreground">Customer account deleted</span>
        )}
      </CardContent>
    </Card>
  );
}

function AddressBlock({ title, when, address }: { title: string; when: string; address: OrderAddress }) {
  const mapsUrl =
    address.latitude != null && address.longitude != null
      ? `https://www.google.com/maps/search/?api=1&query=${address.latitude},${address.longitude}`
      : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address.formatted)}`;
  return (
    <div className="grid gap-1.5">
      <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{title}</div>
      <div className="text-sm font-medium">{when}</div>
      <div className="text-sm text-muted-foreground">
        <span className="mr-1 rounded bg-muted px-1.5 py-0.5 text-xs font-medium text-foreground">{address.label}</span>
        {address.formatted}
      </div>
      <a href={mapsUrl} target="_blank" rel="noreferrer" className="inline-flex w-fit items-center gap-1 text-xs text-primary hover:underline">
        <MapPin className="size-3" /> Open in Maps
      </a>
    </div>
  );
}

function ScheduleCard({ order }: { order: Order }) {
  const same = order.pickupAddress.formatted === order.deliveryAddress.formatted;
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Pickup & delivery</CardTitle>
      </CardHeader>
      <CardContent className="grid gap-5 sm:grid-cols-2">
        <AddressBlock title="Pickup" when={`${calendarDate(order.pickupDate)}, ${order.pickupSlotLabel}`} address={order.pickupAddress} />
        {same ? (
          <div className="grid gap-1.5">
            <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Delivery</div>
            <div className="text-sm font-medium">{`${calendarDate(order.deliveryDate)}, ${order.deliverySlotLabel}`}</div>
            <div className="text-sm text-muted-foreground">Same address as pickup</div>
          </div>
        ) : (
          <AddressBlock title="Delivery" when={`${calendarDate(order.deliveryDate)}, ${order.deliverySlotLabel}`} address={order.deliveryAddress} />
        )}
        {order.instructions ? (
          <Field label="Instructions" className="sm:col-span-2">
            <span className="whitespace-pre-line">{order.instructions}</span>
          </Field>
        ) : null}
        {order.cancelReason ? (
          <Field label="Cancellation reason" className="sm:col-span-2">
            {order.cancelReason}
          </Field>
        ) : null}
      </CardContent>
    </Card>
  );
}
