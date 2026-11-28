import type { Metadata } from "next";
import { ReferralFallback } from "@/components/app-link-fallback";
import { site } from "@/lib/site";

/** Fallback for referral links /r/<code> when the app is not installed or the link is opened on a computer. */
export const metadata: Metadata = {
  title: "You've been invited to IronDost",
  description: `A friend invited you to ${site.name}: laundry, ironing and dry cleaning picked up from your door around LB Nagar, Hyderabad.`,
  robots: { index: false, follow: true },
};

export default function ReferralPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-12 sm:px-6 sm:py-16">
      <h1 className="font-display text-3xl font-bold tracking-tight sm:text-4xl">A friend invited you to IronDost</h1>
      <p className="mt-3 text-lg text-muted">Laundry, ironing and dry cleaning picked up from your door around LB Nagar, Hyderabad.</p>
      <ReferralFallback />
    </div>
  );
}
