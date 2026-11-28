import type { Metadata } from "next";
import Link from "next/link";
import { StoreButtons } from "@/components/store-buttons";
import { localities, areaServed } from "@/lib/areas";
import { formatDate } from "@/lib/posts";
import { priceList, pricesUpdated, type PriceItem } from "@/lib/prices";
import { site } from "@/lib/site";

/** Wash & Iron rates come from the rate card (lib/prices.ts). Wash & Fold has no confirmed prices, so none are shown. */
const washAndIron = priceList.find((c) => c.slug === "wash-and-iron");
const items = washAndIron?.items ?? [];
const now = (i: PriceItem) => i.offer ?? i.price;
const shirt = items.find((i) => i.name.toLowerCase().startsWith("shirt"));
const rupees = (n: number) => `₹${n}`;

const title = "Laundry pickup in LB Nagar, Hyderabad: wash and iron, priced per piece";
const description = `Laundry picked up from your door around LB Nagar${shirt ? `, wash and iron from ${rupees(now(shirt))} a shirt` : ""}. Washed in IronDost's own machines and checked by hand before it comes back.`;

export const metadata: Metadata = {
  title,
  description,
  alternates: { canonical: "/laundry" },
  openGraph: { title: `${title} | ${site.name}`, description },
};

const covers = [
  {
    name: "Wash & Iron",
    body: "Everyday clothes and bedsheets: shirts, T-shirts, trousers, jeans and bedsheets. Washed, dried, ironed and packed, so they are ready to wear or use.",
  },
  {
    name: "Wash & Fold",
    body: "The same wash for things that do not need pressing, like towels and clothes you wear at home. Washed, dried and folded, with no ironing. Wash & Fold is new and its prices are not on the rate card yet, so ask us before you book.",
  },
];

const notForTheMachine = [
  "Suits and blazers",
  "Silk sarees",
  "Anything with zari, embroidery, beadwork or sequins",
  "Anything labelled dry clean only",
];

const faqs = [
  {
    q: "How is laundry priced?",
    a: "Per piece, not by weight. Every price is in the app and you see the total before you confirm. The total changes only if the count at your door is different from what you entered.",
  },
  {
    q: "Who washes my clothes?",
    a: "We do, in IronDost's own machines. The owner checks every load by hand before it is packed and comes back to you.",
  },
  {
    q: "What does Wash & Fold cost?",
    a: "Wash & Fold is new and its prices are not published yet. Call or WhatsApp us before you book and we will tell you.",
  },
  {
    q: "Can you remove every stain?",
    a: "No. Show us any stain when you hand the clothes over. We will try to remove it, but we cannot promise it.",
  },
  {
    q: "Do you pick up in my area?",
    a: "We pick up within 6 km of LB Nagar Circle, in PIN codes 500074, 500060, 500035, 500068, 500070, 500079 and 500059. The app checks your address when you add it.",
  },
  {
    q: "How do I pay?",
    a: "Online with UPI, cards or netbanking, or in cash when your clothes are delivered. You choose at checkout.",
  },
];

