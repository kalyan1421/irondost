# DhobiLite - public-source competitor teardown

Prepared for IronDost (Hyderabad, LB Nagar launch). Read on 2026-11-07. Public sources only: marketing site, store listings, one public YouTube walkthrough, store review lists. No login, no account, no form submitted, no booking or payment clicked.

Tags: OBSERVED = I saw it on a page or screenshot. CLAIMED = their copy says it, I did not see it in UI. INFERRED = my deduction, with the basis stated.

Process notes that affect trust in this file:
- I chose "Hyderabad" in the site's city picker to see city prices. Nothing was submitted. After that the site defaulted the locality to "Bandlaguda, Hyderabad" on the steam-ironing page.
- Some page facts (Hyderabad store list, FAQ answers, "On Our Radar" labels, franchise coverage list) were read through a text-fetch summariser, not by eye. These are marked "(fetch)".
- Colours are eyeballed from screenshots, never measured.

---

## A. Sources

| URL | What it gave | Date read |
|---|---|---|
| https://www.dhobilite.com/ | Hero claims, city picker, dry-clean / wash / prepaid tables, FAQ, 10-step process, testimonials, footer | 2026-11-07 |
| https://www.dhobilite.com/steam-ironing-services | Hero price chip, full per-piece steam-press table for Bandlaguda, Hyderabad | 2026-11-07 |
| https://www.dhobilite.com/laundry-services (also reached from /premium-laundry-rate, which redirected here) | Per-kg compare table (Delhi default), express +40%, packing types | 2026-11-07 |
| https://www.dhobilite.com/laundry-recharge-plans | Prepaid plan page (Delhi rates, placeholder "--" cells), 12-month validity | 2026-11-07 |
| https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad-bandlaguda | Hyderabad locality page: store address, nearby areas, Google reviews, FAQ list | 2026-11-07 |
| https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad | Hyderabad city page: 10 store localities (fetch) | 2026-11-07 |
| https://www.dhobilite.com/laundry-dryclean-locations | Store index; "On Our Radar" markers (fetch) | 2026-11-07 |
| https://www.dhobilite.com/laundry-franchise-in-hyderabad | Franchise pitch; LB Nagar in coverage list | 2026-11-07 |
| https://www.dhobilite.com/blog/laundry-for-working-professionals | Target-customer framing, Wash & Iron description (fetch) | 2026-11-07 |
| https://apps.apple.com/in/app/dhobilite-dry-clean-laundry/id1128126966 | Store stats, 7 screenshots, release notes, privacy label | 2026-11-07 |
| https://apps.apple.com/in/app/dhobilite-dry-clean-laundry/id1128126966?see-all=reviews | 10 App Store reviews | 2026-11-07 |
| https://itunes.apple.com/in/rss/customerreviews/id=1128126966/sortBy=mostRecent/json (and /us/) | Feed returned zero entries | 2026-11-07 |
| https://play.google.com/store/apps/details?id=com.dhobilite&hl=en_IN&gl=IN | Store stats, screenshots (same art as iOS), What's New, reviews dialog (Phone only; newest; 1/2/3-star filters) | 2026-11-07 |
| https://www.youtube.com/watch?v=Yj6duSR84w4 | Third-party Android screen recording, about Aug 2025, older light-theme app | 2026-11-07 |
| https://www.youtube.com/results?search_query=dhobilite+app+how+to+book | Found the walkthrough above; DhobiLite's own channel exists (2.01k subscribers) | 2026-11-07 |
| https://www.trustpilot.com/review/dhobilite.com | 404, no Trustpilot page for DhobiLite | 2026-11-07 |

Not found: MouthShut, Justdial pages (a web search returned none).

---

## B. Positioning and footprint

