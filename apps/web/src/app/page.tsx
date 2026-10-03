import { Banknote, Bell, Clock, MapPin, Phone as PhoneIcon, Shirt, Sparkles, Truck, WashingMachine } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { Bubble } from "@/components/bubble";
import { Phone } from "@/components/phone";
import { StoreButtons } from "@/components/store-buttons";
import { site } from "@/lib/site";

export const metadata: Metadata = { alternates: { canonical: "/" } };

const steps = [
  { title: "Choose your items", body: "Pick ironing, wash and iron, or dry cleaning. A rough count is fine; your partner confirms it at pickup." },
  { title: "Pick a time", body: "Choose a pickup window and a delivery window that suit you. You see the bill before you book." },
  { title: "We collect and clean", body: "A partner collects your clothes from your door, and we iron, wash or dry-clean them." },
  { title: "Back at your door", body: "Your clothes come back, usually the next day. Pay online, or in cash when they arrive." },
];

const services = [
  { icon: Shirt, name: "Ironing", body: "Shirts, trousers, kurtas, sarees and more, pressed and brought back to you." },
  { icon: WashingMachine, name: "Wash and iron", body: "Washed, dried and ironed: everyday clothes, bedsheets and more." },
  { icon: Sparkles, name: "Dry cleaning", body: "For suits, blazers, silk sarees and other pieces that need careful handling." },
];

