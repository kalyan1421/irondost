"use client";

import { useMutation, useQueryClient, type QueryKey } from "@tanstack/react-query";
import { toast } from "sonner";
import { errorMessage } from "./client";

/**
 * useMutation with the admin's conventions: refresh the listed queries,
 * toast the outcome, and surface the API's error message on failure.
 */
export function useApiMutation<TVars, TData>(
  fn: (vars: TVars) => Promise<TData>,
  opts: {
    invalidate?: QueryKey[];
    success?: string | ((data: TData, vars: TVars) => string);
    onSuccess?: (data: TData, vars: TVars) => void;
  } = {},
) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: async (data, vars) => {
      await Promise.all((opts.invalidate ?? []).map((queryKey) => queryClient.invalidateQueries({ queryKey })));
      if (opts.success) toast.success(typeof opts.success === "function" ? opts.success(data, vars) : opts.success);
      opts.onSuccess?.(data, vars);
    },
    onError: (err) => {
      toast.error(errorMessage(err));
    },
  });
}
