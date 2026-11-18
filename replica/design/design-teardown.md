# Design reverse-engineering: five laundry apps and IronDost

replica-design output for the competitor study. Date 2026-11-07. This describes **systems**: roles, scale, layout patterns and feel. It records competitors' brand colours as roles for comparison only. Nothing here is a spec to copy: logos, icons, illustrations, photos, copy and brand colours are theirs.

## How the evidence was gathered, and how far to trust it

| Evidence | Used for | Confidence |
|---|---|---|
| Public store-listing screenshots, saved in [../screens/](../screens/README.md) (68 images, about 15 MB) | Layout, components, colour | Real app screens for Fabrico (Android); phone mockups inside marketing frames for the rest |
| **Colours measured from pixels** inside the phone frames (`*.tokens.json` in this folder) | Palette | High for hue and lightness; ± a few units per channel (JPEG, marketing grading) |
| Agents' notes on the apps' real UI (Android recording of Tumbledry, an older DhobiLite walkthrough, websites) | Type, spacing, shape, flows | **Eyeballed.** Low to medium. Fonts are described by category only; none is named by the apps |
| Competitor websites | Texture, tone, marketing layout | Medium |

Not seen anywhere: logged-in screens (order review, payment, tracking, profile). Store screenshots are curated, may be old (one Tumbledry frame shows a July date from about 2022), and differ by platform.

## The five at a glance

| | Archetype | Brand colours (measured) | Surface | Texture | Nav | Signature move | Contrast on measured pairs |
|---|---|---|---|---|---|---|---|
| **Tumbledry** | Scheduler on a white-label platform | Lime `#A4CC34`, amber `#FCC40C`, navy `#243C64` | Dark charcoal `#232323` home; light schedule screen | Flat Material, stock photos | Hamburger, 4 tabs (Home, Orders, WhatsApp, Packages) | Hourly slot grid beside a date strip | Passes (8 to 15:1). Agent estimates white on amber near 1.6:1 (eyeballed) |
| **DhobiLite** | Scheduler, promo-heavy | Orange `#FD931B`, blue `#4288D4`, legacy navy `#044C6C` | Near-black `#171717`, cards `#212530` | Flat dark, photo process cards, 3D promo art | 5 tabs (Schedule, Orders, Prepaid, Rate List, Account) | Four mood-named time windows; process carousel inside booking | White on blue button **3.68:1 (fails)** |
| **Fabrico** | Scheduler on the same platform | Teal `#4DC1AC` | White `#FBFCFC`, mint tint `#E8F7F5` | Flat, soft, line icons in outlined tiles | Hamburger, 4 tabs (Home, Orders, WhatsApp, Refer & Earn) | Same Day +100% / Next Day +50% radios under the slot grid | White on teal **2.20:1 (fails)**, teal on white 2.16:1, grey on grey field 2.99:1 |
| **LaundryMate** | Shop with basket and membership | Yellow `#FECC04`, blue `#0274BC` | White with yellow bands | Flat, high-chroma, rounded cards | 5 tabs (Home, Orders, Basket, Membership, Wallet) | Standard vs Quick order; express tags on slot rows; "Sprint" toggle | Blue on yellow **3.28:1 (fails)** |
| **LaundroKart** | Shop, editorial, wallet-led | Cream `#F6F3EE`, plum `#2B1331`, magenta `#B8227D`, gold `#AC7C1C` | Warm cream | Soft gradients, serif italic accents | Tabs for Active, Upcoming, History; wallet card | Normal / Semi / Express speed picker with price multipliers | Gold on cream **3.36:1 (fails)**; others pass |
| **IronDost** (shipped) | Shop with basket | Royal `#1F4FD1`, offer yellow `#FFC93C` | Soft grey `#F7F8FA` / white; dark `#101820` | Flat, no resting shadows, three matte 3D service images | 4 tabs (Home, Orders, Offers, Account) | Server-quoted basket; separate pickup and delivery windows | **26 of 26 pairs pass** in light and dark |

## Two UX archetypes and a shared platform

1. **Scheduler-first** (Tumbledry, DhobiLite, Fabrico). The home screen is a service tile or a day and slot picker. There is no item list, no price and no basket before booking; the bill is raised after intake. Booking is 4 to 6 taps (agent counts, partly inferred). Fast, and the source of the "price changed after pickup" complaints.
2. **Shop-first** (LaundryMate, LaundroKart, IronDost). Services, then items with prices and steppers, then a basket total, then slots and payment. More taps, but the customer sees what they will pay.

