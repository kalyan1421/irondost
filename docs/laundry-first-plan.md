# IronDost: laundry as the main service

Status: **Phase 1 app work built (20 November 2026), not committed.** Admin data, store listing text and all marketing items are still to do.

## Decisions taken (asked and answered)

| Question | Answer |
|---|---|
| How laundry is sold | **Per piece only.** No per-kg pricing |
| Prices | Proposed from public competitor rates (below); the owner sets the final numbers in admin |
| Who washes | **IronDost's own machines**, with the **owner checking quality** before anything goes back |
| Marketing channels | Instagram and reels; website and SEO; Google Business Profile and the two store listings |

## Positioning

**One line:** Doorstep laundry around LB Nagar, washed in our own machines, checked by hand, priced per piece before we pick up.

- Laundry leads. Ironing and dry cleaning stay, as "also".
- The brand name stays **IronDost**. The tagline already used on the logo, "Wash, iron, deliver", carries the shift.
- Keep the existing rules: price shown before pickup, only the count can change the bill, no competitor names, no "cheapest".

## Price check (public pages, 20 November 2026)

Per-piece wash and iron for a shirt in Hyderabad:

| Provider | Shirt, wash and iron | Source |
|---|---|---|
| LaundryGo | from ₹35 | [laundrygo.in/pricing](https://www.laundrygo.in/pricing.html) |
| ZapWash | ₹40 (48 h) | [thezapwash.com](https://thezapwash.com/laundry-pricing-hyderabad.html) |
| Laundrology | ₹45 | [laundrology.in/pricing](https://www.laundrology.in/pricing) |
| Tumbledry | about ₹50 | [tumbledry.in Hyderabad](https://tumbledry.in/dry-cleaning-prices-in-hyderabad/) |
| UClean | per kg only (₹89/kg onwards), steam press ₹9/piece | [uclean.in](https://uclean.in/build-your-order?lat=22.79286690&lng=86.18263300) |

These are vendor pages with "from" prices, not a survey, and some may be out of date. IronDost's live **₹35** wash-and-iron shirt sits at the bottom of the ₹35–₹50 range, so laundry can be sold on value without discounting.

**Proposed laundry rate card (owner to confirm):**

| Item | Wash & Iron (live today) | Wash & Fold (new, proposed) |
|---|---|---|
| Shirt / T-shirt | ₹35 | ₹25 |
| Trousers / Jeans | ₹40 | ₹30 |
| Kurta | ₹40 (proposed) | ₹30 |
| Towel | — | ₹20 |
| Bedsheet, single | ₹50 (proposed) | ₹40 |
| Bedsheet, double | ₹70 | ₹55 |

Wash & Fold numbers are my assumption: few local shops publish per-piece Wash & Fold prices. Set them from your washing cost per load.

## Product plan (customer app, admin, API)

### Phase 1: laundry first, no new backend (about 1 week)

| # | Feature | Where | Logic |
|---|---|---|---|
| P1 | **Laundry category first.** One "Laundry" category holding Wash & Iron and Wash & Fold items, sort order 0 | Admin data | Done in admin; no code. Rename "Wash & Iron" to "Laundry" or add a Wash & Fold category next to it |
| P2 | **Home leads with laundry.** Laundry tile becomes the big first tile, the offer banner shows the laundry price ("Shirt washed & ironed ₹35"), Popular prices shows laundry items first | `home_screen.dart` | Tiles and prices read the live catalogue, matched by the laundry slug |
| P3 | **Book a pickup opens Laundry by default.** Search pill and doorstep banner land on the Laundry tab | `booking_entry.dart`, `catalogue_screen.dart` | Default `service` = the laundry category's slug when none is given |
| P4 | **Laundry care choices.** Chips at checkout: "Wash whites separately", "No fabric softener", "Fold" or "On hangers", "Gentle wash" | `checkout/care_note*.dart` | Reuse the existing care note text; chips only prefill it, so the API is unchanged |
| P5 | **First-laundry offer.** A promo code for the first laundry order | Admin promotions | Existing promotions; the Home banner already shows the running offer |
| P6 | **Welcome and store copy.** Welcome screen line, store title and short description, screenshots lead with laundry | `welcome_screen.dart`, `store/` | Copy and images only |

### Phase 2: own-machine operations and quality check (about 2 weeks)

| # | Feature | Where | Logic |
|---|---|---|---|
| P7 | **Owner quality check step.** A "Checked by hand" step before delivery, with who checked and when | API order events, admin order screen, app order timeline | New event `QUALITY_CHECKED` recorded from admin; the timeline shows it between cleaning and out for delivery. Delivery dispatch waits for it |
| P8 | **Turnaround per service.** Laundry 48 h, ironing 24 h | API catalogue category field, schedule logic | `turnaroundHours` on a category; the earliest delivery slot is driven by the slowest service in the basket |
| P9 | **Laundry status updates.** "Washing", "Drying", "Ironed and checked" pushes | API push, app notifications | Driven by the processing sub-steps the staff app or admin records |
| P10 | **Machine and batch log (admin only).** Which machine and wash load an order went into, for tracing a quality issue | Admin, API | A small `WashBatch` table linked to orders; not shown to customers |

### Not doing now

- Per-kg pricing (decided against).
- Express laundry. Add it only after the 48-hour promise holds every day for a month.

## Marketing plan

### Website and SEO

| # | Change | Files |
|---|---|---|
| M1 | Home hero becomes laundry-first: "Laundry picked up from your door, priced per piece" | `apps/web/src/app/page.tsx` |
| M2 | New **/laundry** service page: what Wash & Iron and Wash & Fold cover, the rate card, how we wash (own machines, owner check), areas served, FAQ | new `apps/web/src/app/laundry/` |
| M3 | Prices page lists Laundry first | `apps/web/src/app/prices/` |
| M4 | `llms.txt` / `llms-full.txt` and the Service structured data lead with laundry | `apps/web/src/app/llms*.txt`, layout schema |
| M5 | Three blog posts: "How to pack your laundry bag for pickup", "Wash & iron or dry clean: which does this fabric need?", "Monsoon laundry: why clothes won't dry, and what we do" | `apps/web/src/app/blog/` |

**Search targets:** "laundry service LB Nagar", "laundry pickup near me Dilsukhnagar", "wash and iron price Hyderabad", "laundry service Vanasthalipuram".

### Google Business Profile

- Primary category **Laundry service**; keep Ironing service and Dry cleaner as secondary categories.
- Services list: Wash & Iron and Wash & Fold first, with the confirmed prices.
- Photos: the machines, folding, the owner's check, bags at the door. Real photos only.
- One weekly post for 4 weeks: rate card, how we wash, the quality check, a first-laundry offer.

### Instagram and reels (4-week laundry push)

| Week | Reel | Carousel | Story |
|---|---|---|---|
| 1 | "From your bag to our machine": real footage of a load going in | Laundry rate card, per piece | Poll: fold or hangers? |
| 2 | Owner's quality check, hands only | "What Wash & Fold covers" | Q&A: what can't go in the machine |
| 3 | Folding timelapse | Wash & iron or dry clean: fabric guide | Offer countdown |
| 4 | Doorstep handover, no faces | "How to pack your laundry bag" | Repost customer replies (with permission) |

Every post keeps the house rules: logo, both phone numbers (79934 34932 and 70329 90632), the two store QR codes, and the newest app screens.

### Store listings

- **Title:** "IronDost: Laundry & Ironing Pickup"
- **Short description:** "Doorstep laundry around LB Nagar. Wash, iron and deliver, priced per piece."
- **Screenshots:** first screen is the new Home with Laundry leading; second is the laundry price list; third is order tracking with the quality-check step (after P7).

## What to measure

| Measure | Why |
|---|---|
| Share of orders with a laundry item | Did laundry actually become the main service |
| Laundry pieces per order | Basket size moves with laundry |
| Repeat laundry order within 14 days | The growth plan's main repeat signal |
| Quality issues reported per 100 laundry orders | Keeps the own-machine plus owner-check promise honest |
| Orders back within the 48-hour promise | The turnaround claim must hold before it is advertised |

## What the owner needs to give

1. Final per-piece prices for Wash & Iron and Wash & Fold.
2. Real turnaround the machines can hold every day (the plan assumes 48 hours).
3. Photos and short clips: machines, a load, folding, the quality check, a handover.
4. Whether "Wash & Iron" is renamed to "Laundry" or Wash & Fold is added as its own category.

## Phase 1 progress (20 November 2026)

| # | Item | State |
|---|---|---|
| P1 | Laundry category first in the price list | **Owner, in admin:** set the Laundry (or Wash & Iron) category's sort order to 0, and add Wash & Fold items |
| P2 | Home leads with laundry | **Built.** Laundry is the big first tile ("₹35 a piece", Offers or "Own machines" chip); the offer banner shows the laundry shirt price "washed & ironed"; Popular prices picks laundry items first and labels each price with its service; the doorstep banner reads "Doorstep laundry" |
| P3 | Booking opens on Laundry | **Built.** "Book a pickup" with no service named opens the Laundry tab (`laundrySlugProvider`) |
| P4 | Laundry care choices | **Built.** Washing baskets now offer "Wash whites separately", "No fabric softener" and "Gentle wash" next to the existing prompts; a category named Laundry gets them too |
| P5 | First-laundry offer | **Owner, in admin:** create the promo code; Home shows it in the banner automatically |
| P6 | Welcome and store copy | **Welcome screen built** ("Laundry washed in our own machines, plus ironing and dry cleaning."). Store title, short description and screenshots are set in Play Console and App Store Connect: text is in the Store listings section above |

Code notes: `lib/features/catalogue/laundry.dart` holds the rules. "Laundry" contains the letters "dry", so dry cleaning is now matched by the word, not the letters (`mentionsDryCleaning`), in the care prompts, the price-list artwork and the service pictures. Tests: `test/features/laundry_test.dart`, care-note tests updated. 692 tests pass.

## Phase 2 progress (20 November 2026)

| # | Item | State |
|---|---|---|
| P7 | Owner quality check step | **Built, without a database change.** Moving an order from the workshop to "ready for delivery" *is* the hand check: the admin button now reads **"Checked by hand · ready"**, the customer's push says "Checked and ready: order N has been checked by hand", the order status reads "Checked and ready", and the timeline's third step (now **Cleaning**, not Ironing) shows "Checked by hand · ready for delivery", then "Checked by hand" with the time |
| P8 | Turnaround per service | **Not built, on purpose.** It needs a new column on catalogue categories (a migration on the production database, which is already behind one uncommitted migration) and a change to how the app asks for delivery windows. Until then, set the global minimum turnaround in admin to the laundry time (48 h) if ironing-only orders can wait as long |
| P9 | Laundry status updates | **Built (copy).** "Being cleaned: order N is at our workshop: washing, ironing or dry cleaning" replaces "Being ironed"; the ready push is above. Separate washing / drying pushes need the staff to record those sub-steps, which is part of P10 |
| P10 | Machine and batch log | **Not built.** Needs a new table and a migration; do it together with P8 in one reviewed migration |

The owner's rule this depends on: **only mark an order ready after checking every piece by hand** (count, stains, folding). The app now tells customers that is what happened.

Checks: customer app 692 tests pass, API typecheck, lint and 311 tests pass, admin typecheck and lint pass.
