import type { Metadata } from "next";
import Link from "next/link";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Delete your account",
  description: "How to delete your IronDost account and personal data, in the app or by asking us.",
  alternates: { canonical: "/delete-account" },
};

const deleted = [
  "Your name, mobile number and email address",
  "Your saved addresses",
  "Your notifications and the token we use to send them to your phone",
];

export default function DeleteAccountPage() {
  const subject = encodeURIComponent("Delete my IronDost account");
  const body = encodeURIComponent("Please delete my IronDost account.\n\nMobile number I sign in with: ");
  return (
    <div className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
      <h1 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Delete your IronDost account</h1>
      <p className="mt-4 text-xl text-muted">
        You can delete your account and personal details at any time. It cannot be undone.
      </p>

      <section className="mt-12" aria-labelledby="in-app">
        <h2 id="in-app" className="font-display text-2xl font-semibold">
          In the app (fastest)
        </h2>
        <ol className="mt-4 list-decimal space-y-2 pl-6 text-lg leading-relaxed marker:font-semibold marker:text-royal">
          <li>Open IronDost and go to the Account tab.</li>
          <li>Tap Delete account.</li>
          <li>Read the message and tap Delete account again to confirm.</li>
        </ol>
        <p className="mt-4 text-lg leading-relaxed">
          If you have an order in progress, the app asks you to wait until it is delivered or cancelled. Then you can delete your account.
        </p>
      </section>

      <section className="mt-12" aria-labelledby="by-request">
        <h2 id="by-request" className="font-display text-2xl font-semibold">
          Can&apos;t open the app? Ask us
        </h2>
        <p className="mt-4 text-lg leading-relaxed">
          Email us from the address on your account, or call us, and say the mobile number you sign in with. We will check it is you,
          usually with a call to that number, and then delete the account.
        </p>
        <div className="mt-6 flex flex-wrap gap-4">
          <a
            href={`mailto:${site.email}?subject=${subject}&body=${body}`}
            className="rounded-xl bg-royal px-6 py-3.5 text-lg font-semibold text-white hover:bg-royal-dark"
          >
            Email a deletion request
          </a>
          <a href={`tel:${site.phone.tel}`} className="rounded-xl border border-ring px-6 py-3.5 text-lg font-semibold hover:bg-mist">
            Call {site.phone.display}
          </a>
        </div>
      </section>

      <section className="mt-12 grid gap-6 md:grid-cols-2" aria-label="What happens to your data">
        <div className="rounded-3xl bg-mist p-7">
          <h2 className="font-display text-xl font-semibold">What we delete</h2>
          <ul className="mt-4 list-disc space-y-2 pl-5 text-lg marker:text-royal">
            {deleted.map((d) => (
              <li key={d}>{d}</li>
            ))}
          </ul>
          <p className="mt-4 text-lg">You are signed out on every device.</p>
        </div>
        <div className="rounded-3xl border border-ring p-7">
          <h2 className="font-display text-xl font-semibold">What we keep</h2>
          <p className="mt-4 text-lg leading-relaxed">
            Your past orders (what was ordered, the amounts and the dates) stay in our business records without your name, number or
            address, because we need them for accounts and tax. Payment details are held by Razorpay under its own policy, not by us.
          </p>
        </div>
      </section>

      <p className="mt-12 text-lg text-muted">
        More about what we collect is in our{" "}
        <Link href="/privacy" className="font-semibold text-royal underline-offset-4 hover:underline">
          privacy policy
        </Link>
        .
      </p>
    </div>
  );
}
