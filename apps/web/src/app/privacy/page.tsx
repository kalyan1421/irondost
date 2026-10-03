import type { Metadata } from "next";
import { LegalDocument } from "@/components/legal-document";
import { legal } from "@/lib/legal";

export const metadata: Metadata = {
  title: legal.documents.privacy.title,
  description: "What IronDost collects, why, who else handles it, and how to have your data deleted.",
  alternates: { canonical: "/privacy" },
};

export default function Page() {
  return <LegalDocument slug="privacy" />;
}
