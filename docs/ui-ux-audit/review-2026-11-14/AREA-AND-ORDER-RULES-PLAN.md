# LB Nagar 6 km service area, ₹200 order rule, care notes and insights

Decided with the owner on 15 November 2026. This builds on what already exists: a service area (centre point, radius, PIN allow-list) set from admin settings, a delivery fee with a free-above threshold, and a pickup note at checkout. [FEATURES-PLAN.md](FEATURES-PLAN.md) still covers the other chosen features.

## Decisions

| Topic | Decision |
|---|---|
| Service area | Centre on **LB Nagar Circle**; **6 km straight line** plus an **allowed PIN-code list** (the line decides, the PIN list settles border streets). |
| Outside the area | **Cannot book**, but the app lets them save the address and ask to be told when we arrive, using their **signed-in phone number** (with their yes). Staff see demand by area. |
| Small orders | **Flat ₹30 travel charge** when items total **under ₹200** (counted **before any coupon**); free from ₹200. Not a block. |
| Count at pickup | The charge is **re-checked on the counted items**: reaching ₹200 removes it, falling under adds it. Any net increase still needs the customer's approval. |
| Cancelling | Charge **refunded unless the partner already travelled**. Without a partner app, staff record "trip wasted" when cancelling to keep it. |
| Phone orders | Staff **must give a map pin or served PIN**. An address outside the area needs a **typed reason** and is logged. |
| Capacity | **8 pickups per time window** to start, editable in settings. A full window shows as **Full**. Staff phone orders may override with a reason. |
| Days | All 7 days, three windows (7-11, 11-4, 4-8) as today. |
| Notes | A **care note** with stain and care prompts for dry cleaning, washing and ironing, plus **up to 3 optional photos**, separate from the existing pickup note. |
| Insights | Demand by locality and outside-area interest; small orders and the travel charge; repeat customers and gaps; on-time pickup and delivery. |
| Me as a customer | A **test customer in the local database only**, flagged so it never counts in insights. |

## A. Service area (6 km around LB Nagar)

- **Settings, not code:** drop a pin on LB Nagar Circle in admin settings (centre latitude and longitude), radius 6, and the PIN list. The form already takes these. Add a **"Check an address" tool** (type coordinates or a PIN, see served or not and the distance) so you can test the edge before customers do.
- **Suggested centre (to confirm):** LB Nagar Circle at the bus stop under the Vijayawada highway flyover, **17.3472, 78.5498** (the metro station is about 350 m away at 17.3498, 78.5479). Both are from OpenStreetMap; check the pin in Google Maps before saving it.
- **Suggested PIN list (to confirm):** seven PINs whose main areas all lie 1.8 to 4.8 km from that point: **500074** (LB Nagar), **500060** (Dilsukhnagar, Chaitanyapuri), **500035** (Saroornagar, HUDA complex), **500068** (Mansoorabad, Nagole, Bandlaguda), **500070** (Vanasthalipuram), **500079** (Karmanghat, Champapet), **500059** (Santosh Nagar, Saidabad). Just outside the line and left out: **500036** (Malakpet, 6.1 to 6.4 km), **500039** (Uppal, 6.3 km), **500005** (Balapur, 6.4 km, and the PIN reaches 10 km or more). The PIN list only tightens the radius: an address inside 6 km but in a left-out PIN is refused; an address in a listed PIN but beyond 6 km is refused by the radius. Distances are straight-line from approximate place positions, not surveyed.
- **Staff phone orders:** today an address with no coordinates is treated as inside. New rule: coordinates or a served PIN are required (`ADDRESS_LOCATION_REQUIRED`); an outside address is rejected unless the staff member types a reason, which is stored on the order (`orders.area_override_reason`) and in the audit log.
- **Customer app:** the "not in your area yet" screen keeps Change location, and adds **Tell me when you're here** (one tap, uses the signed-in number, asks consent in plain words). Saving the address stays allowed.
- **Waiting list:** table `area_interest` (user, address, latitude, longitude, PIN, locality, distance from centre, created at, notified at; one open row per user and PIN). Customer endpoint `POST /v1/me/area-interest` (idempotent). Admin page **Outside the area**: counts by PIN and locality with distance bands, newest first, mark as told. Never show another customer's phone outside admin.
- **Capacity:** `business_settings.pickup_capacity_per_slot` (default 8, empty = no cap). A window counts orders with that pickup date and slot that are `PENDING` or `PICKUP_ASSIGNED`. Enforced atomically when placing an order and when rescheduling (lock per date and slot); the scheduling API returns `FULL`; the customer picker shows **Full**; admin phone orders can override with a reason. Settings form gets the field.

## B. Travel charge and the ₹200 rule

