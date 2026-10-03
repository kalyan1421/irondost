import type { Metadata } from "next";
import { LegalDocument } from "@/components/legal-document";
import { legal } from "@/lib/legal";

export const metadata: Metadata = {
  title: legal.documents.terms.title,
  description: "The terms for using IronDost: services and prices, paying, and how we look after your clothes.",
  alternates: { canonical: "/terms" },
};

export default function Page() {
  return <LegalDocument slug="terms" />;
}
