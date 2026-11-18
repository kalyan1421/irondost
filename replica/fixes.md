# What customers of the big laundry apps complain about, and what to fix

replica-entrepreneur output. Date 2026-11-07. Data: [reviews.csv](reviews.csv) (238 reviews from the three Hyderabad-relevant apps), analysed in [feedback.md](feedback.md).

## How much to trust this (read first)

- **Sample:** 220 reviews analysed, from Google Play, the App Store, Trustpilot and Google Maps, for DhobiLite, Tumbledry and Fabrico. Dates run from 2022 to 6 Nov 2026, mostly 2025 and 2026.
- **It is skewed on purpose.** The collectors took 1, 2 and 3 star reviews first, so 109 of 238 are one-star and only 2 are four-star. Real averages are higher (DhobiLite 4.9 on Play from 15K reviews, Tumbledry 4.3 from 11.7K, Fabrico 3.5 on Play). **The table shows what kinds of things go wrong, not how often they go wrong.**
- **Cleaning done:** 12 one- and two-star reviews with plainly positive text ("nice", "bahut badhiya app hai") were excluded as star/text contradictions (list in `reviews.excluded-contradictory.csv`); 7 reviews on DhobiLite's own website were excluded as brand-curated; 6 duplicates were removed.
- **Counts are keyword matches.** A spot check of 6 matches per theme found roughly 80% relevant for support, delays and damage, and about 60 to 65% for cleaning quality and billing. Treat the order as indicative, the shares as upper bounds. Reviews written in Roman Hindi are only partly caught.
- **Independent checks of the collectors' text:** all 3 Fabrico Play reviews on a cached page, 2 of 2 testable DhobiLite Play reviews, and 10 of 10 Tumbledry App Store reviews matched the live pages word for word. Tumbledry's Play and Trustpilot rows could not be re-checked (Trustpilot blocked automated access; Play sample did not overlap).
- **None of these are IronDost testimonials.** They are research. Do not quote them in marketing.

## 1. What they hate (ranked)

| # | Problem | Reviews (of 220) | Sources | Avg stars |
|---|---|---|---|---|
| 1 | Support that does not answer | 40 (18%) | 7 | 1.3 |
| 2 | Late or missed pickup and delivery | 21 (10%) | 7 | 1.3 |
| 3 | Damaged, lost or swapped garments | 20 (9%) | 6 | 1.2 |
| 4 | Poor cleaning or ironing quality | 19 (9%) | 6 | 1.9 |
| 5 | App bugs (OTP, address, slots, crashes) | 14 (6%) | 5 | 1.4 |
| 6 | No status updates or wrong tracking | 13 (6%) | 6 | 1.9 |
| 7 | Price at billing differs from the quote | 12 (6%) | 6 | 2.1 |
| 8 | Refunds and money not returned | 11 (5%) | 6 | 1.4 |
| 9 | Too expensive | 8 (4%) | 5 | 1.9 |
| 10 | Promo or offer did not apply | 7 (3%) | 5 | 1.4 |
| 11 | Rude staff or riders | 7 (3%) | 4 | 1.3 |
| 12 | Rescheduled by the company without notice | 3 (1%) | 3 | 1.0 (thin) |
| 13 | Not serviceable, found out after sign-up | 1 (0%) | 1 | 2.0 (thin) |

Linked examples, all checked word for word against the live page:
- Support: "It took 5-6 attempts to get through to someone" ([Tumbledry, App Store, Dec 2024](https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539?see-all=reviews)).
- Quoted price vs billed price: "delivery person gives a different price store manager says something else" ([Tumbledry, App Store, Sep 2022](https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539?see-all=reviews)).
- Damage: "the gents suits( 3 set in total) were all in bad state" ([Tumbledry, App Store, Feb 2024](https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539?see-all=reviews)).

The recent one-star reviews at the biggest Hyderabad-relevant apps also describe 5 to 8 day delays, lost items and support reachable only through a bot (DhobiLite agent notes; see [competitors/dhobilite/reviews.csv](competitors/dhobilite/reviews.csv)).

## 2. What is missing (explicit requests, few)

The review tool's request patterns mostly matched false positives, so this list is from reading, and it is short:

- **Item picker and bill amount before booking** (a DhobiLite Play reviewer; see [competitors/dhobilite/teardown.md](competitors/dhobilite/teardown.md) section C). Three of the five apps do not show price at booking.
- **Find a nearby store when door pickup is not available** (Tumbledry Play, 2 stars).
- **A visible wallet balance and the status of a raised query** (Tumbledry Play, April 2026).
- **A contact number** (Fabrico, Google Maps).

Thin: four items from a sample this size is not a trend.

## 3. What is unsolved (jobs nobody does well)

- **Ironing as the main job.** At Fabrico steam press is a side column and premium press is extra; at Tumbledry the strength is dry cleaning; at DhobiLite ironing is priced per piece at Rs 50 for a shirt in Bandlaguda against about Rs 20 at Fabrico's Dilsukh Nagar store (Fabrico figure agent-observed, not re-checked). A cheap, clear, ironing-first menu with no high minimum is open ground. (Evidence: price tables in the three teardowns; minimums Rs 299 to 350.)
- **A pickup time that holds.** Late or missed pickups and company-initiated rescheduling together appear in at most 24 of 220 sampled reviews (the themes overlap, so this is an upper bound). Competitors shrink windows to 1 or 2 hours in the UI, but reviews say the windows are not honoured. This is an operations problem first; a UI window alone will not solve it.
- **Telugu.** One of five apps shows a language switch; none showed Telugu. Thin evidence, but Hyderabad-specific.

## 4. Fix plan (top 8, evidence times cost)

| # | What to build or change | Size | Skill | Evidence |
|---|---|---|---|---|
| 1 | Order-linked problem report with status, response clock and admin queue | M | backend, build | Support 40 reviews, 7 sources |
| 2 | Customer approval before any price change after pickup | M | backend, build | Billing 12 reviews; three apps show no price at booking |
| 3 | Express and priority option with the surcharge shown beside it | M | backend, build | All five apps; "late" 21 reviews |
| 4 | Narrower, configurable pickup windows and in-app reschedule | M | backend, build | Windows of 1 to 2.5 h at four apps; rescheduling reviews |
| 5 | WhatsApp one-tap support (then order updates through the official API) | S, then M | build, backend | Three apps; support 40 reviews |
| 6 | Damage claim record and pickup condition photos | M to L | backend, build | Damage 20 reviews; needs a partner flow |
| 7 | **Rider client before volume.** The API for it already exists (driver routes: online, location, offers, tasks, picked-up, delivered); only the client is missing. The owner chose a Flutter app | L | build | Late and missed pickups; today staff run every leg from the admin |
| 8 | Public price list and a few real neighbourhood pages | S to M | launch | Fabrico and DhobiLite do it; Tumbledry hides item prices |

Items 1 to 6 are rows in `features.csv` (they are not new rows because competitors show them). Item 7 is a prerequisite, not a feature, and it is the biggest risk to everything above (see [architecture.md](architecture.md)). Pricing and billing complaints are handled in [launch/pricing.md](launch/pricing.md).

## 5. The angle (three options, one recommendation)

**A. Price before pickup.** *For households around LB Nagar who are tired of finding out the price after their clothes have gone, IronDost shows what each item costs and the total before the rider is booked.* Evidence: price-at-billing complaints (12 reviews, 6 sources) and no price shown at booking in DhobiLite and Fabrico (observed) and Tumbledry (inferred). **Provable today** with the server quote, itemised basket and bill.

**B. A pickup window that holds.** *For people who cannot stay home all day, IronDost picks up inside a window you choose.* Evidence: late and missed pickups (21 reviews). **Not provable yet:** IronDost's windows are 4 to 5 hours, and there is no partner app to hold riders to them.

**C. Someone answers.** *For customers who got no reply elsewhere.* Evidence: support complaints (40 reviews). **Risky:** it is a promise that operations must keep from day one, and one unanswered ticket turns it into a headline.

**Recommended: A.** It is the only one the product can demonstrate in a screenshot today. Build the support and window fixes (items 1 to 4) first, prove them in the pilot, then add B and C to the story. Do not use the original apps' names in IronDost's name, ads or store listing; a comparison page is a legal question for a lawyer.
