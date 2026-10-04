# IronDost customer app: design research and gap analysis

Date: 4 October 2026. Scope: Flutter customer app (`apps/customer`). Question: why does the app read as generic, and what do laundry and home-service leaders do that it doesn't?

## Read this first: what this research is and is not

| Source | Status |
|---|---|
| The app's own screens (`after/*.png`, 10 key screens reviewed) and code (`apps/customer/lib`, `apps/api`) | **Verified.** Every "current state" statement below comes from these. |
| Mobbin | **Not used.** The connector is linked, but every search (screens and flows) returned "Mobbin MCP requires a paid plan". No Mobbin screens were reviewed and none are cited. Section 6 lists the exact queries to run once the plan is active. |
| Web search results | **Secondary.** Summaries of published case studies, store listings and competitor pages. I could not open the pages themselves (the sandbox's network policy blocked medium.com, apps.apple.com, rinse.com and the competitors' sites), so these are search-result summaries, not read-through-the-page evidence. Each is linked. |
| Design judgment | Marked **(judgment)**. Not sourced; weigh accordingly. |

The existing audit ([AUDIT.md](AUDIT.md), [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)) is not repeated here. It fixed layout, accessibility and clutter, and that pass worked. This document is about what is *missing* now that the clutter is gone.

## 1. Verdict: why it feels generic

The v2 pass removed decoration (bubbles, nested cards, hero blocks). That was right, but it left a clean, anonymous app: one blue, one list pattern, text rows everywhere. A user could swap the logo for any other service and nothing else would change. Five specific causes:

1. **Nothing is specific to clothes.** Catalogue rows, basket rows and order cards are text and numbers only. The only garment imagery is three 3D service icons at 28–48 dp.
2. **No visible craft or promise.** The app never says *how* clothes are ironed (steam? press?), how long it takes, or what happens if something is damaged. For a service where customers hand over their wardrobe, that is the trust moment, and it is absent.
3. **The post-booking journey is thin.** The confirmation screen is the stock "green check in a tinted circle" pattern and says nothing about what happens next. Tracking is a correct but plain stepper.
4. **A built capability is unused.** The API already accepts and stores order `instructions` (`apps/api/prisma/schema.prisma:322`; the admin phone-order screen writes it). The customer app never sends it. Customers cannot say "starch the collars", "hang, don't fold", or "call before arriving".
5. **No signature element.** There is no recurring motif, motion or component that is recognisably IronDost (judgment).

## 2. Screen-by-screen: current state, what leaders do, gap

"UI only" means doable with data the API already returns. "Needs API" or "Needs partner app" means a backend or `mobile/partner` change (the partner app is "Not started" per the README).

