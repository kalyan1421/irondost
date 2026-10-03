import data from "@laundry/legal/legal.json";

export type LegalSection = { heading: string; paragraphs?: string[]; bullets?: string[] };
export type LegalDocument = { menuLabel: string; title: string; sections: LegalSection[] };
export type LegalSlug = "terms" | "privacy" | "cancellation";

export const legal = {
  company: data.company,
  updated: data.updated,
  byline: `IronDost is run by ${data.company}. Last updated ${data.updated}.`,
  documents: data.documents as Record<LegalSlug, LegalDocument>,
};

export const legalPages: { slug: LegalSlug; label: string }[] = [
  { slug: "terms", label: "Terms of service" },
  { slug: "privacy", label: "Privacy policy" },
  { slug: "cancellation", label: "Cancellation and refunds" },
];
