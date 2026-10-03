import { Mail, Phone } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Support",
  description: `Call or email IronDost about an order, a payment or your account. ${site.phone.display}.`,
  alternates: { canonical: "/support" },
};

export default function SupportPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
      <h1 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Support</h1>
      <p className="mt-4 text-xl text-muted">Something wrong with an order, a payment or your account? Talk to us.</p>

      <ul className="mt-10 grid gap-5 sm:grid-cols-2">
        <li>
          <a
            href={`tel:${site.phone.tel}`}
            className="flex h-full flex-col gap-3 rounded-3xl bg-mist p-7 hover:ring-2 hover:ring-royal"
          >
            <span className="flex size-12 items-center justify-center rounded-xl bg-white text-royal">
              <Phone aria-hidden className="size-6" />
            </span>
            <span className="font-display text-2xl font-semibold">Call us</span>
            <span className="text-xl font-semibold text-royal">{site.phone.display}</span>
          </a>
        </li>
        <li>
          <a
            href={`mailto:${site.email}?subject=${encodeURIComponent("IronDost support")}`}
            className="flex h-full flex-col gap-3 rounded-3xl bg-mist p-7 hover:ring-2 hover:ring-royal"
          >
            <span className="flex size-12 items-center justify-center rounded-xl bg-white text-royal">
              <Mail aria-hidden className="size-6" />
            </span>
            <span className="font-display text-2xl font-semibold">Email us</span>
            <span className="break-all text-xl font-semibold text-royal">{site.email}</span>
          </a>
        </li>
      </ul>

      <section className="mt-14">
        <h2 className="font-display text-2xl font-semibold">So we can help faster</h2>
        <ul className="mt-4 list-disc space-y-2 pl-6 text-lg leading-relaxed marker:text-royal">
          <li>Tell us your order number. It starts with ID and is at the top of the order screen in the app.</li>
          <li>Say the mobile number you sign in with.</li>
          <li>For a damaged or missing item, tell us within 48 hours of delivery.</li>
        </ul>
      </section>

      <section className="mt-14 rounded-3xl border border-ring p-7">
        <h2 className="font-display text-2xl font-semibold">Looking for something else?</h2>
        <ul className="mt-4 space-y-3 text-lg">
          <li>
            <Link href="/#faq" className="font-semibold text-royal underline-offset-4 hover:underline">
              Common questions
            </Link>
          </li>
          <li>
            <Link href="/cancellation" className="font-semibold text-royal underline-offset-4 hover:underline">
              Cancellation and refunds
            </Link>
          </li>
          <li>
            <Link href="/delete-account" className="font-semibold text-royal underline-offset-4 hover:underline">
              Delete your account
            </Link>
          </li>
        </ul>
      </section>
    </div>
  );
}
