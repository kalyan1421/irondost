"use client";

import { ArrowLeft, Phone, Plus } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ErrorState, PageBody, PageHeader } from "@/components/page";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { phone } from "@/lib/format";
import { useCustomer } from "../_components/queries";
import { AddressesCard } from "./_components/addresses-card";
import { CustomerOrdersCard } from "./_components/orders-card";
import { ProfileCard } from "./_components/profile-card";

export default function CustomerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const customer = useCustomer(id);

  const back = (
    <Link href="/customers" className="mb-1 inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-3" /> Customers
    </Link>
  );

  if (customer.isError) {
    return (
      <>
        <PageHeader title="Customer" back={back} />
        <PageBody>
          <ErrorState error={customer.error} onRetry={() => void customer.refetch()} />
        </PageBody>
      </>
    );
  }
  if (!customer.data) {
    return (
      <>
        <PageHeader title={<Skeleton className="h-7 w-48" />} back={back} />
        <PageBody>
          <Skeleton className="h-64" />
        </PageBody>
      </>
    );
  }

  const c = customer.data;
  return (
    <>
      <PageHeader
        back={back}
        title={
          <span className="flex flex-wrap items-center gap-3">
            {c.name ?? "Unnamed customer"}
            {!c.isActive ? <Badge variant="secondary">Inactive</Badge> : null}
          </span>
        }
        description={
          <a href={`tel:${c.phone}`} className="tabular inline-flex items-center gap-1.5 hover:text-foreground">
            <Phone className="size-3.5" /> {phone(c.phone)}
          </a>
        }
        actions={
          <Button asChild>
            <Link href={`/orders/new?customer=${c.id}`}>
              <Plus /> New order
            </Link>
          </Button>
        }
      />
      <PageBody>
        <div className="grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]">
          <div className="flex min-w-0 flex-col gap-6">
            <ProfileCard customer={c} />
            <AddressesCard customerId={c.id} />
          </div>
          <div className="min-w-0">
            <CustomerOrdersCard customerId={c.id} />
          </div>
        </div>
      </PageBody>
    </>
  );
}
