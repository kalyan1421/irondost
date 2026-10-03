"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { io } from "socket.io-client";
import { toast } from "sonner";
import { API_URL, getToken } from "@/lib/api/client";
import { useAuth } from "@/lib/auth/auth-provider";

interface OrderUpdated {
  orderId: string;
  orderNumber?: string;
  status?: string;
  reason: string;
}

/**
 * Keeps open screens current: when the API reports an order change, the
 * matching queries are refetched. New orders also raise a toast.
 */
export function RealtimeBridge() {
  const { state } = useAuth();
  const queryClient = useQueryClient();
  const router = useRouter();
  const signedIn = state.status === "signedIn";

  useEffect(() => {
    if (!signedIn) return;
    const socket = io(API_URL, {
      path: "/v1/realtime",
      transports: ["websocket"],
      auth: (cb) => {
        void getToken().then((token) => cb({ token }));
      },
    });
    socket.on("order.updated", (e: OrderUpdated) => {
      void queryClient.invalidateQueries({ queryKey: ["orders"] });
      void queryClient.invalidateQueries({ queryKey: ["order", e.orderId] });
      void queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      if (e.reason === "created" && e.orderNumber) {
        toast.info(`New order ${e.orderNumber}`, {
          action: { label: "Open", onClick: () => router.push(`/orders/${e.orderId}`) },
        });
      }
    });
    return () => {
      socket.disconnect();
    };
  }, [signedIn, queryClient, router]);

  return null;
}