**Tumbledry and Fabrico run on one platform.** They share a publisher (DC Web Services on the App Store, Quick Dry Cleaning Software on Play), the same app skeleton (hamburger, centred wordmark, bell, date strip, slot grid, WhatsApp tab, Contact Us form with photo, Delete Account in settings) and sibling apps (FABO and others listed on the stores). I treat them as one design with two skins. Inference from observed structure and publisher; neither company states it.

## Per-app notes

### Tumbledry (platform skin: lime and amber)
- **Colour:** dark charcoal canvas with a lime wordmark; light screens use a lime header and amber action bars. Measured accents: lime `#A4CC34`, amber `#FCC40C`, navy `#243C64`, crimson offer numerals `#B41C3C`. About five greys.
- **Type and spacing (eyeballed):** system sans (Roboto on Android) in a flat hierarchy, bold right-aligned prices, 16 dp gutters, rows 56 to 64 dp.
- **Shape:** tiles about 8 to 10 dp with a light lime border; selected state is a grey fill, not a colour change. Two CTA shapes coexist: a pill on Home and square full-width bottom bars in the flow.
- **Texture:** flat, stock photography banners, a black delivery van graphic; icons inconsistent (rose line icons, solid lime glyphs, black outlines).
- **Layout:** banner carousel, "Select Service" tile row, one big "Schedule Pickup" pill (disabled until a service is chosen); Orders tab shows four counters (Orders, Processing, Due, Ready) rather than a timeline; Packages tab with 10 to 30% prepaid cards.
- **Learn:** slot grid and date strip are familiar and quick. **Avoid:** three visual dialects (dark ads, pastel website, lime app), square and pill buttons mixed, light-on-lime labels, counters instead of status.

### DhobiLite (own app, dark, promo-heavy)
- **Colour:** current Android app is dark (`#171717`, cards `#212530`) with an orange organic-curve header and blue primary buttons (`#4288D4`). **Two accents compete:** the brand is orange but the main buttons are blue. The earlier version was light.
- **Type and shape (eyeballed):** neo-grotesque sans; tab labels all caps at 8 to 9 pt; Place Order is a rounded rectangle while Back and Confirm are full pills in the same flow.
- **Texture:** flat dark cards, selection by orange outline; photography for the 10-step process carousel; 3D promo banners; a floating orange bell on every screen.
- **Layout:** blue promo banner, address card, three day cards, four mood-named windows in a 2 by 2 grid, coupon field, Place Order; process carousel pushes the screen long. Orders: 7-icon stepper, runner row with call button, Share My Location.
- **Learn:** visible rider and a stage stepper. **Avoid:** competing accents, inconsistent buttons, coupon codes everywhere (MY20, MY25, APP30), prepaid plan prices that differ between the website and store art (₹3,499 vs ₹5,555 for the same "Big" plan; both are in the saved screenshots).

### Fabrico (platform skin: teal)
- **Colour:** white page, one teal `#4DC1AC` for header status area, bars, selected date and CTAs, mint tint `#E8F7F5`, grey fields `#DDDDDD`. **Teal carries every job, and white text on it is 2.20:1.**
- **Type (eyeballed):** small 10 to 11 pt labels in a sans; light-grey and teal text on white.
- **Shape and texture:** square-cornered outlined tiles with line icons, one-hour slot chips as outlined rectangles, flat; soft mint banner with a basket photo; a disabled-looking pale teal CTA.
- **Layout:** location check first ("not serviceable, log in to see nearest areas"), then service tiles, slot picker with surcharge radios, confirmation ("keep your items ready", Reschedule, Cancel), Pickups / Dropoffs tabs, Refer & Earn with a wallet credit.
- **Learn:** the serviceability gate and the plain confirmation state. **Avoid:** one colour for everything, tiny low-contrast text, no price anywhere in the flow.

### LaundryMate (shop, yellow and blue)
- **Colour:** high-chroma yellow `#FECC04` with blue `#0274BC`, teal labels `#177777`, an indigo `#2B1D81` mode chip; white cards. Blue text on yellow fails (3.28:1); grey text on white passes (7.0:1).
- **Layout:** greeting and address chip, membership strip, **two ways to order** (Standard: pick items; Quick: schedule without items), "Sprint" toggle, audience tabs (Men, Women, Kids, Household), item rows with steppers, a four-step progress strip (address, slots, basket summary, payment), **express tags on slot rows ("+20% express fees")**, membership screen with a refundable deposit.
- **Learn:** the progress strip, price tags on the slot rows, audience tabs. **Avoid:** blue on yellow; reviews report an update that crashed on launch and a scroll bug that hid the payment button.

