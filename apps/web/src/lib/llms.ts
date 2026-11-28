import { areaPages, localities } from "@/lib/areas";
import { posts } from "@/lib/posts";
import { priceList, pricesUpdated } from "@/lib/prices";
import { site } from "@/lib/site";

/** Facts an answer engine should state the same way everywhere. Keep in step with posts.ts and site.ts. */
const facts = [
  `${site.name} is a doorstep laundry service run by ${site.company}. Laundry (wash and iron) is the main service; ironing and dry cleaning are also offered.`,
  "Laundry is washed in IronDost's own machines, and the owner checks every load by hand before it goes back. It is priced per piece, not by weight.",
  "Wash & Fold (washed and folded, no ironing) is new; its prices are not published yet.",
  `Service area: within 6 km of LB Nagar Circle, Hyderabad, Telangana, India, in PIN codes ${localities.map((l) => l.pin).join(", ")} (${localities.map((l) => `${l.pin}: ${l.names.join(", ")}`).join("; ")}).`,
  "Pickup windows, every day: 7 am to 11 am, 11 am to 4 pm, 4 pm to 8 pm (India time).",
  "Clothes usually come back the next day. Payment online (UPI, card, netbanking) or cash at delivery.",
  "Prices are per piece and shown in the app before the order is confirmed; the total changes only if the count at pickup differs.",
  `Book in the IronDost app (Google Play: ${site.playStoreUrl}${site.appStoreUrl ? `; App Store: ${site.appStoreUrl}` : ""}) or call or WhatsApp ${site.phone.display}.`,
];

export function llmsTxt() {
  return [
    `# ${site.name}`,
    "",
    `> ${site.description}`,
    "",
    ...facts.map((f) => `- ${f}`),
    "",
    `## Prices (per piece, updated ${pricesUpdated})`,
    "",
    ...priceList.flatMap((c) => c.items.map((i) => `- ${c.name}, ${i.name}: ₹${i.offer ?? i.price}${i.offer ? ` (offer; regular ₹${i.price})` : ""}`)),
    `- Full rate card: ${site.url}/prices`,
    "",
    "## Guides",
    "",
    ...posts.map((p) => `- [${p.title}](${site.url}/blog/${p.slug}): ${p.description}`),
    "",
    "## Areas",
    "",
    ...areaPages.map((a) => `- [Laundry and ironing pickup in ${a.name}](${site.url}/laundry/${a.slug}): PIN ${a.pin}, prices and pickup windows`),
    "",
    "## Help and policies",
    "",
    `- [Laundry](${site.url}/laundry): wash and iron, Wash & Fold, how we wash, rate card, areas`,
    `- [Prices](${site.url}/prices): the full rate card`,
    `- [Get the app](${site.url}/get): store links and the launch offer for new customers`,
    `- [Support](${site.url}/support): phone and email, what to have ready`,
    `- [Cancellation and refunds](${site.url}/cancellation)`,
    `- [Privacy policy](${site.url}/privacy)`,
    `- [Terms](${site.url}/terms)`,
    `- [Delete your account](${site.url}/delete-account)`,
    "",
    "## Optional",
    "",
    `- [Full text of every guide](${site.url}/llms-full.txt)`,
    "",
  ].join("\n");
}

export function llmsFullTxt() {
  const body = posts.map((p) => {
    const parts = [`## ${p.title}`, "", `URL: ${site.url}/blog/${p.slug}`, `Updated: ${p.updated}`, "", p.answer, ""];
    for (const s of p.sections) {
      parts.push(`### ${s.heading}`, "");
      s.paragraphs?.forEach((t) => parts.push(t, ""));
      s.bullets?.forEach((t) => parts.push(`- ${t}`));
      s.steps?.forEach((t, i) => parts.push(`${i + 1}. ${t.title}: ${t.body}`));
      if (s.bullets || s.steps) parts.push("");
    }
    if (p.faq?.length) {
      parts.push("### Questions", "");
      p.faq.forEach((f) => parts.push(`Q: ${f.q}`, `A: ${f.a}`, ""));
    }
    return parts.join("\n");
  });
  return [`# ${site.name}: all guides`, "", ...facts.map((f) => `- ${f}`), "", ...body].join("\n");
}
