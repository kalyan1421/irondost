# Recon map: the five most-downloaded laundry apps in India (iOS and Android)

Scope: the customer booking loop of DhobiLite, Tumbledry, Fabrico, LaundryMate and LaundroKart, and the web pages that support it.
For: IronDost (Hyderabad, launching around LB Nagar). This is a competitor study, not a clone brief.
Date: 2026-11-07
Evidence level: **public sources only** (store listings, marketing sites, public videos, public review pages). Nothing was installed, nobody was signed in to, no forms were submitted. Logged-in screens were not seen at any of the five.

## Scope answers (replica-recon step 1)

1. **Which apps, which platform:** the five most-downloaded India laundry-service apps by Google Play download band and App Store rating count ([top-laundry-apps.md](top-laundry-apps.md)); iOS and Android listings for each. Three serve Hyderabad (DhobiLite, Tumbledry, Fabrico). LaundryMate (Bengaluru, Gurugram) and LaundroKart (Bengaluru) do not.
2. **Which slice:** the core loop only: choose, schedule, pay, track, get help.
3. **For whom:** IronDost's own business. Features and patterns are learned; brands, copy, artwork and colours are not taken.

## Sources

| # | Source | What it gave |
|---|---|---|
| 1 | Store listings: [DhobiLite](https://apps.apple.com/in/app/dhobilite-dry-clean-laundry/id1128126966) · [Tumbledry](https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539) · [Fabrico](https://apps.apple.com/in/app/fabrico-laundry-dryclean/id1541387385) · [LaundryMate](https://apps.apple.com/in/app/laundrymate/id1632839902) · [LaundroKart](https://apps.apple.com/in/app/laundrokart/id1552864492), and the five Play listings | Ratings, versions, screenshots (68 saved in [screens/](screens/README.md)), descriptions, public reviews |
| 2 | Apple iTunes Lookup and Search API (India storefront) | Official ratings, rating counts, publishers, screenshot URLs, ranking proxy |
| 3 | Marketing sites: dhobilite.com, tumbledry.in, fabrico.in | Positioning, public price lists (DhobiLite, Fabrico), Hyderabad pages, store lists, FAQs |
| 4 | Public YouTube walkthroughs (Tumbledry Android v16.0.8, DhobiLite Aug 2025, Fabrico about 2022) | Real in-app screens at Tumbledry and older versions of the others |
| 5 | Public review pages: Google Play, App Store, Google Maps; Trustpilot for Tumbledry | 238 collected reviews ([reviews.csv](reviews.csv)) |
| 6 | Three research agents' teardowns | Per-app detail with every claim tagged: [Tumbledry](competitors/tumbledry/teardown.md), [DhobiLite](competitors/dhobilite/teardown.md), [Fabrico](competitors/fabrico/teardown.md), plus [LaundryMate and LaundroKart](competitors/market-listings.md) |

Spot checks I ran on the agents' work: review text matched live pages word for word in every testable case (see [fixes.md](fixes.md)); the Fabrico price table for Dilsukh Nagar could not be re-checked without a browser and is marked agent-observed.

## Core loop

Choose what to send, pick a pickup time, pay (often after intake), and wait for a rider to bring it back. The market splits on one question: **is the price known before the clothes leave?** At DhobiLite, Tumbledry and Fabrico it is not (bill after intake); at LaundryMate and LaundroKart it is.

## Screens

Per-app inventories hold the IDs (DL-S01 to S20, TD-S01 to S22, FB-S01 to S10 plus web and legacy). Here, the screen families that matter for IronDost, with the apps that show them:

| ID | Family | Seen at | Key components | States seen |
|---|---|---|---|---|
| M01 | Onboarding and serviceability gate | Fabrico (location check, then "not serviceable, log in to see areas") | Illustration, single Login button | Not serviceable |
| M02 | Home | All five | Promo banner or carousel, service tiles, address chip, one big CTA; LaundryMate adds a membership strip and Sprint toggle; LaundroKart adds active-order card and Book again chips | Filled, CTA disabled until a service is chosen (Tumbledry, Fabrico) |
| M03 | Service and item selection | LaundryMate, LaundroKart (items and prices); Tumbledry, Fabrico (service tiles only) | Audience tabs, item rows with steppers, search | Selected tile (grey fill at Tumbledry) |
| M04 | Basket and total | LaundryMate (basket total), LaundroKart (bill) | Totals, coupon | Filled |
| M05 | Pickup schedule | All five | Date strip, slot grid or rows, express options, address card, coupon field | Selected date and slot |
| M06 | Speed choice | LaundroKart (Normal, Semi, Express), Fabrico (Same Day +100%, Next Day +50%), LaundryMate (+20% tags) | Radio rows with a price delta | One selected |
| M07 | Confirmation | Tumbledry, Fabrico, DhobiLite | "Keep your items ready", Reschedule, Cancel | Filled |
| M08 | Orders and tracking | DhobiLite (7-step stepper, rider call), LaundroKart (timestamped tracker), Tumbledry (four counters), Fabrico (Pickups and Dropoffs list) | Stepper, counters, tabs | Empty ("No orders found" at Tumbledry), active |
| M09 | Wallet, packages, membership | All five | Package cards, recharge packs, deposit | Active and available tabs (Tumbledry) |
| M10 | Support | All five | Call, WhatsApp tab, form with photo, call-back | Empty form |
| M11 | Account and settings | Tumbledry, Fabrico | Profile, Contact, Call, Share, Language (Fabrico), Delete Account | |
| M12 | Price list | Tumbledry (in app), DhobiLite and Fabrico (web), LaundroKart (in app) | Category dropdown, search, rows with prices | Loading placeholder, "--" cells (DhobiLite web) |

Not observed at any of the five: payment sheet in the booking flow (seen only for packages at Tumbledry), order review, notification screens, empty and error states beyond the two above, dark mode other than DhobiLite's.

## Flows

```
F01 First booking, scheduler style (DhobiLite, Tumbledry, Fabrico)
    M01/M02 -> M05 (day, window) -> M07 confirmation
    returning user taps: DhobiLite about 4, Fabrico 4 to 5, Tumbledry about 6
    first time: Tumbledry about 8 taps plus 5 fields; Fabrico 11 to 15 taps and inputs
    edge: not serviceable, slot changed by the store, OTP not arriving, price differs at pickup
    (agent tap counts; the order of steps is partly inferred, see teardowns)

F02 First booking, shop style (LaundryMate, LaundroKart, IronDost)
    M02 -> M03 items -> M04 basket -> M05/M06 slots and speed -> pay -> M07
    IronDost estimate: about 8 to 10 taps plus one per item (route structure, not measured)

F03 Track an order            M02 -> M08          edge: status stuck "in progress", wrong dates (reviews)
F04 Reschedule or cancel      M08 or M07 -> reschedule / cancel reason
                              edge: company reschedules without notice (reviews)
F05 Get help                  M10 -> call / WhatsApp / form with photo
                              edge: calls unanswered, email bounces, hang-ups (reviews)
F06 Buy credit or a package   M09 -> pay sheet (Paytm PG at Tumbledry) -> balance
                              edge: package terms differ between web and app (observed)
```

## Components

| Component | Variants seen | States | Used on |
|---|---|---|---|
| Date strip | Day cards (DhobiLite, 3 days), strip with weekday and date (Tumbledry, Fabrico), chips (LaundroKart) | selected, unselected | M05 |
| Slot | 2 by 2 cards with icon and mood caption (DhobiLite), hourly chip grid (Tumbledry, Fabrico), rows with express tag (LaundryMate) | selected, closed | M05 |
| Service tile | Outlined tile with icon (Fabrico, Tumbledry), white tile on navy (DhobiLite older), card with price (LaundroKart) | selected, disabled | M02, M03 |
| Bottom action bar | Full-width teal or yellow bar; pill; split bar (Back / Buy Now) | enabled, disabled (pale) | M02, M05, M09 |
| Order stepper | 7-icon rail (DhobiLite), 4-stage timestamped line (LaundroKart) | active, future | M08 |
| Counter tiles | Orders, Processing, Due, Ready (Tumbledry) | zero | M08 |
| Package or wallet card | Package card with SAVE ribbon (Tumbledry), magenta wallet card (LaundroKart) | available, active | M09 |
| Promo banner | Carousel with dots (all) | | M02 |
| Bell with count | All but LaundroKart (not seen) | | header |
| Quantity stepper | LaundryMate item rows | zero, one or more | M03 |

## Inferred data model (what their screens imply; guesses marked)

```
Customer      phone, name, email, addresses (Tumbledry: one saved address only)
              evidence: Tumbledry info form, reviews                         confidence: medium
Store         id, name, address, rating, price list, billing system          confidence: high (Fabrico store codes
              (franchise networks; the store prices the order)               embed the pincode; Tumbledry store cards)
PriceBook     store x garment x service (dry clean, steam press, premium     confidence: high (Fabrico 213 garments
              press, starch) and per-kg laundry tiers                        per store, with an update date)
PickupRequest customer, date, window, services, speed (same day, next day),  confidence: medium
              status; becomes an Order after intake
Order         items counted and priced by the store after pickup, invoice,   confidence: medium (reviews on bill
              status (counters), due amount                                  differences; DhobiLite no item picker)
Package/Wallet tier, price, bonus, validity, balance                         confidence: medium; terms inconsistent
Coupon        code, percent or flat, first-order flag                        confidence: high
Referral      code, reward credit                                            confidence: medium
Ticket        type, text, photo (not order-linked)                           confidence: medium
```

## Feature matrix

[features.csv](features.csv): 56 rows: 50 scored (must 16, should 24, could 10), 2 skipped, 4 IronDost-only. IronDost status on the scored rows: 24 yes, 4 partial, 22 no. Parity result and gaps: [parity.md](parity.md).

## Out of scope (cannot or should not be taken)

- Their store networks, franchise deals, partner contracts, certified-machinery claims and customer bases.
- Their logos, icons, illustrations, photos, copy and brand colours (recorded as roles in [design/](design/design-teardown.md) for comparison only).
- Their prices as anything but market evidence; their review text as testimonials.
- Anything behind a sign-in. Their payment provider arrangements (Paytm PG at Tumbledry).

## Size

Screens inventoried across the three deep teardowns: about 45 observed plus about 15 explicitly not observed; flows: 6; entities: about 10. **Hard parts for IronDost, if it adopted the patterns:** a rider client, stored value, a capacity-aware express promise. **Size: M for the study; the build plan is L (see [architecture.md](architecture.md)).**

Next step: `/replica-architect` (done: [architecture.md](architecture.md)).
