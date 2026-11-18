# Launch plan

replica-launch step 4. Date 2026-11-07. This builds on the plans already in `docs/marketing/` (Dasara launch, November plans, creative pack) and does not repeat them. It adds what the competitor study changes.

## Where IronDost stands today (checked)

- **Android:** live on the public Play Store as "IronDost: Laundry & Ironing" (package `com.irondost.customer`, 10+ downloads, updated 3 Nov 2026).
- **iOS:** no App Store listing found in the India or US storefronts.
- **Backend and admin:** production API and admin on Render; the public catalogue endpoint answers.
- **Operations:** staff move every pickup and delivery from the admin; there is no rider app ([staff-delivery-runbook.md](../../docs/staff-delivery-runbook.md)).
- **Measurement:** the privacy answers say there is no analytics or crash-reporting SDK in the app, so the booking funnel the research doc wants (address, basket, checkout, payment, repeat) cannot be measured from the client today.

## Before any paid push (found in this pass)

1. **Confirm the live prices.** The production catalogue equals the repo's placeholder seed ([pricing.md](pricing.md) section 1).
2. **Confirm minimum order and delivery fee** in the admin; the defaults are ₹0 and competitors set ₹299 to ₹350.
3. **Make the service-area wording true.** The live listing says "Available in Hyderabad"; the service area is a radius or PIN list around LB Nagar.
4. **Do not ship the iOS subtitle "Pickup and delivery in a day".** It is a timing promise the product does not make.
5. **Decide how to measure.** Either privacy-friendly analytics plus crash reporting (update the privacy answers and the store data-safety form when added) or server-side counts from existing order and quote records.
6. **Keep the support phone and email current** (`business_settings`) and decide who answers and by when. Unanswered support is the largest complaint theme at the competitors (18% of the sampled reviews).

## Waitlist and the first orders

- Keep the controlled pilot the product-marketing doc describes: the first 10 to 20 orders in LB Nagar are the baseline for on-time pickup and delivery, repeat rate and complaint rate.
- Use the WhatsApp fallback for anyone who cannot or will not use the app; this is also where the planned click-to-chat link (architecture step 1) pays off.
- Talk to the first 10 customers by hand, ideally apartment champions, and ask what they paid elsewhere and what went wrong last time.

## Where the other apps' unhappy customers are

**Not researched in this pass.** I collected public store and map reviews, not forum threads, and I will not guess at communities. Reasonable next steps, for you to choose: search public Hyderabad neighbourhood groups and apartment-community pages for "ironing" and "laundry pickup" threads, read them as a person would, and note what people ask for. The review sample itself ([feedback.md](../feedback.md)) shows the kinds of problems to listen for: late pickups, support that goes quiet, damaged or missing items, bills that differ from the quote.

## Message

Lead with the angle in [fixes.md](../fixes.md): **see the price before we pick up**, shown with a real basket screenshot. Add the support and window promises only after the pilot shows they hold. Never name a competitor, never use their reviews as testimonials, never ask for or buy reviews.

## Store listing

- `listing.py` result: 0 errors, 2 warnings (empty promotional text; keywords repeating words already in the name and subtitle). Competitor names are absent.
- Apple Guideline 4.1 (Copycats): IronDost is an original design (layout similarity to the one competitor with raw screens: 2 to 27 out of 100; its own palette ΔE 43 or more away from every competitor's primary). Make the differences visible in the first screenshots: itemised basket with price, separate pickup and return windows. The existing store screenshots already show catalogue, basket, schedule and checkout.
- Refresh screenshots and copy only when the app and the service area match what they promise ([store-submission-assets.md](../../docs/store-submission-assets.md)).

## What to watch in week one

Quote-to-order rate, orders per active address, on-time pickup and delivery (needs a timestamp comparison in the admin data), payment failures and recoveries, support contacts per order, repeat orders within 14 days, and every review that mentions price, lateness or support. Read each new store review the day it arrives and answer personally.