**Who they target.** OBSERVED (https://www.dhobilite.com/): "India's #1 Rated Laundry & Dry Cleaning Service", general urban households plus working professionals (https://www.dhobilite.com/blog/laundry-for-working-professionals, fetch). Premium and ethnic wear are pushed in copy (sarees, lehengas, sherwani, silk). Also sells a franchise model (retail partner from Rs 7 lakh) and consultancy, so the brand is half consumer service and half franchisor. CLAIMED: founded 2011 by IIT alumni, "since 2011".

**Scale claims (inconsistent).** OBSERVED hero: 89 cities, 194 outlets, 700K+ downloads, 4.5+ rating. Elsewhere on the site: 79+, 76, 75, 72+ cities and 175+, 168+ outlets. Counters: 88.4 L clothes washed, 9.4 L orders, 4.2 L satisfied families. All CLAIMED.

**Hyderabad presence.**
- City page exists: https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad (fetch). Franchise page says serving Hyderabad since 2021 (CLAIMED).
- 10 store localities listed (fetch): Kokapet, Bachupally, Banjara Hills, Vanasthalipuram, Miyapur, Kompally, Mokila, Kukatpally, Bandlaguda, Manikonda. Three have no map link and are labelled "On Our Radar" on https://www.dhobilite.com/laundry-dryclean-locations (Bachupally, Banjara Hills, Manikonda) - INFERRED not yet open.
- Bandlaguda store address OBSERVED: 19/77, NRR Square, Lower Ground Floor, H.No.4, Kismatpur Rd, Bandlaguda Jagir, Hyderabad 500086 (https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad-bandlaguda).

| Locality | On DhobiLite pages? | URL |
|---|---|---|
| Bandlaguda | Yes: store and locality page | https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad-bandlaguda |
| LB Nagar | Only as "nearby" in the Bandlaguda SEO text, and in the franchise coverage list ("Secunderabad, LB Nagar, Manikonda, Tolichowki"). No LB Nagar store or service page found | https://www.dhobilite.com/laundry-franchise-in-hyderabad |
| Kothapet | "Nearby" in Bandlaguda text only | https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad-bandlaguda |
| Dilsukhnagar | Not found on any page read | - |
| Saroornagar | Not found on any page read | - |

INFERRED: the nearest live stores to LB Nagar are Bandlaguda and Vanasthalipuram. I did not measure distances. Whether they actually serve LB Nagar addresses is not observable without entering an address in the app.

Content quality note (OBSERVED): the Bandlaguda page gives pincode 500068 in the article and 500086 in the address block. Dry-clean "Starts at --" cells render as placeholders on the locality page (browser view, 2026-11-07).

**Store stats (read 2026-11-07).**

| Field | App Store (India) | Google Play |
|---|---|---|
| Rating | 3.3 out of 5 | 4.9 |
| Count | 504 ratings | about 15K reviews (14.8K) |
| Installs band | not shown | 5L+ (500K+) |
| Last updated | v14.00.00, "24 Oct" (year not shown) | 29 Oct 2026 |
| Size | 5.4 MB | not shown |
| Age rating | 4+ | Rated for 3+ |
| Developer | Elite Dhobilite Laundry Private Limited | Elite Dhobilite Laundry Pvt Ltd |
| Other | iPhone only, free, English only, iOS 15.0+, Lifestyle, "Data Not Collected" | Lifestyle, "may collect location, personal info and 2 others", encrypted in transit, deletion on request |
| Subtitle / promo | "20% Off for new user" | "DryClean & Laundry, 85+ Cities, 200+ Stores, 30% discount on 1st Order" |

Source: https://apps.apple.com/in/app/dhobilite-dry-clean-laundry/id1128126966 and https://play.google.com/store/apps/details?id=com.dhobilite&hl=en_IN&gl=IN. Rating histogram on iOS (eyeballed): roughly half 5-star and about 40 percent 1-star, very little in between.

INFERRED: the 3.3 vs 4.9 gap and the template replies on Play (see features.csv) point to different review-solicitation behaviour per store.

---

## C. Visual system (reverse-engineered)

Basis: App Store screenshots 1-4 (current dark app, Sept 2026 state), the Aug 2025 Android recording (older light app), and the website. Sources: https://apps.apple.com/in/app/dhobilite-dry-clean-laundry/id1128126966, https://www.youtube.com/watch?v=Yj6duSR84w4, https://www.dhobilite.com/.

### Colour roles (all approx, eyeballed)

| Role | App (dark, current) | Website | Confidence |
|---|---|---|---|
| bg | near-black, ~#161616 | white #FFFFFF, with pale blue bands ~#EEF4FC | med |
| surface | dark grey cards ~#232323 | white cards on pale bands | med |
| border | hairline ~#3A3A3A; selected state = 1px orange outline | ~#E3E8F0 | low |
| text | white ~#FFFFFF | navy ~#14224A headings, grey ~#555 body | med |
| text-muted | ~#9A9A9A | ~#6B7280 | low |
| accent / brand | orange ~#FF9F1C (header blob, active tab, add-on chips, Max/Get tags) | orange ~#FFA31A (CTAs, table headers) | high |
| second accent | blue ~#3F86D8 for primary buttons (Place Order, Confirm, Add Comment, Share My Location) | blue ~#1D6FF2 for links, stats, secondary buttons | med |
| on-accent | white on blue; dark text on orange tags | white on orange | med |
| danger | red ~#E53935 ("Cancel") | - | med |
| success | green ~#2E9B3E (call button) | WhatsApp green outline | med |
| warning | not observed | not observed | - |
| offer / highlight | royal-blue promo banner ~#1E6FE8 with orange coupon tag | "MY25" orange pill on white chip | med |

Greys: about 4 in the app (bg, card, hairline, muted text). Gradients: not in app chrome; only inside promo banners and photographic store art. Store art uses pastel pink, blue and orange draped-fabric photography as backdrop. Brand mark: orange shirt glyph with a blue droplet.

Observation worth noting (OBSERVED): the brand colour is orange but the main buttons are blue. Two accents compete; the Back button on confirmation is a white pill (new) or black pill (old).

### Typography
- Category: clean sans-serif, neo-grotesque / humanist mix. Store-art headlines are heavy, tightly leaded, navy. Website headings are semi-bold grotesque; body regular. I do not claim a specific font; none is named by the listing or site.
- Hierarchy in app (eyeballed from screenshots): screen title bold ~16-18 pt in the orange header ("Order Confirmation"); section label semi-bold ~13-14 pt ("Choose a day for Pickup"); body ~11-12 pt; tab labels ALL CAPS ~8-9 pt; day cards use a large bold date number (~20 pt) over a tiny caps weekday. Prices on the website are bold and larger than item names, with the MRP struck through in grey-blue.
- Numerals: lining figures, appear proportional in app; the rupee symbol is set inline before the number (the app shows the symbol followed by "299 + Tax"; this file writes it as "Rs").

### Spacing rhythm
- Looks like a 4/8 base. Side gutters roughly 16 px in app. Card inner padding about 12-16 px. List/field row height about 40-44 px. Day cards are square-ish and equal width with 8 px gaps; slot cards are a 2x2 grid with 8 px gaps. Confidence: low-med (screenshots are small and scaled).

### Shape language
- Radii: day cards and slot cards about 10-12 px; chips (add-ons) about 10 px outlined; primary buttons: Place Order is a rounded rectangle (~6-8 px) while Back/Confirm are full pills - inconsistent in the same flow (OBSERVED screenshots 2 vs 3); content panel has large rounded top corners (~20 px) overlaying the promo banner; header on detail screens is an organic orange blob cut at lower right.
- Borders vs shadows: flat dark cards, no visible shadows; selection shown with orange outline and slight orange tint. Floating bell button has a subtle shadow. Website cards use soft large shadows (white on pale blue).
- Dividers: hairlines inside the summary card rows; no heavy separators.

### Texture / material
- App: flat dark, no grain, no pattern. Process cards use real photography (staff at machines, delivery handoff) in a horizontal carousel. Promo banners are illustrated/3D-ish (washing machine, basket, bottles).
- Store art: lifestyle device mockups (3D phone) over pastel fabric photography; infographic panels in white cards.
- Website: photography of staff and machines, line icons (black ~1.5 px stroke with a blue accent fill, duotone-ish) in stat tiles.
- Icons in app: small filled/outline mixed glyphs for add-ons (antiseptic bottle, leaf, softener bottle, drop), bottom-tab icons simple filled line style.
- Mascot / character: none; logo only.
- Motion hints (INFERRED from UI): carousel pagination dots on home banner, typed-text rotation of city names in website hero, sticky right-edge quick-nav, floating WhatsApp FAB.

### Dark mode
OBSERVED: the current app screenshots are dark throughout. The Aug 2025 recording shows a light version, so the dark look arrived with the redesign that Play's What's New calls "fresh, modern, more user-friendly app design". No in-app theme switch observed. Website is light only.

### Tone of voice in UI copy
Three adjectives: reassuring, promotional, plain-spoken. Paraphrased examples: "Leave your laundry with us, pickup at your door on your schedule"; "Pick a time that suits your day: morning, evening or night"; "Choose add-ons and we handle the rest". Slot cards carry mood captions (start your day fresh, convenient after work).

### Design critique (5 bullets)
1. Trust through process: the 10-step photo carousel inside the booking screens makes the back-end visible and reads trustworthy, but it also pushes the Place Order screen into a long, busy column (OBSERVED).
2. Feels part-premium, part-budget: dark UI and photographic cards look modern; heavy promo banners, coupon codes and a floating bell make it feel discount-led (OBSERVED, several codes: MY20, MY25, APP30).
3. Inconsistent system: orange brand vs blue buttons; pill vs rounded-rect buttons; white vs black secondary button across versions (OBSERVED).
4. Booking is a scheduler, not a shop: no items, no price, no cart. Clean and fast, but a Play reviewer asks for item selection and bill amount (INFERRED opacity risk).
5. Small, dense labels: all-caps 8-9 pt tab labels and tiny captions on dark surfaces are low contrast for older users (INFERRED from screenshots; no measurement).

---

## D. App layout

**Global navigation (OBSERVED, App Store screenshots 1-4):** bottom tab bar, 5 tabs in this order: SCHEDULE, MY ORDERS, PREPAID, RATE LIST, ACCOUNT. Active tab orange. No drawer seen. A circular orange bell button floats bottom-right on every screen. Header on detail screens: orange blob with title and logo.

### Screen inventory

Surface key: App (current) = App Store screenshots of the current dark app; App (old) = Aug 2025 YouTube recording of the previous light app; Web = dhobilite.com.

| ID | Screen | Where seen | Layout top to bottom | Key components | States seen | Tag |
|---|---|---|---|---|---|---|
| DL-S01 | Home / Schedule Pickup (App, current) | https://apps.apple.com/in/app/dhobilite-dry-clean-laundry/id1128126966 screenshot 1 of 7 | Blue promo carousel (MY20 20% banner) > rounded panel with orange "Schedule Pickup" tag > Address (label + "Nearest Store >") > address card with pencil > "Choose a day for Pickup" > 3 day cards > Place Order > "Our 10-Step Cleaning Process" photo carousel > tab bar | Promo banner with dots, address card, day cards, blue button, process cards, bell FAB | Filled, no day selected | OBSERVED |
| DL-S02 | Schedule: day + time window + coupon (App, current) | same, screenshot 2 of 7 | Tag > Address > day cards (Tomorrow selected) > "Choose preferred Pickup Time" 2x2 grid > Coupon field > Place Order > T&C checkbox > process carousel | Selectable slot cards with icon and caption (Morning ticked), coupon input, checkbox | Selected (Tomorrow, Morning) | OBSERVED |
| DL-S03 | Order Confirmation + add-ons (App, current) | same, screenshot 3 of 7 | Orange blob header (Back, title, logo) > summary card (Pickup Date, Time Slot, coupon status, Compulsory Min Order Rs 299 + Tax) > "Add On Services" 4 chips > Back (white pill) and Confirm (blue pill) > process carousel | Key-value card, outlined orange icon chips, 2 pill buttons | Filled, "No Coupon Applied" | OBSERVED |
| DL-S04 | Active Orders / tracking (App, current) | same, screenshot 4 of 7 | Orange blob header "Active Orders" > order card: Order # with edit, red Cancel > 7-icon stepper > "OTP for Minimum Order" chip > Pickup Date > Runner Assigned (call button) > Coupon > Order Comment + Add Comment > Share My Location > inspection note | Stepper rail, outlined chip, green call button, full-width blue button | "Runner not yet assigned", first step active | OBSERVED |
| DL-S05 | Process infographic steps 1-5 (store art, not app UI) | same, screenshot 5 of 7 | Title > five white photo cards (Dirty Clothes to Preprocessing) | Numbered pills, photos | Static | OBSERVED |
| DL-S06 | Process infographic steps 6-10 (store art) | same, screenshot 6 of 7 | Title > five cards (Processing to Happy Customer) | Same | Static | OBSERVED |
| DL-S07 | Prepaid plans infographic (store art; in-app Prepaid tab not seen) | same, screenshot 7 of 7 | Title > five dark plan rows with orange left bar and price | Small Rs 1,399 / Medium Rs 2,199 / Big Rs 5,555 / Jumbo Rs 11,999 / Super Jumbo Rs 14,999, dry-clean discount 10/15/20/23/27 percent | Static | OBSERVED |
| DL-S08 | Home / Schedule (App, old light) | https://www.youtube.com/watch?v=Yj6duSR84w4 | Rotating orange/blue promo banner > "Schedule Pickup" tag > Address (Sector 75 Noida) > radio rows Today/Tomorrow/Day After Tomorrow > Place Order | Radio list, banner carousel (franchise, 666/999 offers, MY20) | Nothing selected | OBSERVED |
| DL-S09 | Slot picker + coupon (App, old light) | same | Address > day radios > "Choose preferred Pickup Time" 4 radios (09-11, 11-01, 04-06, 07-09) > Coupon Code field > Place Order > T&C checkbox | Radios, text field | Day Tomorrow and 09-11 chosen | OBSERVED |
| DL-S10 | Order Confirmation (App, old light) | same | Header blob > Pickup Date, Time Slot, coupon, Compulsory Min Order Rs 299 + Tax > Add On Services checkboxes > Back (black pill) and Confirm (blue pill) | Checkbox add-ons | Unchecked | OBSERVED |
| DL-S11 | Coupons / Referral (App, old light) | same | Referral code block with Invite Now > "Coupons for Me" ticket cards (APP30, WIN21) | Ticket-style cards: code, Get/Max tags, validity, service, min order | Filled | OBSERVED |
| DL-S12 | Active Orders (App, old light) | same | Header > Order #, Cancel > 7-icon stepper > OTP for Minimum Order > Pickup Date > Runner > Coupon with Apply > comment > Share My Location > note | Same as DL-S04 | "Runner not yet assigned" | OBSERVED |
| DL-S13 | Web home hero and lead form | https://www.dhobilite.com/ | Header (logo, location, nav, phone, Request Call Back) > hero (offer chip, H1, typed city, Book a Service, Chat on WhatsApp, 4 stat tiles) > product image > "Pickup - Absolutely Free" form (Location, Name, Mobile Number, Address, Book Pickup Now) | Form fields not filled | Default | OBSERVED |
| DL-S14 | Web city picker modal | same | Popular Cities (8 icon tiles) > All Cities A-Z grid | Modal with close X | Open | OBSERVED |
| DL-S15 | Web price tabs: Dry Clean | same, after choosing Hyderabad | Tabs (Dry Clean Rates, Wash Rates, Prepaid Plans) > carousel of category tables with arrows > View Full List | Orange-header tables, strike-through MRP | Filled | OBSERVED |
| DL-S16 | Web price tabs: Wash and Prepaid | same | Per-kg cards and plan cards (Small to Jumbo, Recommended badge) | Cards | Wash and Prepaid panels were blank for several seconds before rendering (loading state) | OBSERVED |
| DL-S17 | Web steam press rate page | https://www.dhobilite.com/steam-ironing-services | Hero with price chip > locality dropdown > 4 columns Gents, Ladies, Kids, Home Linen > search box | Dense item lists, strike-through MRP | Filled | OBSERVED |
| DL-S18 | Web laundry compare table | https://www.dhobilite.com/laundry-services | Hero > 7 service cards > 5-column compare table (process, cleaning agent, service time, best for, regular and MY25 rate, packing, express) | Compare table | Filled (Delhi default) | OBSERVED |
| DL-S19 | Web Bandlaguda locality page | https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad-bandlaguda | Hero with Google rating > address and map > price tabs with "--" placeholders > long SEO article > store carousel > Google reviews > FAQ accordion | Map, review cards | Placeholders in price cells | OBSERVED |
| DL-S20 | Web prepaid plans page | https://www.dhobilite.com/laundry-recharge-plans | Hero > plan comparison table > how it works > benefits > FAQ | Table cells show "--" | Placeholder state | OBSERVED |

### Not observed (no ID assigned)
- First-open / onboarding screens: not observed.
- Login (phone + OTP) screens: not observed; only CLAIMED in listing copy.
- Service / item selection and Rate List tab contents: not observed (tab label only).
- Cart / basket: none seen; flow appears to have no cart (INFERRED).
- Payment / checkout payment sheet: not observed.
- Order history list (past orders) and invoices: not observed.
- In-app Prepaid tab and wallet balance: not observed (marketing art only).
- Account / profile / support screens: not observed.
- Rating / feedback after delivery: not observed.
- Empty and error states in the app: not observed.

---

## E. Core flow

Numbered from open to confirmed order. O = OBSERVED, I = INFERRED, C = CLAIMED.

1. Install and open the app (C: store listing; O: listing page).
2. Enter mobile number, receive OTP, no password (C: store copy "OTP login"; screens not observed). Login is demanded before booking (I: from listing How It Works and review of forced registration).
3. Serviceability: no pin-code step observed. A review reports "registers first, then says not in serviceable zone" (I: Play 2-star, 1 Oct 2025). Address card has "Nearest Store >" (O). Website uses a city picker and, on rate pages, a locality dropdown (O).
4. Land on SCHEDULE tab with saved address (O: S01). Optionally edit address (pencil).
5. Tap a day: Today, Tomorrow or Day after tomorrow (O: S01-S02). Only three days ahead.
6. Tap one of four pickup windows (O: S02): Morning 9-11, Afternoon 11-1, Evening 4-6, Night 6-8.
7. Optional: type coupon (O).
8. Tick Terms (O; pre-ticked in older version).
9. Tap Place Order (O).
10. Confirmation screen: summary and compulsory minimum order Rs 299 + tax; optional add-ons Antiseptic, Neutralizer, Softener, Emulsifier; tap Confirm (O: S03).
11. Order appears under Active Orders with 7-step stepper, "runner not yet assigned", Share My Location (O: S04).
12. Runner collects; garments are inspected; an SMS is sent if an issue is found at inspection (O note on S04; C for the rest of the 10-step process).
13. Delivery in about 48 hours for standard (C: listing, FAQ). Pay online via "Tap to Pay" or cash/UPI/card (C; screen not observed). Invoice in app (C).

**Tap count on happy path (after login and with address saved):** day, slot, Place Order, Confirm = 4 taps. With coupon or add-ons 5-7. If the current design pre-selects Tomorrow and Morning (S02 shows both selected, possibly a demo state) the minimum is 2. Steps 1-3 and 13 are INFERRED or CLAIMED; steps 4-11 are OBSERVED.

| Question | Answer | Tag |
|---|---|---|
| Item model | Booking has no items. Laundry priced per kg, dry clean and steam press per piece, sofa per seat, carpet per sq ft. Items counted or weighed after pickup (I: no item screen exists before confirm) | O / I |
| How ironing is priced | Standalone steam press per piece (shirt Rs 50 list, Rs 38 with MY25, in Bandlaguda), or bundled into per-kg Wash & Iron (Hyderabad Rs 144/kg list, Rs 108/kg with MY25) | O |
| Express vs standard | Standard 2-3 days (48 hours in listing). Express 12 hours at +40 percent on laundry. Same-day dry clean "subject to availability". Steam ironing chip says 24-hour turnaround | O / C |
| Slot model | Date strip of 3 days; 4 fixed windows (Morning, Afternoon, Evening, Night). Same-day shown as "Today" (O). Reviews say windows are often missed (Play 3-star 27 Sep 2026: pickup never done within the selected window) | O |
| Payment methods | Cash, UPI, credit and debit cards (C). "Tap to Pay" online, discount on online payment (C) | C |
| Minimum order | Rs 299 + tax shown in app confirmation (O). Site: varies by location, lower for first order, sent by SMS (C) | O / C |
| Delivery charge | Free pickup and delivery when minimum met (C; app listing "no extra charges") | C |
| Tracking granularity | 7-step icon stepper in app (O); 10-step process in marketing (O). Reviews: tracking shows wrong dates (Play 1-star 19 Jul 2026) | O |
| Post-delivery | Rating prompt not observed. Re-order not observed. 7-day satisfaction guarantee and reimbursement up to 3x processing cost for prepaid accounts (C) | C |
| Support channels | Phone 8800414848, WhatsApp, email, Request Call Back (O). "AI agent bot" in Play release notes (C). Reviews say WhatsApp bot and unanswered phone (Apple 22 Jun 2025) | O / C |

---

## F. Pricing (publicly listed)

Read 2026-11-07. Prices are city- and locality-specific: Wash & Iron is Rs 170/kg list in the Delhi table and Rs 144/kg in the Hyderabad view of the home page. All shown with GST included per page footnotes. "MY25" = first-order offer price (25 percent off). Regular = list price.

### Steam ironing per piece, Bandlaguda, Hyderabad (https://www.dhobilite.com/steam-ironing-services)

| Item | Regular | MY25 first order |
|---|---|---|
| Shirt | Rs 50 | Rs 38 |
| T Shirt | Rs 50 | Rs 38 |
| Shirt Branded | Rs 70 | Rs 53 |
| Trouser / Pant | Rs 70 | Rs 53 |
| Jeans | Rs 70 | Rs 53 |
| Coat | Rs 139 | Rs 104 |
| Jacket Full | Rs 139 | Rs 104 |
| Waist Coat | Rs 99 | Rs 74 |
| Saree - R (regular) | Rs 119 | Rs 89 |
| Saree - M | Rs 229 | Rs 172 |
| Saree Roll Polish Press | Rs 139 | Rs 104 |
| Lehnga / Ghagra - R | Rs 339 | Rs 254 |
| Kurta / Kameez | Rs 70 | Rs 53 |
| Gents Sherwani - R | Rs 299 | Rs 224 |
| Bedsheet - S | Rs 79 | Rs 59 |
| Bedsheet - D | Rs 129 | Rs 97 |
| Blanket - D | Rs 249 | Rs 187 |
| Pillow Cover | Rs 39 | Rs 29 |

Hero chip on the same page: "Starts from Rs 38*/pc". No "suit" row; Coat plus Trouser is the nearest.

### Wash / laundry per kg

| Service | Delhi regular | Delhi MY25 | Hyderabad regular | Hyderabad MY25 | Source |
|---|---|---|---|---|---|
| Wash Only / Wash & Fold | Rs 100 | Rs 75 | Rs 100 | Rs 75 | https://www.dhobilite.com/laundry-services ; https://www.dhobilite.com/ |
| Organic Wash | Rs 135 | Rs 101 | Rs 129 | Rs 97 | same |
| Wash & Iron | Rs 170 | Rs 127 | Rs 144 | Rs 108 | same |
| Organic Laundry | Rs 203 | Rs 152 | Rs 190 | Rs 143 | same |
| Premium Laundry | Rs 216 | Rs 162 | Rs 216 | Rs 162 | same |
| Curtain Wash | - | - | Rs 216 | Rs 162 | home |
| Woolen Wash | - | - | Rs 197 | Rs 148 | home |

City attribution: Delhi is INFERRED from the page's city dropdown showing Delhi; Hyderabad is OBSERVED on the home page after choosing Hyderabad. Bandlaguda locality page shows Rs 49*/kg ("valid with MY25 on first order"), regular "--" (placeholder; I could not reconcile it with the Rs 75 above).

### Dry clean per piece (home page, Hyderabad selected; same values when the picker briefly showed Delhi)

| Item | MRP | MY25 |
|---|---|---|
| Shirt | Rs 119 | Rs 89 |
| T Shirt | Rs 109 | Rs 82 |
| Trouser / Pant | Rs 139 | Rs 104 |
| Jeans | Rs 139 | Rs 104 |
| Dress | Rs 299 | Rs 224 |
| Ladies Top | Rs 159 | Rs 119 |
| Saree - R | Rs 179 | Rs 134 |
| Kurta / Kameez | Rs 159 | Rs 119 |
| Coat | Rs 309 | Rs 232 |
| Jacket Full | Rs 329 | Rs 247 |
| Anarkali Suit - R | Rs 359 | Rs 269 |
| Bedsheet - S | Rs 189 | Rs 142 |
| Bedsheet - D | Rs 289 | Rs 217 |
| Blanket - D | Rs 499 | Rs 374 |

Source: https://www.dhobilite.com/ (accessibility text of the table). Organic dry clean runs about 1.5x (shirt Rs 179 MRP, Rs 134 MY25). Shoes: sneakers Rs 389 (MY25), slippers Rs 97; sofa Rs 399 per seat, carpet Rs 35 per sq ft on the same page. Store listing copy says "Dry Cleaning (from Rs 89)" and "Shoe Cleaning (from Rs 399)" (C).

### Prepaid plans

| Surface | Plans |
|---|---|
| Home (Hyderabad selected) | Small Rs 1,399 (laundry Rs 139/kg, dry clean 10 percent off), Medium Rs 2,199 (Rs 135/kg, 15), Big Rs 3,499 recommended (Rs 132/kg, 20), Jumbo Rs 6,399 (Rs 130/kg, 25) |
| Plans page (Delhi) | Bachelor Rs 1,399, Couple Rs 2,199, Family Rs 5,555 best value, Jumbo Rs 11,999 |
| App Store art | Small 1,399, Medium 2,199, Big 5,555, Jumbo 11,999, Super Jumbo 14,999 |

Prices for the same named plan differ by surface. Validity: 12 months (plans page) vs no expiry (home FAQ). Both OBSERVED.

---

## G. Components list

| Component | Variants seen | Where |
|---|---|---|
| Buttons | Blue rounded-rect primary (Place Order); blue pill (Confirm); white pill and black pill secondary (Back); full-width blue (Share My Location); small blue (Add Comment, Apply); orange pill (website CTAs); outlined green WhatsApp | App, Web |
| Chips | Outlined orange icon chips (add-ons); coupon pill "MY25"; "Recommended" badge; Max / Get tags on coupons; "OTP for Minimum Order" outlined chip; "Schedule Pickup" orange tag | App, Web |
| Cards | Day card (3); slot card (2x2); summary key-value card; order card; process photo card; plan card; ticket coupon card; stat tile; service card | App, Web |
| Sheets / modals | Rounded top panel over banner; city picker modal; reviews dialog on stores | App, Web |
| Steppers | 7-icon order progress rail; none for quantity (no item counter seen) | App |
| Banners | Promo carousel with dots (discount, franchise, 666/999 offers); orange blob page header | App |
| Status pills | Not seen as text pills; progress shown by stepper only | App |
| Navigation | 5-tab bottom bar; sticky right-edge pill group; Back to top; floating bell; floating WhatsApp | App, Web |
| Form fields | Dark filled input with label; underlined text field with edit pencil | App |
| Tables | Orange-header price tables; compare table with highlighted Premium column | Web |

---

## H. Strengths and weaknesses vs a new hyperlocal entrant

### Strengths (evidence-backed)
1. Brand and reach: about 15K Play reviews, 5L+ installs, 4.9 on Play, press logos (https://play.google.com/store/apps/details?id=com.dhobilite&hl=en_IN&gl=IN; C for press).
2. Very wide, structured catalogue: roughly 140 steam-press SKUs (my approximate count) with tiers and POLISH finishes, plus shoes, bags, sofa, carpet, curtains (https://www.dhobilite.com/steam-ironing-services).
3. Booking is short: schedule-first flow with day cards and four windows; about 4 taps once logged in (S01-S03).
4. Process story and guarantees: 10-step photo process in app and site, 7-day satisfaction promise, packing options by tier (C/O; https://www.dhobilite.com/).
5. Retention machinery: prepaid plans with 10-27 percent dry-clean discounts, referral codes, coupon wallet, template replies that hand out codes (O; https://www.dhobilite.com/laundry-recharge-plans, https://www.youtube.com/watch?v=Yj6duSR84w4).

### Weaknesses
1. Delivery reliability in recent reviews: "more than 8 days" (Play 1-star, 2 Nov 2026), "5+ days" and a missing piece (31 Oct 2026), misplaced formals (24 Oct 2026). Many 1-star reviews in Aug-Nov 2026 cite lost items and unresolved follow-ups (https://play.google.com/store/apps/details?id=com.dhobilite&hl=en_IN&gl=IN).
2. Weak support loop: bots, unanswered calls, resolution "senior will call you back" (Apple 22 Jun 2025; Play 18 Aug 2026). Developer reply is a templated apology with a coupon, not a fix (O).
3. Thin and unproven Hyderabad east-side coverage: no LB Nagar, Dilsukhnagar, Kothapet, Saroornagar service page; nearest are Bandlaguda and Vanasthalipuram; 3 of 10 Hyderabad localities marked "On Our Radar" (https://www.dhobilite.com/laundry-dryclean-locations, fetch). Locality page shows blank price placeholders (https://www.dhobilite.com/laundry-and-dry-cleaning-hyderabad-bandlaguda).
4. Price opacity: no estimate or bill before confirm, minimum order "varies by location", promo-versus-actual disputes ("20 percent promised, 5 percent given", Play 2-star 28 Jun 2026), plan prices differ by surface, and +40 percent for 12-hour express.
5. Standard speed is slow for ironing-only needs (48 hours to 2-3 days versus a hyperlocal press shop's same-day), English-only app, iOS rating 3.3, and signs of review gaming (1-star reviews with positive text; "dont fall for paid reviews", Play 1-star 18 Aug 2026).

---

## I. Limits

- Never logged in. No onboarding, login, Rate List, Prepaid tab, Account, payment, order history, rating or empty/error states seen. Everything about those is CLAIMED or INFERRED.
- In-app visuals come from 4 current-app screenshots (store art, curated, Sept 2026 order data) and one Aug 2025 third-party recording of the older light app. Whether the live app matches the store art is not verified.
- Play reviews were read in the "Phone" filter only; "newest", 1-star, 2-star, 3-star lists were captured, 4-star list not captured. Only star ratings on filtered lists are certain; I read stars visually for 4 unfiltered reviews. Developer replies were not copied into reviews.csv.
- Apple RSS feed returned zero entries for India and US; the on-page list of 10 reviews was used instead.
- Trustpilot has no DhobiLite page; MouthShut, Justdial, Google Maps listing reviews not read. The three Google reviews come from the site's own widget (could be curated).
- Several facts were read through a text-fetch summariser (store list, FAQ answers, franchise list, blog). They are marked (fetch) and should be spot-checked.
- Price pages show city-dependent values and some "--" placeholders; which locality default a visitor sees depends on cookie/selection. I did not verify prices for LB Nagar addresses.
- Hex values and sizes are eyeballed; no measurement.
- The Play "Trailer" video and DhobiLite's own YouTube videos were not watched. The only walkthrough watched is third-party and dated about Aug 2025.
- The Prepaid, Rate List and Account tabs exist by label only; I cannot say whether they contain Hyderabad-specific content.
