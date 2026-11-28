import type { Metadata } from "next";
import { OrderFallback } from "@/components/app-link-fallback";
import { site } from "@/lib/site";

/** Fallback for order links /o/<id> when the app is not installed or the link is opened on a computer. */
export const metadata: Metadata = {
  title: "Open your order in the app",
  description: `Track your ${site.name} order in the app.`,
  robots: { index: false, follow: false },
};

export default function OrderLinkPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-12 sm:px-6 sm:py-16">
      <h1 className="font-display text-3xl font-bold tracking-tight sm:text-4xl">Open your order in the IronDost app</h1>
      <OrderFallback />
      <p className="mt-8 text-muted">
        Need help with an order? Call or WhatsApp{" "}
        <a href={`tel:${site.phone.tel}`} className="font-semibold text-royal underline-offset-4 hover:underline">
          {site.phone.display}
        </a>
        .
      </p>
    </div>
  );
}
