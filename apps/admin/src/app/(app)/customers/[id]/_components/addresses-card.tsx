"use client";

import { MapPin, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { ErrorState } from "@/components/page";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Address } from "@/lib/api/types";
import { AddressDialog } from "../../_components/address-dialog";
import { useCustomerAddresses } from "../../_components/queries";

/** The API allows up to this many saved addresses per customer. */
const MAX_ADDRESSES = 10;

export function AddressesCard({ customerId }: { customerId: string }) {
  const addresses = useCustomerAddresses(customerId);
  const [editing, setEditing] = useState<Address | "new" | null>(null);
  const list = addresses.data ?? [];
  const full = list.length >= MAX_ADDRESSES;

  const remove = useApiMutation(
    (addressId: string) =>
      unwrap(api.DELETE("/v1/admin/customers/{id}/addresses/{addressId}", { params: { path: { id: customerId, addressId } } })),
    { invalidate: [["customer", customerId, "addresses"]], success: "Address deleted" },
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Addresses</CardTitle>
        {full ? <CardDescription>A customer can have up to {MAX_ADDRESSES} addresses. Delete one to add another.</CardDescription> : null}
        <CardAction>
          <Button variant="outline" size="sm" disabled={!addresses.data || full} onClick={() => setEditing("new")}>
            <Plus /> Add address
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        {addresses.isError ? (
          <ErrorState error={addresses.error} onRetry={() => void addresses.refetch()} />
        ) : !addresses.data ? (
          <Skeleton className="h-20" />
        ) : list.length === 0 ? (
          <p className="flex items-start gap-2 rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
            <MapPin className="mt-0.5 size-4 shrink-0" />
            No saved addresses. Addresses added here or in the app appear here and can be picked for new orders.
          </p>
        ) : (
          <ul className="grid gap-3">
            {list.map((a) => (
              <li key={a.id} className="flex items-start gap-3 rounded-lg border p-3">
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-1.5">
                    <span className="text-sm font-medium">{a.label}</span>
                    {a.isPrimary ? <Badge variant="secondary">Primary</Badge> : null}
                    {a.serviceable ? null : (
                      <Badge variant="outline" title="Customers can't book pickups here. Staff can still place phone orders.">
                        Outside service area
                      </Badge>
                    )}
                  </div>
                  <p className="mt-1 text-sm text-muted-foreground">{a.formatted}</p>
                </div>
                <div className="flex shrink-0 gap-1">
                  <Button variant="ghost" size="icon-sm" aria-label={`Edit ${a.label} address`} onClick={() => setEditing(a)}>
                    <Pencil />
                  </Button>
                  <ConfirmDialog
                    destructive
                    title={`Delete the ${a.label} address?`}
                    confirmLabel="Delete address"
                    description={
                      <span className="grid gap-2">
                        <span>{a.formatted}</span>
                        <span>
                          Orders already placed keep their copy of this address.
                          {a.isPrimary && list.length > 1 ? " The oldest remaining address becomes the primary one." : ""}
                        </span>
                      </span>
                    }
                    trigger={
                      <Button variant="ghost" size="icon-sm" aria-label={`Delete ${a.label} address`} className="text-muted-foreground hover:text-destructive">
                        <Trash2 />
                      </Button>
                    }
                    onConfirm={() => remove.mutateAsync(a.id)}
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
      {editing ? (
        <AddressDialog
          customerId={customerId}
          address={editing === "new" ? undefined : editing}
          firstAddress={editing === "new" && list.length === 0}
          onClose={() => setEditing(null)}
        />
      ) : null}
    </Card>
  );
}
