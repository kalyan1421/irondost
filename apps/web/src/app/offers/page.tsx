import type { Metadata } from "next";
import { SmartStoreButtons } from "@/components/smart-store-buttons";
import { launchOffer } from "@/lib/offer";
import { site } from "@/lib/site";

/** /offers is an App Link into the app's offers screen. Without the app (or on a computer) this page shows the current offer. */
export const metadata: Metadata = {
  title: "Offers",
  description: `${launchOffer.headline}. Use code ${launchOffer.code} in the ${site.name} app.`,
  alternates: { canonical: "/get" },
};

export default function OffersPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-12 sm:px-6 sm:py-16">
      <p className="text-sm font-semibold uppercase tracking-wider text-royal">Current offer</p>
      <h1 className="mt-1 font-display text-3xl font-bold tracking-tight sm:text-4xl">{launchOffer.headline}</h1>
      <p className="mt-4 text-lg leading-relaxed">
        Use code <span className="rounded-lg bg-mist px-2.5 py-1 font-mono font-bold tracking-wider">{launchOffer.code}</span> at checkout in
        the IronDost app.
      </p>
      <div className="mt-8">
        <SmartStoreButtons src="web" campaign="offers" />
      </div>
    </div>
  );
}
