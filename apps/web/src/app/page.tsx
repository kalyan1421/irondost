import { MapPin, MessageCircle, Phone as PhoneIcon, Shirt, Sparkles, WashingMachine } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { GuideCards } from "@/components/guide-cards";
import { Journey } from "@/components/journey/journey";
import { StoreButtons } from "@/components/store-buttons";
import { site } from "@/lib/site";

const title = "Ironing, Laundry and Dry Cleaning Pickup in LB Nagar, Hyderabad";
const description =
  "IronDost picks up from your door in LB Nagar, Dilsukhnagar, Nagole, Vanasthalipuram and nearby, and brings your clothes back ironed, washed or dry-cleaned, usually the next day. Book a pickup in the app.";

export const metadata: Metadata = {
  title: { absolute: `${title} | ${site.name}` },
  description,
  alternates: { canonical: "/" },
  openGraph: { title: `${title} | ${site.name}`, description },
};

const localities = [
  { pin: "500074", names: ["LB Nagar"] },
  { pin: "500060", names: ["Dilsukhnagar", "Chaitanyapuri"] },
  { pin: "500035", names: ["Saroornagar", "HUDA Complex"] },
  { pin: "500068", names: ["Mansoorabad", "Nagole", "Bandlaguda"] },
  { pin: "500070", names: ["Vanasthalipuram"] },
  { pin: "500079", names: ["Karmanghat", "Champapet"] },
  { pin: "500059", names: ["Santosh Nagar", "Saidabad"] },
];

const steps = [
  { title: "Choose your clothes", body: "Ironing, wash and iron, or dry cleaning. A rough count is fine." },
  { title: "Pick a window", body: "7 to 11 am, 11 am to 4 pm or 4 to 8 pm, every day." },
  { title: "Hand over at your door", body: "Your partner counts the clothes with you before anything leaves." },
  { title: "Back at your door", body: "Usually the next day. Pay online or in cash when it arrives." },
];

const services = [
  { icon: Sparkles, name: "Dry cleaning", body: "Suits, blazers, silk sarees and anything with zari, embroidery or beadwork." },
  { icon: Shirt, name: "Ironing", body: "Shirts, trousers, kurtas, sarees and more, pressed and brought back on a hanger or folded." },
  { icon: WashingMachine, name: "Wash and iron", body: "Everyday clothes and bedsheets, washed, dried and ironed." },
];

const faqs = [
  {
    q: "When will my clothes come back?",
    a: "Usually the next day. You choose the delivery window when you book, and dry cleaning can take longer: ask us if you need it for a date.",
  },
  { q: "How do I pay?", a: "Online with UPI, cards or netbanking, or in cash when your clothes are delivered. You choose at checkout." },
  { q: "Can I cancel?", a: "Yes, in the app until your clothes are picked up. After pickup, call us and we'll help." },
  {
    q: "What if something is damaged or missing?",
    a: "Tell us within 48 hours of delivery, with your order number. We'll look into it and offer a repair, a replacement or a refund.",
  },
  {
    q: "How do refunds work?",
    a: "If you paid online and the order is cancelled, or we agree a refund, it goes back to the payment method you used within 7 to 14 business days.",
  },
];

const whatsapp = `https://wa.me/${site.phone.tel.replace(/\D/g, "")}?text=${encodeURIComponent("Hi IronDost, I'd like to book a pickup.")}`;

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "DryCleaningOrLaundry",
  name: site.name,
  description: site.description,
  url: site.url,
  logo: `${site.url}/brand/irondost-mark.svg`,
  image: `${site.url}/redesign/hero-suit-cover.webp`,
  telephone: site.phone.tel,
  email: site.email,
  areaServed: [
    ...localities.flatMap((l) => l.names.map((name) => ({ "@type": "Place", name: `${name}, Hyderabad`, address: { "@type": "PostalAddress", postalCode: l.pin, addressLocality: "Hyderabad", addressRegion: "Telangana", addressCountry: "IN" } }))),
    {
      "@type": "GeoCircle",
      geoMidpoint: { "@type": "GeoCoordinates", latitude: 17.3457, longitude: 78.5522 },
      geoRadius: "6000",
    },
  ],
  sameAs: [site.playStoreUrl, site.appStoreUrl].filter(Boolean),
  parentOrganization: { "@type": "Organization", name: site.company },
};

/** Real app screens (14 Nov captures) in a phone frame. Screens without prices only, until prices are confirmed. */
function AppPhones() {
  const frame = "overflow-hidden rounded-[2rem] border-[6px] border-ink bg-ink shadow-2xl shadow-ink/30";
  return (
    <>
      <div className={`${frame} w-1/2`}>
        {/* eslint-disable-next-line @next/next/no-img-element -- static export */}
        <img src="/redesign/screen-welcome.webp" alt="The IronDost app's welcome screen: fresh clothes, back at your door." width={540} height={1169} className="block h-auto w-full rounded-[1.6rem]" loading="lazy" />
      </div>
      <div className={`${frame} mb-8 w-1/2`}>
        {/* eslint-disable-next-line @next/next/no-img-element -- static export */}
        <img src="/redesign/screen-schedule.webp" alt="Choosing a pickup window and a delivery time in the IronDost app." width={540} height={1169} className="block h-auto w-full rounded-[1.6rem]" loading="lazy" />
      </div>
    </>
  );
}

