# IronDost: blog and search plan

Mode: **PLAN**. Written 18 November 2026. This is a content plan for search engines, Google Maps and AI answer tools, not finished articles. I did not check live search results for each query, so the ranking difficulty of every topic is unverified; the topics come from what customers ask (see the product-marketing file and the competitor review study).

## Where it would live

The public site is `apps/web` (home, cancellation and delete-account pages; hosted at irondost-app.web.app as far as the repository shows). It has no blog route yet. Two options: add `/blog` and `/areas/<locality>` routes to `apps/web`, or start with Google Business Profile posts, which need no build. **Start with the profile posts and one pricing page; add the blog when there is a custom domain.** A blog on a `web.app` address builds little lasting value.

## Who searches, and for what

| Searcher | What they type | What they want next |
| --- | --- | --- |
| Working household | "ironing service near me", "laundry pickup LB Nagar" | A price and a number to message |
| PG resident | "ironing for PG Dilsukhnagar", "laundry near Chaitanyapuri" | Small-order price, pickup timing |
| Occasion buyer | "saree dry cleaning LB Nagar", "suit dry clean price Hyderabad" | Price, how stains are handled |
| Comparer | "ironing price per shirt Hyderabad" | A straight rate card |

## Pages and posts, in order

| # | Type | Working title | Main question it answers | Proof it uses |
| --- | --- | --- | --- | --- |
| 1 | Page | IronDost rate card: ironing, wash and iron, dry cleaning in LB Nagar | "How much does ironing cost near LB Nagar?" | The live rate card, dated |
| 2 | Page | Areas we serve around LB Nagar | "Do you pick up in my area?" | The 12 localities and 7 PIN codes |
| 3 | Article | How doorstep ironing pickup works, step by step | "What happens after I book?" | App screens, the three pickup windows |
| 4 | Article | What to tell a dry cleaner before handing over a silk saree | "How do I get a silk saree cleaned safely?" | The four points in `carousel-saree-care`; honest stain line |
| 5 | Article | Ironing for PG and hostel residents in Dilsukhnagar: what it costs | "Where can I get shirts ironed near my PG?" | 5 shirts ₹75 on the offer price |
| 6 | Article | Will the laundry bill change after pickup? What to check before you book | "Why was my laundry bill more than the quote?" | IronDost's rule: only the count can change the amount |
| 7 | Area pages (later) | Ironing and laundry pickup in Vanasthalipuram / Nagole / Saroornagar … | Local intent per locality | Only write one when there is a real detail for that area (a building served, a pickup day). Twelve copies of one page help nobody |

## Outline for page 1 (the rate card), ready to write

- **Title tag:** Ironing and laundry prices in LB Nagar, Hyderabad | IronDost
- **Meta description:** Shirt ironing ₹15, saree ₹50, wash and iron from ₹35, suit dry cleaning ₹350. See the full IronDost rate card and book a doorstep pickup around LB Nagar.
- **URL:** `/prices`
- **H1:** IronDost prices: ironing, wash and iron, and dry cleaning
- **Opening (first 100 words):** state the three headline prices, the area, and that the total is shown before confirming. No scene-setting.
- **H2 Ironing prices per piece** — table from the live catalogue.
- **H2 Wash and iron prices** — table.
- **H2 Dry cleaning prices** — table, with "We will try to remove stains but cannot promise it."
- **H2 Is there a minimum order or a pickup charge?** — answer in one sentence with whatever is live on the day of publishing. Today: no minimum and no pickup charge. When the ₹30-under-₹200 travel charge goes live, update this the same day.
- **H2 Will the price change after pickup?** — "Only if the number of clothes counted at pickup differs from what you entered."
- **H2 Which areas do you serve?** — the 12 localities, link to page 2.
- **H2 How do I book?** — app links, call or WhatsApp 79934 34932 (second number 70329 90632).
- **Last updated** date at the top, and update it whenever a price changes.
- **Schema:** LocalBusiness as a service-area business (no street address shown unless you have a walk-in counter), with `areaServed` listing the localities and `telephone`. FAQPage only if the questions above are visible on the page. No rich result is guaranteed.
- **Images:** the rate-card carousel slides, with alt text that states the prices ("IronDost ironing prices: shirt ₹15, trousers ₹15, kurta ₹20, saree ₹50").

## Google Business Profile (do this first)

- Category: laundry service; add dry cleaner and ironing-related services as service items with prices.
- Service-area business; list the 12 localities.
- Phone 79934 34932, hours that match when someone actually answers.
- 5 real photos to start (the filmed clips' stills), then one post a week using the pack's posters.
- Ask delivered customers for an honest review, with no reward. Reply to every review.

## Rules for every piece

- One page, one job. The price page sells nothing but clarity.
- Every price carries a date. Wrong prices on a page are worse than no page.
- No competitor names, no "best" or "cheapest", no invented customer stories or numbers.
- Answers first: each section opens with a sentence that still makes sense when quoted alone.
- Mark anything from a competitor's site as their claim, and prefer not to cite them at all.

## What I could not verify

- Search volume and current results for any query here.
- Whether a custom domain exists or is planned.
- Whether a Google Business Profile already exists.
