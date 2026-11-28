import { CalendarClock, MessageSquareText, ShieldCheck } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { SmartStoreButtons } from "@/components/smart-store-buttons";
import { areaPages, localities } from "@/lib/areas";
import { launchOffer } from "@/lib/offer";
import { formatDate } from "@/lib/posts";
import { site } from "@/lib/site";

/**
 * The download page that Instagram auto-DMs, bag tags and society posters point to: /get?src=ig&c=<campaign>, /get?src=bag,
 * /get?src=rwa. Kept small (no photos, one tiny client island) so it opens fast on a phone. Not in the main navigation.
 */
const title = "Get the IronDost app: laundry picked up from your door";
const description = `${launchOffer.headline}. Book laundry, ironing and dry cleaning pickup around LB Nagar, Hyderabad in the IronDost app.`;

export const metadata: Metadata = {
  title,
  description,
  alternates: { canonical: "/get" },
  openGraph: { title: `${title} | ${site.name}`, description },
};

const features = [
  { icon: CalendarClock, title: "Pick a time window", body: "Morning, afternoon or evening, any day. We come to your door in that window." },
  { icon: MessageSquareText, title: "Add a care note", body: "Tell us about a stain, a delicate fabric or how you like it folded." },
  { icon: ShieldCheck, title: "Approve any price change first", body: "If the count at your door changes the total, you approve it before you're charged." },
];

export default function GetPage() {
  const terms = [launchOffer.cap, launchOffer.endsOn ? `until ${formatDate(launchOffer.endsOn)}` : null].filter(Boolean).join(", ");
  return (
    <div className="mx-auto max-w-xl px-4 py-10 sm:px-6 sm:py-16">
      <h1 className="font-display text-3xl font-bold tracking-tight sm:text-4xl">Laundry picked up from your door, back fresh</h1>
      <p className="mt-3 text-lg text-muted">Wash &amp; iron, ironing and dry cleaning around LB Nagar, Hyderabad.</p>

      <section aria-labelledby="offer" className="mt-7 rounded-3xl bg-ink p-6 text-white">
        <p className="text-sm font-semibold uppercase tracking-wider text-sun">Launch offer</p>
        <h2 id="offer" className="mt-1 font-display text-2xl font-semibold">
          {launchOffer.headline}
        </h2>
        <p className="mt-3 text-white/85">
          Use code{" "}
          <span className="rounded-lg bg-white px-2.5 py-1 font-mono text-lg font-bold tracking-wider text-ink">{launchOffer.code}</span> at
          checkout{terms ? ` (${terms})` : ""}.
        </p>
        <div className="mt-6">
          <SmartStoreButtons onDark />
        </div>
      </section>

      <ul className="mt-8 space-y-4">
        {features.map((f) => (
          <li key={f.title} className="flex gap-4">
            <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-mist text-royal">
              <f.icon aria-hidden className="size-5" />
            </span>
            <span>
              <span className="block text-lg font-semibold">{f.title}</span>
              <span className="block leading-relaxed text-muted">{f.body}</span>
            </span>
          </li>
        ))}
      </ul>

      <section aria-labelledby="areas" className="mt-10">
        <h2 id="areas" className="font-display text-xl font-semibold">
          Where we pick up
        </h2>
        <p className="mt-2 text-muted">Within 6 km of LB Nagar Circle. The app checks your address when you add it.</p>
        <ul className="mt-4 flex flex-wrap gap-2">
          {areaPages.map((a) => (
            <li key={a.slug}>
              <Link href={`/laundry/${a.slug}`} className="inline-block rounded-full border border-ring px-3.5 py-1.5 hover:border-royal hover:text-royal">
                {a.name}
              </Link>
            </li>
          ))}
        </ul>
        <p className="mt-3 text-sm text-muted">PIN codes {localities.map((l) => l.pin).join(", ")}</p>
      </section>

      <p className="mt-10 text-muted">
        Prefer to talk? Call or WhatsApp{" "}
        <a href={`tel:${site.phone.tel}`} className="font-semibold text-royal underline-offset-4 hover:underline">
          {site.phone.display}
        </a>
        . See all{" "}
        <Link href="/prices" className="font-semibold text-royal underline-offset-4 hover:underline">
          prices
        </Link>
        .
      </p>
    </div>
  );
}
