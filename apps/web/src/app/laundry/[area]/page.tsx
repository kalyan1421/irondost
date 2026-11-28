import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { StoreButtons } from "@/components/store-buttons";
import { areaPages, getAreaPage, placeFor } from "@/lib/areas";
import { playStoreUrl } from "@/lib/install-links";
import { formatDate } from "@/lib/posts";
import { priceList, pricesUpdated, type PriceItem } from "@/lib/prices";
import { site } from "@/lib/site";

// Static export: one page per locality in lib/areas.ts, built at build time. Anything else is a 404.
export const dynamicParams = false;

export function generateStaticParams() {
  return areaPages.map((a) => ({ area: a.slug }));
}

const now = (i: PriceItem) => i.offer ?? i.price;
const rupees = (n: number) => `₹${n}`;
const shown = priceList.filter((c) => c.slug === "wash-and-iron" || c.slug === "ironing");
const shirt = priceList.find((c) => c.slug === "wash-and-iron")?.items.find((i) => i.name.toLowerCase().startsWith("shirt"));

const copy = (name: string, pin: string) => ({
  title: `Laundry and ironing pickup in ${name}, Hyderabad ${pin}`,
  description: `IronDost picks up laundry, ironing and dry cleaning from your door in ${name} (${pin})${shirt ? `: wash and iron from ${rupees(now(shirt))} a shirt` : ""}. Priced per piece, back the next day.`,
});

export async function generateMetadata(props: PageProps<"/laundry/[area]">): Promise<Metadata> {
  const { area } = await props.params;
  const a = getAreaPage(area);
  if (!a) return {};
  const { title, description } = copy(a.name, a.pin);
  return { title, description, alternates: { canonical: `/laundry/${a.slug}` }, openGraph: { title: `${title} | ${site.name}`, description } };
}

export default async function AreaPage(props: PageProps<"/laundry/[area]">) {
  const { area } = await props.params;
  const a = getAreaPage(area);
  if (!a) notFound();
  const { description } = copy(a.name, a.pin);
  const url = `${site.url}/laundry/${a.slug}`;
  const others = areaPages.filter((o) => o.slug !== a.slug);

  const jsonLd = [
    {
      "@context": "https://schema.org",
      "@type": "Service",
      name: `Laundry and ironing pickup in ${a.name}`,
      serviceType: "Laundry service",
      description,
      url,
      provider: {
        "@type": "DryCleaningOrLaundry",
        name: site.name,
        url: site.url,
        telephone: site.phone.tel,
        address: { "@type": "PostalAddress", addressLocality: "LB Nagar, Hyderabad", addressRegion: "Telangana", addressCountry: "IN" },
      },
      areaServed: placeFor(a.name, a.pin),
      hasOfferCatalog: {
        "@type": "OfferCatalog",
        name: "Prices per piece",
        itemListElement: shown.flatMap((c) =>
          c.items.map((i) => ({ "@type": "Offer", price: now(i), priceCurrency: "INR", itemOffered: { "@type": "Service", name: `${c.name}: ${i.name}` } })),
        ),
      },
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: [
        { "@type": "ListItem", position: 1, name: "Home", item: `${site.url}/` },
        { "@type": "ListItem", position: 2, name: "Laundry", item: `${site.url}/laundry` },
        { "@type": "ListItem", position: 3, name: a.name, item: url },
      ],
    },
  ];

  return (
    <div className="mx-auto max-w-3xl px-4 py-12 sm:px-6 sm:py-20">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }} />
      <p className="text-muted">
        <Link href="/laundry" className="hover:text-royal">
          Laundry
        </Link>{" "}
        / {a.name}
      </p>
      <h1 className="mt-2 font-display text-4xl font-bold tracking-tight sm:text-5xl">Laundry and ironing picked up from your door in {a.name}</h1>
      <p className="mt-5 text-xl leading-relaxed">
        IronDost collects your clothes from your home in {a.name}, PIN {a.pin}, washes and irons them in our own machines,
        and brings them back, usually the next day{shirt ? `. Wash and iron starts at ${rupees(now(shirt))} a shirt` : ""}. Every
        price is per piece and shown in the app before you confirm.
      </p>

      <div className="mt-8">
        <StoreButtons playUrl={playStoreUrl("web", a.slug)} />
      </div>

      <section className="mt-12" aria-labelledby="area-pin">
        <h2 id="area-pin" className="font-display text-2xl font-semibold">
          Is my address in {a.name} covered?
        </h2>
        <p className="mt-3 text-lg leading-relaxed">
          We pick up in PIN code <strong>{a.pin}</strong>
          {a.samePin.length ? `, which also covers ${a.samePin.join(" and ")}` : ""}, within 6 km of LB Nagar Circle. Add your address in the
          app and it tells you straight away.
        </p>
        <p className="mt-3 text-lg leading-relaxed">Pickup windows every day: 7 am to 11 am, 11 am to 4 pm and 4 pm to 8 pm.</p>
      </section>

      <section className="mt-12" aria-labelledby="area-prices">
        <h2 id="area-prices" className="font-display text-2xl font-semibold">
          Prices in {a.name}
        </h2>
        <p className="mt-2 text-muted">
          Per piece · Updated <time dateTime={pricesUpdated}>{formatDate(pricesUpdated)}</time>
        </p>
        {shown.map((c) => (
          <table key={c.slug} className="mt-4 w-full overflow-hidden rounded-2xl text-left text-lg ring-1 ring-ring">
            <caption className="sr-only">{c.name} prices</caption>
            <thead className="bg-mist text-base">
              <tr>
                <th scope="col" className="px-5 py-3 font-semibold">
                  {c.name}
                </th>
                <th scope="col" className="px-5 py-3 text-right font-semibold">
                  Per piece
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ring">
              {c.items.map((i) => (
                <tr key={i.name}>
                  <td className="px-5 py-3">{i.name}</td>
                  <td className="px-5 py-3 text-right font-semibold">
                    {i.offer ? (
                      <>
                        <span className="mr-2 text-base font-normal text-muted line-through">{rupees(i.price)}</span>
                        <span className="text-royal">{rupees(i.offer)}</span>
                      </>
                    ) : (
                      rupees(i.price)
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ))}
        <p className="mt-3 text-muted">
          <Link href="/prices" className="font-semibold text-royal underline-offset-4 hover:underline">
            Full rate card, with dry cleaning
          </Link>
        </p>
      </section>

      <aside className="mt-14 rounded-3xl bg-ink p-7 text-white">
        <h2 className="font-display text-2xl font-semibold">Book a pickup in {a.name}</h2>
        <p className="mt-2 text-lg text-white/85">
          Get the app, or call or WhatsApp{" "}
          <a href={`tel:${site.phone.tel}`} className="font-semibold text-white underline underline-offset-4">
            {site.phone.display}
          </a>
          .
        </p>
        <div className="mt-6">
          <StoreButtons onDark playUrl={playStoreUrl("web", a.slug)} />
        </div>
      </aside>

      <nav className="mt-12" aria-labelledby="area-others">
        <h2 id="area-others" className="font-display text-xl font-semibold">
          We also pick up in
        </h2>
        <ul className="mt-4 flex flex-wrap gap-2">
          {others.map((o) => (
            <li key={o.slug}>
              <Link href={`/laundry/${o.slug}`} className="inline-block rounded-full border border-ring px-3.5 py-1.5 hover:border-royal hover:text-royal">
                {o.name}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
    </div>
  );
}