export default function HomePage() {
  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }} />

      <Journey phones={<AppPhones />} />

      {/* Book */}
      <section id="book" className="on-dark relative scroll-mt-16 bg-ink text-white">
        <span id="download" className="absolute -top-16" aria-hidden />
        <div className="mx-auto grid max-w-6xl gap-12 px-4 py-20 sm:px-6 sm:py-28 lg:grid-cols-[1.2fr_1fr] lg:items-center">
          <div>
            <h2 className="font-display text-5xl font-bold tracking-tight sm:text-6xl">Book a pickup</h2>
            <p className="mt-5 max-w-xl text-xl leading-relaxed text-white/85">
              {site.name} picks up your clothes from your door around LB Nagar, Hyderabad, and brings them back ironed, washed or
              dry-cleaned, usually the next day. Book in the app in a minute, see every price before you confirm, and pay online or in
              cash at delivery.
            </p>
            <div className="mt-9">
              <StoreButtons onDark />
            </div>
          </div>
          <div className="rounded-3xl bg-white/[0.06] p-7 ring-1 ring-white/15">
            <p className="font-display text-2xl font-semibold">Rather talk to us?</p>
            <ul className="mt-5 space-y-3 text-lg">
              <li>
                <a href={whatsapp} className="inline-flex min-h-11 items-center gap-3 font-semibold text-white underline-offset-4 hover:underline">
                  <MessageCircle aria-hidden className="size-6 text-sun" />
                  WhatsApp {site.phone.display}
                </a>
              </li>
              <li>
                <a href={`tel:${site.phone.tel}`} className="inline-flex min-h-11 items-center gap-3 font-semibold text-white underline-offset-4 hover:underline">
                  <PhoneIcon aria-hidden className="size-6 text-sun" />
                  Call {site.phone.display}
                </a>
              </li>
              <li className="text-white/75">Second line: 70329 90632</li>
            </ul>
          </div>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="mx-auto max-w-6xl scroll-mt-16 px-4 py-20 sm:px-6 sm:py-28">
        <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">How booking works</h2>
        <ol className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s, i) => (
            <li key={s.title}>
              <span aria-hidden className="font-display text-5xl font-bold text-royal">
                {i + 1}
              </span>
              <h3 className="mt-3 font-display text-2xl font-semibold">{s.title}</h3>
              <p className="mt-2 text-lg leading-relaxed text-muted">{s.body}</p>
            </li>
          ))}
        </ol>
      </section>

      {/* Services */}
      <section id="services" className="scroll-mt-16 bg-chrome">
        <div className="mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28">
          <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">What we do</h2>
          <p className="mt-4 max-w-2xl text-xl text-muted">Prices are per piece and shown in the app before you book.</p>
          <ul className="mt-12 grid gap-6 md:grid-cols-3">
            {services.map(({ icon: Icon, name, body }) => (
              <li key={name} className="rounded-3xl bg-white p-8 ring-1 ring-ring">
                <span className="flex size-14 items-center justify-center rounded-2xl bg-mist text-royal">
                  <Icon aria-hidden className="size-7" />
                </span>
                <h3 className="mt-6 font-display text-2xl font-semibold">{name}</h3>
                <p className="mt-2 text-lg leading-relaxed text-muted">{body}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* Areas */}
      <section id="areas" className="mx-auto max-w-6xl scroll-mt-16 px-4 py-20 sm:px-6 sm:py-28">
        <div className="flex items-start gap-5">
          <span className="hidden size-14 shrink-0 items-center justify-center rounded-2xl bg-mist text-royal sm:flex">
            <MapPin aria-hidden className="size-7" />
          </span>
          <div>
            <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Areas we serve around LB Nagar</h2>
            <p className="mt-4 max-w-3xl text-xl text-muted">
              Within 6 km of LB Nagar Circle, in seven PIN codes. The app checks your address when you add it.{" "}
              <Link href="/blog/areas-we-serve-around-lb-nagar" className="font-semibold text-royal underline-offset-4 hover:underline">
                More about our area
              </Link>
            </p>
          </div>
        </div>
        <ul className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {localities.map((l) => (
            <li key={l.pin} className="rounded-2xl border border-ring p-5">
              <p className="font-display text-xl font-bold text-royal">{l.pin}</p>
              <p className="mt-1 text-lg">{l.names.join(", ")}</p>
            </li>
          ))}
        </ul>
      </section>

      {/* FAQ */}
      <section id="faq" className="scroll-mt-16 bg-chrome">
        <div className="mx-auto max-w-3xl px-4 py-20 sm:px-6 sm:py-28">
          <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Common questions</h2>
          <div className="mt-10 divide-y divide-ring rounded-3xl border border-ring bg-white">
            {faqs.map((f, i) => (
              <details key={f.q} className="group px-6 py-5" open={i === 0}>
                <summary className="flex min-h-11 cursor-pointer items-center justify-between gap-4 text-xl font-semibold">
                  {f.q}
                  <span aria-hidden className="text-3xl font-normal text-royal transition-transform group-open:rotate-45">
                    +
                  </span>
                </summary>
                <p className="mt-3 text-lg leading-relaxed text-muted">{f.a}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* Guides */}
      <section id="guides" className="mx-auto max-w-6xl scroll-mt-16 px-4 py-20 sm:px-6 sm:py-28">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Guides</h2>
            <p className="mt-3 max-w-2xl text-lg text-muted">Straight answers to what people ask before they hand over their clothes.</p>
          </div>
          <Link href="/blog" className="font-semibold text-royal underline-offset-4 hover:underline">
            All guides
          </Link>
        </div>
        <div className="mt-10">
          <GuideCards />
        </div>
      </section>
    </>
  );
}