| Screen | Current state (verified) | What leaders do | Gap and recommendation | Effort |
|---|---|---|---|---|
| **Home** | First screen: greeting, generic tagline, active order, Book CTA, then a full offers carousel. The "Services" heading is only just visible at the bottom of the first screen, so the thing you sell is below the fold. | Washmen and Rinse centre the home on *choosing what to send* (bag or service type) ([Washmen listing](https://apps.apple.com/us/app/washmen-laundry-dry-cleaning/id1037965236), [Rinse](https://www.rinse.com/)). UX case studies for laundry apps stress "every important feature available without clutter" and a home that answers where the clothes are, what it costs, and whether to trust the provider ([case study](https://barridesign.medium.com/ui-ux-case-study-for-a-laundry-business-mobile-app-9faf91356075)). | Put service rows (with price basis) above the offers carousel. Replace the tagline "Ironing, washing and dry cleaning." with a verifiable promise line. Add one compact trust strip (turnaround, process, damage cover). **Only claims the business can back; needs owner input.** | UI only |
| **Catalogue** | Divided text rows: name, ₹ price, "per piece", stepper. Large empty area below three rows. Tab icons are the 3D trio. | Apps for garment services let users attach notes, stains and condition to items ([CleanCloud](https://cleancloudapp.com/features)); Washmen lets users report stains and add notes for delicate items. | Consistent garment glyphs per item type (shirt, trousers, saree, blazer), and use admin `imageUrl` when set (the field exists; rows render it only if supplied). Add an item-level "i" sheet for what's included. Add a service explainer under the tab bar. | UI only (art needed) |
| **Basket** | Each line stacks name, then stepper below, so three items fill the screen. The line price floats near the middle of the row instead of aligning right. Footer CTA says "Choose pickup time" and carries no total. | Blinkit and Swiggy Instamart show the payable amount on the final CTA; one Zepto user complaint is that it does not ([thread](https://www.threads.com/@beastoftraal/post/DIdLu45TWDw/figured-out-recently-that-while-swiggy-instamart-and-blinkit-show-the-final-amou?hl=en)). | Put name, stepper and right-aligned line price on one row. Show the total in the basket footer, as the catalogue cart bar already does. Keep the estimate-versus-final-count explanation prominent (see Rinse lesson below). | UI only |
| **Schedule** | Good: date strip, divided slot rows, delivery summary. Closed slots take the most space on "Today". | Independent Urban Company UX case studies report that merging provider choice and slot choice cut time-to-purchase by about 50%, and that pre-selecting the saved address for returning users removed a step ([case study](https://medium.com/uxm-community/fixing-the-heat-a-ux-journey-through-urban-companys-ac-service-booking-experience-to-impact-137e4bd7e7ef)). A "high demand" slot marker was tested as a hypothesis, with no confirmed result in what I could see. | Collapse closed slots into one muted line ("Morning and Afternoon closed for today"), and preselect the first open slot. Add a pickup-notes entry here or on checkout (see section 3, item 1). | UI only |
| **Checkout** | Strong: review rows with Change, payment choice, "Secure payment by Razorpay", amount on the CTA. | Same pattern as the quick-commerce apps above. | Keep. Add the optional note to partner. | UI only |
| **Confirmation** | Green check in a tinted circle, "Pickup booked", dates, order ID, two buttons. | Leaders use this moment to set expectations for the next steps. The laundry case studies emphasise order visibility and delay notification as the core trust problems ([case study](https://medium.com/@debora.maretauli/the-solution-to-your-laundry-problems-becomes-easy-with-the-lemons-laundry-app-ui-ux-case-study-60d4bf8d6abc)). | Add a short "What happens next" list: partner assigned, pickup and count confirmation, ironing, delivery. Add "get your clothes ready" guidance. Drop the generic tinted check circle for something IronDost-specific (judgment). | UI only |
| **Tracking** | Correct five-step timeline, honest overdue copy, a blue info panel ("You'll see your partner's name…"), a yellow payment-due panel. No map, no partner card until assigned, no ETA language beyond the slot. | Tracking guidance from delivery-app engineering write-ups: a split layout with a map around half the height over a fixed status panel; markers for partner, pickup and drop; ETA that recalculates; grey for expected, orange for delayed, green for early ([Drizz](https://www.drizz.dev/post/testing-real-time-features-in-delivery-apps-maps-live-tracking-and-eta-updates)). | Make the status the hero ("Out for delivery, arriving 4 to 8 PM"). Show the partner as a card (initials, name, call) once assigned. Use warning colour only for the delay state, with a clear action. **Live map: the order payload carries only the partner's name and phone (`PersonRefDto`), not coordinates, so this needs an API change.** | Hero and card: UI only. Map: needs API |
| **Orders list** | Two text cards: status, first item, pickup and delivery, amount chip, Track or Pay. Reorder exists only inside order detail ("Book the same again"). | Repeat-order shortcuts are standard for recurring services (judgment; no source reviewed). | Add a one-line garment summary ("12 shirts, 4 trousers") and a Repeat action on past orders. Surface "Repeat last order" on Home for returning customers. | UI only |
| **Offers** | Campaign banner carousel with readable terms. | Indian competitors lead with price and first-order offers; LaundryGo lists 2.5% wallet cashback ([LaundryGo](https://www.laundrygo.in/steam-iron.html)). | Fine as is. Wallet or cashback is out of v1 scope (see section 5). | n/a |
| **Account** | Standard settings list. | n/a | No change needed for the "generic" problem. | n/a |

## 3. What is missing, in priority order

### P1: high impact, builds on what already exists

1. **Pickup and care notes.** Add an optional note field and quick chips on checkout ("Call before arriving", "Starch collars", "Hang, don't fold"). Chips compose into the existing free-text `instructions` field, so this is UI-only. Washmen exposes the same idea: special instructions for how items are packaged, folded, hung, creased or starched ([listing summary](https://apps.apple.com/us/app/washmen-laundry-dry-cleaning/id1037965236)). Before shipping, confirm the partner and workshop actually see the note; the API stores it and the admin shows it on phone orders, but I did not verify the order-detail views.
2. **Home reorder: services first, then offers.** Move service rows with price basis above the carousel, and add one trust strip.
3. **State the craft and the promise.** One "How we iron" sheet per service: process, turnaround, what is counted and when, damage cover. Hyderabad competitors state price, turnaround and process on their pages: Irony quotes ₹19 per piece or ₹89 per kg with 24-hour delivery ([Irony](https://www.ironystore.in/)); LaundryGo starts at ₹25 per piece with 8 AM to 8 PM pickup ([LaundryGo](https://www.laundrygo.in/steam-iron.html)); Steamee markets itself as an app-based steam-ironing service with 24 to 48 hour delivery ([Steamee](https://steamee.in/)). Your catalogue fixture shows ₹15 per shirt; **check the live catalogue**, but if it is real, price is a differentiator the app never mentions.
4. **Confirmation and tracking as a story.** "What happens next" on confirmation. A status-hero tracking screen with a partner card.
5. **Garment-specific visuals in the catalogue.** One consistent glyph or illustration set for item types, plus admin images where available.

### P2: polish with clear payoff

6. Basket row layout fix and total in the basket footer.
7. Collapse closed slots; preselect the first open one.
8. Order-card garment summary and a Repeat action (list and Home).
9. A small signature system (judgment): a garment-tag or crease motif for order IDs and receipts, and one restrained completion moment (for example a short steam-clear animation on "Delivered", respecting reduced motion). Keep the design system's rule against decorative looping motion.
10. Empty and offline states with a little personality, still one action each.

### P3: needs product or backend decisions

11. **Live partner map**: API must expose partner coordinates to customers.
12. **Photo proof at pickup and delivery**: needs the partner app, which is not started.
13. **Ratings after delivery**: explicitly out of v1 in the app plan; the plan lists it as a candidate for v1.1.
14. **Wallet, cashback, subscriptions** (monthly ironing plans): out of v1.

## 4. Lessons from competitors worth copying or avoiding

- **Price certainty matters.** Reviews summarised in search results report that Rinse customers sometimes got large unexpected invoices when the bag size wasn't what they expected ([Whisk's Rinse review](https://whisklaundry.com/blog/rinse-laundry-review-pricing/), a competitor's blog, so treat it as indicative). IronDost counts pieces at pickup, which has the same risk. Your existing line "A rough count is fine. Your partner confirms it at pickup." is the right instinct; make it more visible in basket and checkout and show how the final count changes the bill.
- **Show the total where the decision happens.** Blinkit and Instamart do; keep your checkout CTA as is and extend it to the basket footer.
- **Process visibility is the category's trust lever.** Washmen's colour-coded bags and item-level notes and Rinse's bag types make the process tangible. IronDost has no equivalent object yet (judgment: a numbered garment tag or pickup receipt would be the cheapest one).

## 5. Boundaries

- Stay inside v1 scope in `customer-app-plan.md`. Items 11 to 14 above are product decisions, not design fixes.
- Do not add claims the business can't back (turnaround, damage cover, "steam"). Ask the owner first; the existing audit already removed copy that promised behaviour the system lacked.
- Keep the design-system rules: one primary action per screen, 20 dp gutters, no decorative looping motion, text always accompanies status colour.

## 6. To finish this in Mobbin (once the plan is active)

Run these on iOS, one per search, and compare against the table in section 2. The exact wording follows Mobbin's own guidance (one screen or flow per query).

Screens:
1. Laundry or dry cleaning app home with service categories and a book button
2. Item selection list with garment photos and quantity steppers
3. Pickup time slot picker with date strip and time windows
4. Order confirmation screen with a what-happens-next list
5. Order tracking with a status timeline and delivery partner card
6. Delivery partner card with call button and vehicle details
7. Special instructions or notes field on checkout
8. Repeat last order shortcut on a home screen
9. Delayed order state with updated estimate

Flows:
10. Booking a laundry pickup: choose items, pick a time slot, confirm
11. Tracking an on-demand service order from booked to delivered

Useful apps to name in a query: Washmen, Rinse, Urban Company, Blinkit, Swiggy.

## 7. Status: built and not built

Verified on Flutter 3.47.6: `flutter analyze` clean; 416 tests pass (398 before, 18 added); the 200% text stress suite passes 78/78 at each of 320, 390 and 430 dp. Layout was checked on real-font renders, not just widget tests. The captures in `after/` were **not** regenerated, so they still show the earlier Home, Basket, Checkout and Confirmation layouts.

| Item | State |
|---|---|
| 1. Pickup note (checkout) | **Built.** Optional note, three neutral quick phrases, sent as the order's `instructions` (max 500). The helper line says "IronDost sees this with your order": staff see it on the admin order page; there is no driver app yet. Care requests (starch, hanging) are typed freely; I did not add them as one-tap options because I don't know you offer them. |
| 2. Home: services before offers | **Built.** Services now sit directly under Book a pickup. The trust strip is **not** built: it needs claims you can back. |
| 4. Confirmation "What happens next" | **Built.** Three steps that only restate things the app already says. |
| 6. Basket price alignment | **Built.** The price floated mid-row because a `Flexible` and an `Expanded` split the row 50/50. Total in the basket footer is **not** built. |
| 3. "How we iron" sheet and promise copy | Not built. Needs your content. |
| 5. Garment glyphs in the catalogue | Not built. Needs artwork. |
| 4. Tracking status hero and partner card | **Built.** A five-segment progress bar and a clock icon on the "when" line; a late state (amber icon and bar, plus a "Call us" button) when the delivery estimate has passed, still with the existing words; the partner card now has the same shape before and after a partner accepts, with a "Pickup partner" or "Delivery partner" label. The hero and partner card also moved onto the 20 dp grid the timeline uses. No logic or copy changed. **Known and left alone:** a delivery window like "4 – 8 PM" can wrap at the dash; fixing it needs non-breaking spaces in strings that many tests match on. The live map is not built (needs an API change). |
| 7. Collapse closed slots; preselect first open | Not built. |
| 8. Order-card garment summary; Repeat action | Not built. |
| 9, 10. Signature system, empty-state personality | Not built. |
| 11 to 14 (map, photo proof, ratings, wallet) | Not built; backend or product decisions. |

## Sources

Search-result summaries; pages themselves were not opened (see the table at the top).

- [UI/UX case study for a laundry business app](https://barridesign.medium.com/ui-ux-case-study-for-a-laundry-business-mobile-app-9faf91356075)
- [Lemon's laundry app case study](https://medium.com/@debora.maretauli/the-solution-to-your-laundry-problems-becomes-easy-with-the-lemons-laundry-app-ui-ux-case-study-60d4bf8d6abc)
- [Washmen on the App Store](https://apps.apple.com/us/app/washmen-laundry-dry-cleaning/id1037965236)
- [Rinse](https://www.rinse.com/) and [Whisk's Rinse review](https://whisklaundry.com/blog/rinse-laundry-review-pricing/)
- [Urban Company AC booking UX case study](https://medium.com/uxm-community/fixing-the-heat-a-ux-journey-through-urban-companys-ac-service-booking-experience-to-impact-137e4bd7e7ef)
- [Real-time delivery tracking write-up (Drizz)](https://www.drizz.dev/post/testing-real-time-features-in-delivery-apps-maps-live-tracking-and-eta-updates)
- [CleanCloud features](https://cleancloudapp.com/features)
- [LaundryGo](https://www.laundrygo.in/steam-iron.html), [Irony](https://www.ironystore.in/), [Steamee](https://steamee.in/)
- [Threads post on Zepto, Instamart and Blinkit payable-amount display](https://www.threads.com/@beastoftraal/post/DIdLu45TWDw/figured-out-recently-that-while-swiggy-instamart-and-blinkit-show-the-final-amou?hl=en)