### LaundroKart (shop, editorial, wallet)
- **Colour:** cream `#F6F3EE`, plum ink `#2B1331`, magenta `#B8227D` fading to purple `#7C2C8C` on the wallet card, gold italic accent `#AC7C1C` (fails on cream at 3.36:1). Ink and magenta pass comfortably (15:1, 5.3:1).
- **Type:** serif italic accent words inside a sans headline ("We give you your *time* back"); looks like a deliberate editorial voice. Marketing frames only; in-app use is smaller.
- **Layout:** Home shows the active order as a card with a progress line and "Back by <date>", a "Book again" chip row, service tiles; booking asks **where, what, when, how fast** in that order, with Normal, Semi and Express cards showing a multiplier; order detail has a four-stage tracker with timestamps; wallet with recharge packs and bonus credit; Orders in Active, Upcoming and History.
- **Learn:** the where-what-when-how-fast sequence, the Back-by line, Book again chips, timestamps in the tracker. **Avoid:** gold-on-cream accents; a wallet that rewards large top-ups (₹10k pack, ₹2,000 bonus) is a stored-value liability that needs advice first.

## How IronDost compares

| Dimension | Market | IronDost today | Reading |
|---|---|---|---|
| Brand colour distinctness | Orange, lime, teal, yellow, magenta, plus blues at DhobiLite and LaundryMate | Royal blue `#1F4FD1` | **Distinct.** Nearest competitor colours are LaundryMate blue and DhobiLite's blue button at ΔE 43 (clearly different). |
| Offer yellow | Tumbledry amber `#FCC40C`, LaundryMate yellow `#FECC04` | `#FFC93C`, small offer marker only | **Close** (ΔE 9.7 to Tumbledry, 12.3 to LaundryMate). Low risk as a small marker; do not grow it into a CTA colour. |
| Ink navy | Tumbledry navy `#243C64` | `#0E1E3D` | Related (ΔE 14.4); text and logo only. |
| Contrast | Four of five fail a measured pair | 26 of 26 pairs pass | A real, provable difference. |
| Resting elevation | Mostly flat | None | Consistent. |
| CTA shape | Mixed pill and square at three apps | One primary action per view, 10 dp radius | Consistent. |
| Item-level price before booking | LaundryMate, LaundroKart | Yes | Differentiator versus the three Hyderabad apps. |
| Status | Stepper (DhobiLite), timestamps (LaundroKart), counters (Tumbledry) | 8-step timeline, realtime, overdue label | Ahead of the Hyderabad set. |
| Texture | Photography, stock banners, editorial type, 3D promo art | Three matte 3D service images, flat UI | Own look; keep. |
| Localisation | Fabrico has a language switch | English only | Gap for Hyderabad. |

## Patterns worth adapting (not copying)

All map to rules already in [IronDost's design system](../../docs/ui-ux-audit/DESIGN_SYSTEM.md): one primary action per view, divided rows instead of nested cards, text and controls that meet AA, 200% text scaling.

1. **Speed choice with the price beside it** (LaundroKart, LaundryMate): selectable rows, price delta in the row, no hidden multiplier. Fits `SlotRow`. Pairs with the express feature in [../architecture.md](../architecture.md).
2. **Where, what, when, how fast** order of questions (LaundroKart) as a progress label in booking (LaundryMate), without adding mandatory steps.
3. **"Back by <date>" on the active-order card and Book again chips on Home** (LaundroKart). IronDost already surfaces the active order first; the Back-by line and chips are small additions.
4. **Audience tabs** (Men, Women, Kids, Household) above item rows (LaundryMate, Fabrico, Tumbledry).
5. **Slot rows that say what they cost** (LaundryMate) instead of a surcharge buried in the total.
6. **A plain "keep your items ready" confirmation with Reschedule and Cancel** (Tumbledry, Fabrico), once reschedule exists.

## Things not to repeat

Competing accent colours; mixed pill and square buttons; label text on mid-tone brand fills; tiny caps labels on dark; prices or plan terms that differ between surfaces; a process carousel that makes the booking screen long; counters standing in for status.

## Sources

Listing pages and the saved images are indexed in [../screens/README.md](../screens/README.md). Per-app detail, with every claim tagged observed, claimed or inferred, is in [../competitors/tumbledry/teardown.md](../competitors/tumbledry/teardown.md), [../competitors/dhobilite/teardown.md](../competitors/dhobilite/teardown.md), [../competitors/fabrico/teardown.md](../competitors/fabrico/teardown.md) and [../competitors/market-listings.md](../competitors/market-listings.md). Palettes: `tumbledry.tokens.json`, `dhobilite.tokens.json`, `fabrico.tokens.json`, `laundrymate.tokens.json`, `laundrokart.tokens.json`, `irondost.light.tokens.json`, `irondost.dark.tokens.json`.