export default function LaundryPage() {
  const jsonLd = [
    {
      "@context": "https://schema.org",
      "@type": "Service",
      name: "Laundry: wash and iron",
      serviceType: "Laundry service",
      description,
      url: `${site.url}/laundry`,
      provider: { "@type": "DryCleaningOrLaundry", name: site.name, url: site.url, telephone: site.phone.tel },
      areaServed,
      hasOfferCatalog: {
        "@type": "OfferCatalog",
        name: "Wash and iron prices",
        itemListElement: items.map((i) => ({
          "@type": "Offer",
          price: now(i),
          priceCurrency: "INR",
          itemOffered: { "@type": "Service", name: `Wash & Iron: ${i.name}` },
        })),
      },
    },
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      mainEntity: faqs.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: [
        { "@type": "ListItem", position: 1, name: "Home", item: `${site.url}/` },
        { "@type": "ListItem", position: 2, name: "Laundry", item: `${site.url}/laundry` },
      ],
    },
  ];

  return (
    <div className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }} />
      <h1 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Laundry picked up from your door, priced per piece</h1>
      <p className="mt-4 text-muted">Wash and iron · Wash and fold · Around LB Nagar, Hyderabad</p>
      <p className="mt-6 text-xl leading-relaxed">
        IronDost picks up your laundry from your door around LB Nagar, washes it in our own machines, and brings it back ironed and
        packed{shirt ? `, from ${rupees(now(shirt))} a shirt` : ""}. The owner checks every load by hand before it goes back. You see every
        price and the total in the app before you confirm.
      </p>

      <figure className="mt-10 overflow-hidden rounded-3xl bg-mist">
        {/* eslint-disable-next-line @next/next/no-img-element -- static export, images are pre-sized WebP */}
        <img src="/redesign/finished-bed.webp" alt="Pressed shirts and folded clothes laid out on a bed, ready for the week." className="aspect-[16/9] w-full object-cover" />
      </figure>

      <section className="mt-12" aria-labelledby="laundry-covers">
        <h2 id="laundry-covers" className="font-display text-2xl font-semibold">
          What Wash & Iron and Wash & Fold cover
        </h2>
        <ul className="mt-4 grid gap-4 sm:grid-cols-2">
          {covers.map((c) => (
            <li key={c.name} className="rounded-3xl bg-white p-6 ring-1 ring-ring">
              <h3 className="font-display text-xl font-semibold">{c.name}</h3>
              <p className="mt-2 text-lg leading-relaxed text-muted">{c.body}</p>
            </li>
          ))}
        </ul>
        <p className="mt-6 text-lg leading-relaxed">These go to dry cleaning instead of the machine:</p>
        <ul className="mt-3 list-disc space-y-2 pl-6 text-lg leading-relaxed marker:text-royal">
          {notForTheMachine.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ul>
        <p className="mt-3 text-lg leading-relaxed">
          Not sure?{" "}
          <Link href="/blog/wash-and-iron-or-dry-clean-which-fabric" className="font-semibold text-royal underline-offset-4 hover:underline">
            Wash and iron or dry clean: a fabric guide
          </Link>
        </p>
      </section>

      <section className="mt-12" aria-labelledby="laundry-prices">
        <h2 id="laundry-prices" className="font-display text-2xl font-semibold">
          Wash and iron prices
        </h2>
        <p className="mt-2 text-muted">
          Per piece · Updated <time dateTime={pricesUpdated}>{formatDate(pricesUpdated)}</time>
        </p>
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
            {items.map((i) => (
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
        <p className="mt-3 text-muted">
          Wash & Fold prices are not on the rate card yet.{" "}
          <Link href="/prices" className="font-semibold text-royal underline-offset-4 hover:underline">
            Ironing and dry cleaning prices
          </Link>
        </p>
      </section>

      <section className="mt-12" aria-labelledby="laundry-how">
        <h2 id="laundry-how" className="font-display text-2xl font-semibold">
          How we wash
        </h2>
        <ol className="mt-4 space-y-4">
          {[
            { title: "Counted at your door", body: "Your partner counts the clothes with you before anything leaves. Show us any stain or anything that may lose colour." },
            { title: "Washed in our own machines", body: "Your laundry is washed by IronDost, in our own machines. It is not sent out to another laundry." },
            { title: "Checked by the owner", body: "The owner checks every load by hand before it is ironed or folded, packed and sent back to you." },
          ].map((st, i) => (
            <li key={st.title} className="flex gap-4">
              <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-royal font-semibold text-white">{i + 1}</span>
              <span>
                <span className="block text-lg font-semibold">{st.title}</span>
                <span className="block text-lg leading-relaxed text-muted">{st.body}</span>
              </span>
            </li>
          ))}
        </ol>
        <p className="mt-4 text-lg leading-relaxed">
          <Link href="/blog/how-to-pack-your-laundry-bag-for-pickup" className="font-semibold text-royal underline-offset-4 hover:underline">
            How to pack your laundry bag for pickup
          </Link>
        </p>
      </section>

      <section className="mt-12" aria-labelledby="laundry-areas">
        <h2 id="laundry-areas" className="font-display text-2xl font-semibold">
          Areas we serve
        </h2>
        <p className="mt-3 text-lg leading-relaxed">
          Within 6 km of LB Nagar Circle, in seven PIN codes. The app checks your address when you add it.{" "}
          <Link href="/blog/areas-we-serve-around-lb-nagar" className="font-semibold text-royal underline-offset-4 hover:underline">
            More about our area
          </Link>
        </p>
        <ul className="mt-4 grid gap-3 sm:grid-cols-2">
          {localities.map((l) => (
            <li key={l.pin} className="rounded-2xl border border-ring p-5">
              <p className="font-display text-xl font-bold text-royal">{l.pin}</p>
              <p className="mt-1 text-lg">{l.names.join(", ")}</p>
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-12" aria-labelledby="laundry-faq">
        <h2 id="laundry-faq" className="font-display text-2xl font-semibold">
          Questions
        </h2>
        <dl className="mt-3 space-y-5">
          {faqs.map((f) => (
            <div key={f.q}>
              <dt className="text-lg font-semibold">{f.q}</dt>
              <dd className="mt-1 text-lg leading-relaxed">{f.a}</dd>
            </div>
          ))}
        </dl>
      </section>

      <aside className="mt-14 rounded-3xl bg-ink p-7 text-white">
        <h2 className="font-display text-2xl font-semibold">Book a laundry pickup</h2>
        <p className="mt-2 text-lg text-white/85">
          Get the app, or call or WhatsApp{" "}
          <a href={`tel:${site.phone.tel}`} className="font-semibold text-white underline underline-offset-4">
            {site.phone.display}
          </a>{" "}
          (second line 70329 90632).
        </p>
        <div className="mt-6">
          <StoreButtons onDark />
        </div>
      </aside>
    </div>
  );
}
