import type { Metadata } from "next";
import Link from "next/link";
import { StoreButtons } from "@/components/store-buttons";
import { formatDate } from "@/lib/posts";
import { priceList, pricesUpdated, type PriceItem } from "@/lib/prices";
import { site } from "@/lib/site";

const find = (category: string, name: string) =>
  priceList.find((c) => c.slug === category)?.items.find((i) => i.name.toLowerCase().startsWith(name.toLowerCase()));
const now = (i?: PriceItem) => (i ? (i.offer ?? i.price) : undefined);

const shirt = find("ironing", "shirt");
const saree = find("ironing", "saree");
const washShirt = find("wash-and-iron", "shirt");
const suit = priceList.find((c) => c.name.toLowerCase().includes("dry"))?.items[0];

export const metadata: Metadata = {
  title: "Laundry and ironing prices in LB Nagar, Hyderabad",
  description: `Laundry (wash and iron) from ₹${now(washShirt)} a shirt, shirt ironing ₹${now(shirt)}, saree ₹${now(saree)}, suit dry cleaning ₹${now(suit)}. The full IronDost rate card, with doorstep pickup around LB Nagar.`,
  alternates: { canonical: "/prices" },
};

const rupees = (n: number) => `₹${n}`;

export default function PricesPage() {
  const jsonLd = [
    {
      "@context": "https://schema.org",
      "@type": "OfferCatalog",
      name: `${site.name} rate card`,
      url: `${site.url}/prices`,
      itemListElement: priceList.map((c) => ({
        "@type": "OfferCatalog",
        name: c.name,
        itemListElement: c.items.map((i) => ({
          "@type": "Offer",
          price: now(i),
          priceCurrency: "INR",
          itemOffered: { "@type": "Service", name: `${c.name}: ${i.name}`, provider: { "@type": "Organization", name: site.name } },
        })),
      })),
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: [
        { "@type": "ListItem", position: 1, name: "Home", item: `${site.url}/` },
        { "@type": "ListItem", position: 2, name: "Prices", item: `${site.url}/prices` },
      ],
    },
  ];

  return (
    <div className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }} />
      <h1 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">IronDost prices: laundry, ironing and dry cleaning</h1>
      <p className="mt-4 text-muted">
        Updated <time dateTime={pricesUpdated}>{formatDate(pricesUpdated)}</time> · Per piece · Around LB Nagar, Hyderabad
      </p>
      <p className="mt-6 text-xl leading-relaxed">
        Laundry, washed and ironed, costs {rupees(now(washShirt) ?? 0)} a shirt. Shirt ironing alone is {rupees(now(shirt) ?? 0)} a piece
        {shirt?.offer ? ` on the current offer (${rupees(shirt.price)} regular)` : ""}, saree ironing {rupees(now(saree) ?? 0)}, and suit dry
        cleaning {rupees(now(suit) ?? 0)}. You see every price and the total in the app
        before you confirm, and we pick up from your door.
      </p>

      {priceList.map((c) => (
        <section key={c.slug} className="mt-12" aria-labelledby={`prices-${c.slug}`}>
          <h2 id={`prices-${c.slug}`} className="font-display text-2xl font-semibold">
            {c.slug === "wash-and-iron" ? "Laundry: wash and iron prices" : `${c.name.replace("&", "and")} prices`}
          </h2>
          <table className="mt-4 w-full overflow-hidden rounded-2xl text-left text-lg ring-1 ring-ring">
            <thead className="bg-mist text-base">
              <tr>
                <th scope="col" className="px-5 py-3 font-semibold">
                  Item
                </th>
                <th scope="col" className="px-5 py-3 text-right font-semibold">
                  Price per piece
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
          {c.slug === "wash-and-iron" && (
            <p className="mt-3 text-muted">
              Washed in our own machines and checked by hand. Wash & Fold prices are not on the rate card yet: ask us before you book.{" "}
              <Link href="/laundry" className="font-semibold text-royal underline-offset-4 hover:underline">
                About our laundry
              </Link>
            </p>
          )}
          {c.slug.includes("dry") && <p className="mt-3 text-muted">We will try to remove stains, but we cannot promise it.</p>}
        </section>
      ))}

      <section className="mt-14 space-y-10">
        <div>
          <h2 className="font-display text-2xl font-semibold">Will the price change after pickup?</h2>
          <p className="mt-3 text-lg leading-relaxed">
            Only if the number of clothes counted at your door is different from what you entered. The count is agreed with you before anything
            is washed or pressed.{" "}
            <Link href="/blog/will-laundry-bill-change-after-pickup" className="font-semibold text-royal underline-offset-4 hover:underline">
              How the bill works
            </Link>
          </p>
        </div>
        <div>
          <h2 className="font-display text-2xl font-semibold">Which areas do you serve?</h2>
          <p className="mt-3 text-lg leading-relaxed">
            Within 6 km of LB Nagar Circle, in PIN codes 500074, 500060, 500035, 500068, 500070, 500079 and 500059.{" "}
            <Link href="/blog/areas-we-serve-around-lb-nagar" className="font-semibold text-royal underline-offset-4 hover:underline">
              See all 14 localities
            </Link>
          </p>
        </div>
      </section>

      <aside className="mt-14 rounded-3xl bg-ink p-7 text-white">
        <h2 className="font-display text-2xl font-semibold">Book a pickup</h2>
        <p className="mt-2 text-lg text-white/85">
          Get the app, or call or WhatsApp{" "}
          <a href={`tel:${site.phone.tel}`} className="font-semibold text-white underline underline-offset-4">
            {site.phone.display}
          </a>
          .
        </p>
        <div className="mt-6">
          <StoreButtons onDark />
        </div>
      </aside>
    </div>
  );
}
