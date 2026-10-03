import type { Metadata } from "next";
import { LegalDocument } from "@/components/legal-document";
import { legal } from "@/lib/legal";

export const metadata: Metadata = {
  title: legal.documents.cancellation.title,
  description: "When you can cancel an IronDost order, and how refunds work.",
  alternates: { canonical: "/cancellation" },
};

export default function Page() {
  return <LegalDocument slug="cancellation" />;
}
