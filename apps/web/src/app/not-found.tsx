import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = { title: "Page not found" };

export default function NotFound() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-28 text-center sm:px-6">
      <p className="font-display text-7xl font-bold text-royal">404</p>
      <h1 className="mt-4 font-display text-3xl font-bold">We couldn&apos;t find that page</h1>
      <p className="mt-3 text-lg text-muted">It may have moved. Start from the home page, or get in touch and we&apos;ll help.</p>
      <div className="mt-8 flex flex-wrap justify-center gap-4">
        <Link href="/" className="rounded-xl bg-royal px-6 py-3 font-semibold text-white hover:bg-royal-dark">
          Go to the home page
        </Link>
        <Link href="/support" className="rounded-xl border border-ring px-6 py-3 font-semibold hover:bg-mist">
          Contact support
        </Link>
      </div>
    </div>
  );
}
