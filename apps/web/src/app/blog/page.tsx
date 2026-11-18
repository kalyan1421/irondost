import type { Metadata } from "next";
import { GuideCards } from "@/components/guide-cards";

export const metadata: Metadata = {
  title: "Guides",
  description:
    "Plain answers about doorstep ironing, laundry and dry cleaning around LB Nagar, Hyderabad: how pickup works, areas we serve, saree care and billing.",
  alternates: { canonical: "/blog" },
};

export default function BlogIndex() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-14 sm:px-6 sm:py-20">
      <h1 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">Guides</h1>
      <p className="mt-4 text-xl text-muted">Straight answers to what people ask before they hand over their clothes.</p>

      <div className="mt-10">
        <GuideCards headingLevel="h2" />
      </div>
    </div>
  );
}
