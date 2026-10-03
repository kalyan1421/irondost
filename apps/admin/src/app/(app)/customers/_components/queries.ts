"use client";

import { useQuery } from "@tanstack/react-query";
import { api, unwrap } from "@/lib/api/client";

/** One customer's profile. Disabled until an id is known. */
export function useCustomer(id: string | null) {
  return useQuery({
    queryKey: ["customer", id],
    queryFn: () => unwrap(api.GET("/v1/admin/customers/{id}", { params: { path: { id: id ?? "" } } })),
    enabled: Boolean(id),
  });
}

/** A customer's saved addresses, primary first. Disabled until an id is known. */
export function useCustomerAddresses(id: string | null) {
  return useQuery({
    queryKey: ["customer", id, "addresses"],
    queryFn: () => unwrap(api.GET("/v1/admin/customers/{id}/addresses", { params: { path: { id: id ?? "" } } })),
    enabled: Boolean(id),
  });
}