const faqs = [
  {
    q: "When will my clothes come back?",
    a: "You choose the delivery window when you book. Clothes usually come back the next day: a morning pickup is typically back by the next evening.",
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

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "DryCleaningOrLaundry",
  name: site.name,
  description: site.description,
  url: site.url,
  telephone: site.phone.tel,
  email: site.email,
  areaServed: { "@type": "City", name: site.area },
  parentOrganization: { "@type": "Organization", name: site.company },
};

export default function HomePage() {
  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      {/* Hero */}
      <section className="on-dark relative overflow-hidden bg-royal text-white">
        <Bubble className="-right-10 -top-10 size-40 opacity-90" />
        <Bubble className="left-[46%] top-16 hidden size-5 lg:block" />
        <div className="mx-auto grid max-w-6xl items-center gap-12 px-4 pb-0 pt-14 sm:px-6 lg:grid-cols-[1.1fr_1fr] lg:pb-0 lg:pt-20">
          <div className="pb-14 lg:pb-24">
            <p className="inline-flex items-center gap-2 rounded-full bg-white/15 px-4 py-1.5 text-sm font-semibold">
              <MapPin aria-hidden className="size-4" />
              Now in {site.area}
            </p>
            <h1 className="mt-6 font-display text-5xl font-bold leading-[1.05] tracking-tight sm:text-6xl">{site.tagline}</h1>
            <p className="mt-6 max-w-xl text-xl leading-relaxed text-white/90">
              IronDost collects your clothes, irons, washes or dry-cleans them, and brings them back. You pick the time and see the
              price before you book.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-4">
              <Link
                href="/#download"
                className="rounded-2xl bg-white px-7 py-4 text-lg font-semibold text-royal hover:bg-mist"
              >
                Get the app
              </Link>
              <Link href="/#how-it-works" className="rounded-2xl border-2 border-white/60 px-7 py-[14px] text-lg font-semibold hover:bg-white/10">
                How it works
              </Link>
            </div>
            <p className="mt-6 text-white/85">Pay online or in cash when your clothes arrive.</p>
          </div>

          <div className="relative mx-auto flex w-full max-w-md items-end justify-center gap-4 self-end sm:max-w-lg lg:max-w-none">
            <Phone screen="home" alt="The IronDost home screen with the services and an offer." className="w-[46%]" priority />
            <Phone
              screen="tracking"
              alt="Tracking an order that is out for delivery, with the partner's name and a call button."
              className="mb-0 w-[46%] translate-y-10"
              priority
            />
          </div>
        </div>
      </section>

      {/* Reassurance */}
      <section aria-label="Why IronDost" className="border-b border-ring bg-chrome">
        <ul className="mx-auto grid max-w-6xl gap-px px-4 py-8 sm:grid-cols-3 sm:px-6">
          {[
            { icon: Truck, text: "Pickup and delivery from your door" },
            { icon: Clock, text: "Ironed and back in about a day" },
            { icon: Banknote, text: "Pay online or in cash at delivery" },
          ].map(({ icon: Icon, text }) => (
            <li key={text} className="flex items-center gap-4 py-3 sm:justify-center">
              <span className="flex size-12 shrink-0 items-center justify-center rounded-xl bg-mist text-royal">
                <Icon aria-hidden className="size-6" />
              </span>
              <span className="text-lg font-semibold">{text}</span>
            </li>
          ))}
        </ul>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28">
        <div className="grid items-center gap-14 lg:grid-cols-[1fr_1fr]">
          <div>
            <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">How it works</h2>
            <p className="mt-4 text-xl text-muted">Four steps, all from your phone.</p>
            <ol className="mt-10 space-y-8">
              {steps.map((s, i) => (
                <li key={s.title} className="flex gap-5">
                  <span
                    aria-hidden
                    className="flex size-12 shrink-0 items-center justify-center rounded-full bg-royal font-display text-xl font-bold text-white"
                  >
                    {i + 1}
                  </span>
                  <div>
                    <h3 className="font-display text-2xl font-semibold">{s.title}</h3>
                    <p className="mt-1.5 text-lg leading-relaxed text-muted">{s.body}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
          <div className="relative flex justify-center gap-4 overflow-hidden rounded-[2rem] bg-mist px-6 pb-0 pt-10">
            <Phone screen="items" alt="Choosing items to iron, with a running total." className="w-[46%]" />
            <Phone screen="pickup" alt="Choosing a pickup window." className="w-[46%] translate-y-12" />
          </div>
        </div>
      </section>

      {/* Services */}
      <section id="services" className="bg-chrome">
        <div className="mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28">
          <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">What we do</h2>
          <p className="mt-4 max-w-2xl text-xl text-muted">Prices are shown in the app before you book, so there are no surprises.</p>
          <ul className="mt-12 grid gap-6 md:grid-cols-3">
            {services.map(({ icon: Icon, name, body }) => (
              <li key={name} className="rounded-3xl bg-white p-8 shadow-sm ring-1 ring-ring">
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

      {/* Tracking and offers */}
      <section className="mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28">
        <div className="grid items-center gap-14 lg:grid-cols-2">
          <div className="order-2 flex justify-center gap-4 lg:order-1">
            <Phone screen="tracking" alt="The order tracking screen showing each step from booking to delivery." className="w-[46%]" />
            <Phone screen="offers" alt="The offers screen with promo codes to copy." className="w-[46%] translate-y-10" />
          </div>
          <div className="order-1 lg:order-2">
            <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Know where your clothes are</h2>
            <ul className="mt-8 space-y-6">
              {[
                { icon: Bell, title: "An update at every step", body: "You get a notification when your clothes are picked up, being ironed, and on their way back." },
                { icon: PhoneIcon, title: "Your partner, one tap away", body: "See who is collecting or delivering and call them from the order screen." },
                { icon: Banknote, title: "Offers and promo codes", body: "Look in the Offers tab for current codes, and apply one in your basket." },
              ].map(({ icon: Icon, title, body }) => (
                <li key={title} className="flex gap-4">
                  <span className="flex size-12 shrink-0 items-center justify-center rounded-xl bg-mist text-royal">
                    <Icon aria-hidden className="size-6" />
                  </span>
                  <div>
                    <h3 className="font-display text-xl font-semibold">{title}</h3>
                    <p className="mt-1 text-lg leading-relaxed text-muted">{body}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* Service area */}
      <section className="bg-mist">
        <div className="mx-auto flex max-w-6xl flex-col items-start gap-6 px-4 py-16 sm:px-6 md:flex-row md:items-center md:gap-10">
          <span className="flex size-16 shrink-0 items-center justify-center rounded-2xl bg-white text-royal">
            <MapPin aria-hidden className="size-8" />
          </span>
          <div>
            <h2 className="font-display text-3xl font-bold">We pick up and deliver across {site.area}</h2>
            <p className="mt-2 max-w-3xl text-lg text-muted">
              The app checks your address when you add it. Live somewhere else? You can still create an account and save your address;
              booking opens in other cities as we expand.
            </p>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="mx-auto max-w-3xl px-4 py-20 sm:px-6 sm:py-28">
        <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Common questions</h2>
        <div className="mt-10 divide-y divide-ring rounded-3xl border border-ring">
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
        <p className="mt-6 text-lg text-muted">
          More in our{" "}
          <Link href="/cancellation" className="font-semibold text-royal underline-offset-4 hover:underline">
            cancellation and refund policy
          </Link>
          , or{" "}
          <Link href="/support" className="font-semibold text-royal underline-offset-4 hover:underline">
            ask us directly
          </Link>
          .
        </p>
      </section>

      {/* Download */}
      <section id="download" className="on-dark relative overflow-hidden bg-royal text-white">
        <Bubble className="-left-8 top-10 size-28" />
        <Bubble className="right-[12%] bottom-8 size-12" />
        <div className="relative mx-auto max-w-6xl px-4 py-20 text-center sm:px-6 sm:py-24">
          <h2 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Get IronDost</h2>
          <p className="mx-auto mt-4 max-w-xl text-xl text-white/85">
            Sign in with your mobile number. We send a one-time code by SMS, and you can book your first pickup in a minute.
          </p>
          <div className="mt-10 flex justify-center">
            <StoreButtons onDark />
          </div>
        </div>
      </section>
    </>
  );
}