- **Rule:** items total before any coupon `< ₹200` adds the flat travel charge; `>= ₹200` is free. It reuses the existing `deliveryFeePaise` (set to 3000) and `freeDeliveryAbovePaise` (set to 20000) settings, but the threshold now compares the total **before the coupon** (today it compares after). `minOrderPaise` stays as a hard minimum and is set to 0. Labels in admin settings change to "Travel charge" and "Free travel from".
- **Quote and bill:** the quote exposes the charge and **how much more makes it free** (`freeTravelShortfallPaise`). Basket and checkout show a **Travel charge** line (₹30 or Free) and one calm line: "Add ₹X more of clothes and travel is free." The order bill, receipt and admin order show the same line.
- **Frozen at booking:** the order stores the rule it was booked under (`orders.travel_charge_paise_rule`, `orders.travel_free_from_paise_rule`), so later settings changes never alter an existing order.
- **Re-check on edits:** item edits re-evaluate the charge on the new items total using the frozen rule, both directions, inside the same price request (the customer sees the old and new total with the charge line changing). Decreases apply with a notice; net increases need approval, as now.
- **Cancel:** by default everything paid is refunded, charge included. The admin cancel dialog gets **"Partner already travelled: keep the travel charge"**, which sets `orders.travel_charge_kept` and reduces the refund due by the charge. The customer sees why.
- **Coupons:** coupon minimums keep comparing the items total, so they are unaffected.

## C. Care notes and photos

- **Why separate:** the pickup note tells the rider (gate, landmark); the care note tells the workshop (stains, delicate, colours). Both stay optional.
- **Customer:** a section in checkout "Anything we should know about your clothes?" with **prompts that depend on the services in the basket** (dry cleaning: stain, delicate fabric, embroidery or beadwork; washing: colours may run, wash separately, heavily soiled; ironing: starch, fold not hang), a note field (500 characters), and up to 3 photos using the existing upload path (processed, metadata stripped, daily limit). The tracking and bill screens show "Your care note".
- **API:** `careNote` and `carePhotoUrls` on place-order; photos must belong to the customer (same ownership check as report photos); stored on the order (`orders.care_note`, `order_care_photos`). Returned to the customer, admin and the assigned partner.
- **Admin:** a "Care note" card on the order with photos at full size, printed on any pickup sheet; it also feeds the intake receipt (FA08).
- **Wording (approved by the owner on 15 November 2026):** "We will try to remove stains but cannot promise it." Shown at the photo step and added to the terms; a lawyer should still read the terms update before release.

## D. Insights (business analytics)

An admin **Insights** page with a date range (default last 30 days), no personal data except where staff already see it:

1. **Demand by locality:** orders, revenue and average basket by PIN and locality; distance bands 0-2, 2-4, 4-6 km; **outside-area interest by PIN** next to it.
2. **Small orders and the travel charge:** share of orders under ₹200, travel charge collected, how many customers added items after seeing the "add ₹X more" line, and how many left after seeing the charge (needs the funnel events from FA15).
3. **Repeat customers:** new versus repeat, median days between orders, and a **lapsed list** (no order for 30, 60, 90 days) for reminders.
4. **On time:** share of pickups and deliveries completed inside their window, average turnaround, window fill against the cap, by slot and distance band.

Support work: `orders.distance_km` stored at booking; `users.is_test` excludes test accounts; funnel events table (FA15) for step 2.

## Local test customer

After the changes are built, create **Claude Test (local)** in the local dev database only (flagged `is_test`), with an LB Nagar address inside the circle and one outside, and run bookings end to end through the dev sign-in: inside and outside the area, under and over ₹200, a coupon, a care note with a photo, a count change at pickup, a cancel with and without "trip wasted", a full window. Nothing touches production.

## Build order and ownership

1. Finish and review phase 1 (reschedule, ledger, undelivered alerts); apply its migrations locally; commit.
2. **Wave A, in parallel with separate file areas:**
   - Travel charge (B): pricing, quote, bill UI, settings labels, refund rule, cancel dialog.
   - Service area (A): enforcement for staff orders, waiting list, capacity, "Full" in the pickers, admin settings tool and Outside the area page.
   - Care notes (C): place-order fields, photos, customer section, admin card.
3. **Wave B:** Insights (D) and `distance_km`, `is_test`, funnel events (FA15), then the rest of phase 2 and 3 (ratings, intake photos, coverage page, first-order offer).
4. Local test customer run, release checklist update, device pass.

## Risks to watch

- The three Wave A pieces all touch the place-order path; each makes small, separate edits and the suite is re-run after each lands.
- A straight 6 km line can include places that are far by road; the PIN list and the "Check an address" tool are the controls. Revisit road distance only if edge complaints appear.
- A flat charge may push people to skip small orders; the small-order insight shows whether to change the amount.
- Capacity counts orders, not clothes; a window of 8 large pickups is not the same as 8 small ones.
