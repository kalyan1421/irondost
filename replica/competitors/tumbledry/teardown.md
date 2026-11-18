# Tumbledry teardown (public sources only)

Prepared for IronDost (Hyderabad, LB Nagar launch). All reads on 2026-11-07. No login, no forms, no downloads, no JS/CSS/network inspection.
Tags: OBSERVED = seen on screen; CLAIMED = their copy or a customer's report that I did not see in the UI; INFERRED = my deduction (reason given).
Colours/spacing are eyeballed from compressed screenshots and a screen-recorded video, so every hex is "approx, eyeballed".

## A. Sources table

| URL | What it gave | Date read |
|---|---|---|
| https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539 | iOS listing stats, description, 8 screenshots (carousel), 4 reviews | 2026-11-07 |
| https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539?see-all=reviews | 10 India-storefront reviews, star ratings read from accessibility labels | 2026-11-07 |
| https://itunes.apple.com/in/rss/customerreviews/id=1481554539/sortBy=mostRecent/json | Feed header only, 0 entries (India) | 2026-11-07 |
| https://itunes.apple.com/us/rss/customerreviews/id=1481554539/sortBy=mostRecent/json | 9 reviews (US storefront feed, many from Indian users) | 2026-11-07 |
| https://play.google.com/store/apps/details?id=com.quickdrycleaning.tumbledry&hl=en_IN&gl=IN | Play stats, 8 screenshots, "All reviews" dialog (Newest, 1/2/3-star filters), 77 reviews captured | 2026-11-07 |
| https://www.trustpilot.com/review/tumbledry.in (+ 14 individual /reviews/ URLs listed in reviews.csv) | TrustScore 2.0 (14 reviews, unclaimed profile); full text of each review | 2026-11-07 |
| https://tumbledry.in/ | Marketing home: positioning, delivery terms, 6-stage process, stats, nav | 2026-11-07 |
| https://tumbledry.in/dry-cleaning-prices-near-me/ | Pricing page: city dropdown + "Download Price List" (not downloaded), membership tiers, express text | 2026-11-07 |
| https://tumbledry.in/?p=179800 (redirects to https://tumbledry.in/best-laundry-in-saroornagar-hyderabad/) | Saroornagar landing page: service table, nearest-store card (Kharmanghat), app composite image | 2026-11-07 |
| https://tumbledry.in/best-laundry-in-l-b-nagar-hyderabad/ | LB Nagar page: nearest-store card (Vanasthalipuram), FAQ incl. minimum order 350 (expanded in browser) | 2026-11-07 |
| https://tumbledry.in/best-laundry-in-dilsukhnagar-hyderabad/ | Dilsukhnagar page; store card seen in browser is empty (name only, address ", ,", rating "4 ()") | 2026-11-07 |
| https://tumbledry.in/best-laundry-in-kothapet-hyderabad/ | Kothapet page exists; read via WebFetch text extract only (no store address) | 2026-11-07 |
| https://tumbledry.in/best-steam-ironing-in-dilsukhnagar-hyderabad/ | Steam-ironing local page, read via WebFetch text extract (TAT 24h, 1.5X express) | 2026-11-07 |
| https://tumbledry.in/best-dry-clean-shop-in-hyderabad/ | Hyderabad store list (49 store cards in first 100k of 129k chars), via WebFetch | 2026-11-07 |
| https://tumbledry.in/store-locations/tumbledry-dry-clean-laundry-store-vanasthalipuram-hyderabad/ | Vanasthalipuram store page (address, 9am-9pm, FAQs), via WebFetch | 2026-11-07 |
| https://tumbledry.in/dry-cleaning-cost-in-india-what-affects-pricing/ (also ?p=241161) | Tumbledry blog price-range table dated Jan 24, 2026 (table verified in browser) | 2026-11-07 |
| https://www.youtube.com/watch?v=taOeVxhqn-4 | Third-party screen recording ("Techie Bon", 13:07, ~2 months old): real Android app v16.0.8 (446) screens | 2026-11-07 |
| https://www.youtube.com/watch?v=Iw0LMxWp2bw | Official 4:23 "Journey from Pickup to Delivery" (6 yrs old): opened, only a sponsored ad and intro seen, NOT used | 2026-11-07 |

## B. Positioning and footprint

**Who they target (CLAIMED, site/app copy):** broad urban and tier-2/3 households and working professionals; headline "India's Largest Dry Clean and Laundry Chain" (https://tumbledry.in/). Strength is premium/delicate care (designer wear, ethnic, woollens, shoes, leather, curtains, carpets, bridal), not everyday ironing. Steam Iron exists as a service tile and local SEO pages, but it is not the hero.

**Footprint claims (inconsistent across surfaces, all OBSERVED as text):**
- Website: 1600+ stores, 650+ cities, 2Cr+ orders, 10Cr+ garments, "80 Lac+ customers" (https://tumbledry.in/, pricing page).
- Play listing: "1500+ stores across 600+ cities", description says "30 Lac+ customers".
- iOS description: "15 Lac+ customers"; iOS screenshot 1: "1400+ stores, 600+ cities"; iOS screenshot 4: "30 lakh+"; iOS home screenshots: "20 lakhs+".
- Reading: the numbers are not synchronised between channels. INFERRED: marketing assets are updated per channel without a single source of truth.

**Store-led / franchise model (INFERRED):** nav has "Get Franchise" and "Store Locator" (https://tumbledry.in/); per-store pages show a store card with Google rating, Get Directions, Check Pricing, Call Now, WhatsApp; reviews refer to "Tumbledry's partner" (App Store review by Jatin2609, 12/12/2024), a "local store owner" taking payment on a personal QR code (Play, 26 Dec 2025) and "no control over their stores" (Play, 29 Oct 2026). Doorstep is a free pickup/delivery service run by the nearest store, not a separate hyperlocal fleet. Free delivery needs a minimum order of 350 after all discounts (OBSERVED: FAQ expanded at https://tumbledry.in/best-laundry-in-l-b-nagar-hyderabad/). A steam-ironing page says outside the coverage area you can drop clothes at the nearest store (CLAIMED, https://tumbledry.in/best-steam-ironing-in-dilsukhnagar-hyderabad/).

**Same software as other brands (OBSERVED):** both listings show a long "More by" list under the same developer (iOS developer "DC WEB SERVICES PRIVATE LIMITED", Play developer "Quick Dry Cleaning Software", copyright "(c) 2019 Quick Dry Cleaning Software") with sibling apps Fabrico, FABO, REVIVO, Washodry, Laundry Legend and others. INFERRED: Tumbledry's app is a white-label laundry-POS customer app, which explains the generic Material-style UI and the weak fit with franchise operations.

**Hyderabad presence (OBSERVED unless stated):**
- Saroornagar: https://tumbledry.in/?p=179800 -> https://tumbledry.in/best-laundry-in-saroornagar-hyderabad/ . Nearest-store card: "Tumbledry Laundry & Dry Clean KHARMANGHAT", H No 10-1-80/1, Ramdev Plaza, Besides UCO Bank, Hyderabad; Google 4.3 (95). Page states "Our prices vary at city level", free pickup and drop in 48 hours, express "Double charges".
- LB Nagar: https://tumbledry.in/best-laundry-in-l-b-nagar-hyderabad/ . Nearest-store card: Vanasthalipuram, Plot No18 M/P, Hill Colony, Near Panama Godown; Google 4.3 (160). So no store is listed in LB Nagar itself (the nearest card is Vanasthalipuram).
- Dilsukhnagar: https://tumbledry.in/best-laundry-in-dilsukhnagar-hyderabad/ . Store card is empty (see Sources). Also https://tumbledry.in/best-steam-ironing-in-dilsukhnagar-hyderabad/ , https://tumbledry.in/best-shoe-laundry-and-shoe-cleaning-in-dilsukhnagar-hyderabad/ and https://tumbledry.in/best-dry-cleaners-in-dilsukhnagar-hyderabad/ (the last two URLs from a search result, not opened).
- Kothapet: https://tumbledry.in/best-laundry-in-kothapet-hyderabad/ (exists; no store address; WebFetch only).
- Vanasthalipuram store page: https://tumbledry.in/store-locations/tumbledry-dry-clean-laundry-store-vanasthalipuram-hyderabad/ (9:00 AM-9:00 PM, open all days; "3 Days Delivery TAT"; WebFetch).
- Hyderabad store list: https://tumbledry.in/best-dry-clean-shop-in-hyderabad/ lists 49 cards (WebFetch of first 100k chars). Nearest to LB Nagar by name: Kharmanghat 4.3 (95), Vanasthalipuram 4.3 (160), Hayathnagar Khalsa 4.7 (43), Malakpet Extension 2.9 (36), Uppal 4.7 (229), Habsiguda 3.7 (84), Himayath Nagar 4.1 (176). Lowest-rated cards in the list: Nallagandla 1 (1), Gachibowli 2.1 (30) and 2.6 (105), Malakpet Extension 2.9 (36).
- Customer voice: Play 1-star, 3 Oct 2026: "very poor service from Himayat Nagar branch ... articles are long overdue" (reviews.csv).

**App store stats (OBSERVED, read 2026-11-07):**

| Field | iOS (apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539) | Google Play (com.quickdrycleaning.tumbledry) |
|---|---|---|
| Rating | 3.1 out of 5 | 4.3 (verified ratings) |
| Count | 1.5K ratings | 11.7K reviews (11.6K on rating block) |
| Installs | not shown on iOS | 5L+ (500,000+) |
| Last updated | "What's New: Fix Bugs", Version 10.0.6, "6 Oct" (year not shown on page) | 30 Sept 2026 |
| Size | 64.6 MB | not shown |
| Version | 10.0.6 | not shown (Android app screens in the video show "Version: 16.0.8 (446)") |
| Age rating | 9+ | Rated for 3+ |
| Developer | DC WEB SERVICES PRIVATE LIMITED | Quick Dry Cleaning Software |
| Other | Lifestyle chart No. 99; iOS 15.1+; English only; free; Apple Wallet supported | Lifestyle; Data safety: "No data shared with third parties", "No data collected", encrypted in transit, deletion on request |

Contradiction (OBSERVED): iOS privacy label says identifiers may be used to track you and are linked to you; Play says no data collected. The gap between iOS 3.1 and Play 4.3 is large; INFERRED: Play skews positive (the 20 newest Play reviews were 16 five-star, 3 one-star, 1 four-star, but the 1-star filter alone returned 20 reviews dated 2 Oct to 6 Nov 2026, so the stream is bimodal).

## C. Visual system (reverse-engineered)

Sources: iOS screenshots 6-8 of 8 and Play screenshots (https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539, https://play.google.com/store/apps/details?id=com.quickdrycleaning.tumbledry&hl=en_IN&gl=IN), real Android frames in https://www.youtube.com/watch?v=taOeVxhqn-4 , website https://tumbledry.in/ . Three visual dialects exist: (1) the in-app UI, (2) dark marketing creatives, (3) a pastel multi-colour website.

### Colour roles (approx, eyeballed)

| Role | Value | Confidence | Where |
|---|---|---|---|
| bg | #FFFFFF; alt page grey ~#F0F0F0 | high / med | app screens, feedback screen |
| surface | #FFFFFF cards and tiles; input/disabled grey ~#E4E4E4 | med | feedback textarea, selected tile fill |
| border | light lime ~#C8DC85 on service tiles; list divider ~#E6E6E6 | low / med | home tiles, price list |
| text | near-black ~#1C1C1C | high | headings, item names, prices |
| text-muted | mid grey ~#7A7A7A | med | helper copy |
| brand / accent | lime green ~#AED136 (status bar, header, drawer header, tab strips); logo green ~#A5CB38 with golden-yellow "dry" ~#F2B91C | med | all app screens, logo |
| primary action | amber yellow ~#FFC809 | med | Proceed, Confirm, Submit, Buy Now, Reschedule, Cancel |
| on-accent | white label on amber and on lime | high | INFERRED contrast about 1.6:1 on amber and 1.8:1 on lime (computed from eyeballed hex) |
| disabled | pale yellow ~#FFE48C (Android), light grey ~#DEDEDE (iOS creatives) | med | "Schedule Pickup" pill |
| danger | red notification badge ~#E53935 | med | bell badge |
| success | not observed in app; green tick ~#5DB65D in website comparison table | low | site only |
| warning | not observed | - | - |
| offer / highlight | crimson "20% OFF" numerals ~#B5123E on blush ~#F8E8EC panel; selected date amber ~#FFB800; navy ~#2A3E6B "Schedule your pickup" button in the slot creative | med | store creatives |

- Greys: about 5 neutrals (white, #F0F0F0, #E4E4E4, #7A7A7A, #1C1C1C) plus charcoal ~#222 canvas on dark creatives.
- Gradients: none seen in app UI or site; only photographic fades in banners. The logo is two-tone, not a gradient (med confidence).
- Website section bands rotate through pastel/earthy colours (all approx, low-med): lavender ~#A98BCB, dusty rose ~#D69A94, terracotta ~#C9724E, navy ~#3F4D6E, teal ~#17B5C9, cream ~#F4F5DB, blush ~#FBE9EA, grey hero ~#E6E6E6.

### Typography
- Wordmark "tumbledry" (with a diaeresis on the second e): lowercase geometric sans with rounded terminals; lime + yellow.
- App text: looks like the platform system sans (Roboto on the Android recording); INFERRED from the generic Material layouts and glyph shapes at low resolution. Hierarchy is flat: screen titles bold about 16-18 px on a ~360 px-wide frame, list item names bold ~14, helper labels ~11-12, buttons bold ~14.
- Prices: bold, right-aligned, "₹" prefix, no decimals except "₹287.50" on one shoe item. Package cards use very large light-weight numerals (₹2000, ₹2200).
- Marketing creatives: geometric sans mixing light and bold weights in one headline (Poppins-like look, not claimed to be that font).
- Website: bold, widely letter-spaced uppercase section headings in the band colour; body in a Helvetica/Arial-like sans; thin-weight oversized count-up numerals for stats.

### Spacing
- No clear 4/8 grid evidence; INFERRED Material default (8 dp) with low confidence.
- Price-list rows about 56-64 dp tall (eyeballed, low); left/right gutter about 16 dp; header block on lime with dropdown + search stacked with ~12 dp gaps; service tiles about 100 x 100 dp with ~10 dp gaps (low).

### Shape language
- Tiles: rounded rectangles (~8-10 dp) with 1 px light-green border; selected state is a grey fill, not a colour change.
- CTAs: two coexisting shapes. Home "Schedule Pickup" is a full pill; flow screens (Proceed, Confirm, Submit, Buy Now/Back, Call/Send) use full-width, square-cornered yellow bars docked to the bottom; Reschedule/Cancel/Go Back To Home are yellow rounded rectangles (~4-6 dp).
- Package cards: ~12 dp radius, 1 px pale-lime border, diagonal "SAVE ₹200" ribbon, pill label "SMART".
- Borders over shadows: no elevation or shadows observed in the app; hairline dividers between list rows. Website uses pill buttons and flat full-bleed colour bands.

### Texture / material feel
- Flat, Material-default feel; no glass, no grain, no illustration backgrounds in app.
- Imagery: stock photography banners (family with laundry basket, man in suit, tan brogues, bridal couple), not 3D, not illustration. A black delivery van with a lime swoosh is the one brand graphic.
- Icons: inconsistent. Service tiles use thin rose-coloured line icons inside a circle (shoe is teal); drawer uses solid lime glyphs; marketing tiles use black outline icons; site "services" list uses solid dusty-rose glyphs.
- No mascot. Motion hints: banner carousel with five dash indicators (active one yellow); website count-up counters; nothing else observed.
- Dark mode: not observed in the app. Dark charcoal is used only on marketing screenshot canvases.

### Tone of voice
Three adjectives: promotional, assertive, reassuring. Paraphrased examples: (1) "India's largest, world-class, impeccable care" superlatives on every surface; (2) "Please keep your items ready! Our expert will be on the way soon" friendly instruction on confirmation; (3) "Dear Customer, we value your feedback, write to us and we will get back" formal feedback prompt.

### Design critique (5 bullets)
1. Lime and amber give a fresh, friendly, budget-leaning identity; lime on white (wordmark, header glyphs) is low contrast and does not read premium.
2. Dialect drift: dark creatives, pastel multi-colour website and lime/amber app do not look like one brand; inside the app, pill and square CTAs, filled and outline icons are mixed.
3. White-on-amber buttons and the pale-yellow disabled pill have weak affordance and poor contrast (INFERRED from eyeballed colours).
4. Trust devices are strong on marketing surfaces (6-stage process, comparison table, per-store Google ratings, certifications) but the app itself shows no proof (no photos, no live status, no price breakdown), so it feels like a booking form rather than a trustworthy service.
5. The website is clutter-prone: a "To Place Your Order" WhatsApp/Pickup pair repeats after nearly every section, with a different colour per band; long SEO text blocks follow.

## D. App layout

**Global navigation (OBSERVED, Android v16.0.8 (446), https://www.youtube.com/watch?v=taOeVxhqn-4 at ~3:58, ~5:08, ~10:31):**
- Top app bar: hamburger (left), wordmark (centre), phone icon and bell with red count badge (right).
- Bottom tab bar, 4 tabs in order: Home, Orders, WhatsApp, Packages. Active tab shows a lime bar above the icon and a lime label.
- Left drawer: lime header with avatar and name; items in order: Home, Promotion & Offers, Request Pickup, My Requests, My Orders, Pay Now, Price List, Contact us, Settings, Logout; footer "Version: 16.0.8 (446)".
- Settings list: My Profile, Contact Us, About Us, Call Us, Share, Delete Account (~9:21).
- Older marketing composite (https://tumbledry.in/best-laundry-in-saroornagar-hyderabad/, "Online laundry service" section) shows a drawer with Home, Request Pickup, My Requests, My Orders, Pay Now, Price List, Feedback, About Us, Settings, Logout and a 5-icon bottom bar (home, search, plus, heart, profile). INFERRED: that bar is mock-up chrome or an older version; it conflicts with the real 4-tab bar.

### Screen inventory

Timestamps are positions in https://www.youtube.com/watch?v=taOeVxhqn-4 (call it "YT"). iOS listing = https://apps.apple.com/in/app/tumbledry-dry-clean-laundry/id1481554539 (8 screenshots); Play listing = https://play.google.com/store/apps/details?id=com.quickdrycleaning.tumbledry&hl=en_IN&gl=IN (8 screenshots).

| ID | Screen | Where seen | Layout top to bottom | Key components | States seen | Tag |
|---|---|---|---|---|---|---|
| TD-S01 | Home | iOS listing screenshots 6, 7, 8 of 8; YT ~3:58, ~4:03, ~10:22; Saroornagar page composite | Status bar (lime), app bar, auto-advancing banner (with "FLAT 20% OFF On First Order" overlay), "Select Service" label with yellow underline, horizontally scrolling service tiles, large "Schedule Pickup" pill, [iOS creative: grey strip "First choice of 20 lakhs+ customers"], bottom tabs; composite adds "My Open Orders" header | Banner carousel with 5 dashes, service tiles (Dry Clean, Wash And Steam Iron, Wash And Fold; iOS creatives also show Shoe Cleaning, Steam Iron), disabled CTA | Disabled CTA (no service selected); tile selected = grey fill | OBSERVED |
| TD-S02 | Service multi-select grid | YT ~6:16 | App bar, 2-column grid of 5 tiles (Dry Clean selected, Wash and Steam Iron, Wash and Fold, Shoe Cleaning, Steam Iron), yellow "Proceed" bar docked at bottom | Service tiles, bottom action bar | One tile selected | OBSERVED |
| TD-S03 | First-use info capture | YT ~4:18 | Lime full screen, centred prompt "Please enter your information", +91 phone field (flag), Name, Email, yellow "Submit" bar | Icon-led inputs on lime | Empty form only | OBSERVED (OTP step after it: not observed) |
| TD-S04 | Pickup address | YT ~4:33-4:37 | Back + title "Pickup Address", map with pin (Google Maps), address line + green "Change" button, "House / Flat / Block / Building", "Street, Society or Landmark", "Confirm" bar | Map, text fields | Pre-filled from GPS (Jadavpur, Kolkata in the recording) | OBSERVED |
| TD-S05 | Pickup date and slot picker | iOS listing screenshot 3 of 8; Play screenshot 4 of 8; Saroornagar composite (right phone) | App bar; horizontal date strip (selected date amber, one grey); slot grid of hourly windows 2:00-3:00 PM through 8:00-9:00 PM (iOS/Play creative) or 2-per-row windows 10:00-11:00 AM to 8:00-9:00 PM (composite); "Same Day Delivery" and "Express Delivery" icons; "Schedule Your Pickup" button (navy in creative, yellow in composite); van graphic "FREE PICK-UP & DELIVERY" | Date chips, slot cells | Selected date shown; selected slot not shown | OBSERVED (marketing creative, not a recorded session; date strip "Tue 26 Jul" implies the creative is from 2022, INFERRED) |
| TD-S06 | Pickup confirmed | YT ~6:30-6:35 | App bar; centred "PLEASE KEEP YOUR ITEMS READY!", "Our Laundry / Dryclean expert will be on his way soon!", date and window "02 Sep 2026, 3:00 PM - 5:00 PM", yellow Reschedule and Cancel, yellow "Go Back To Home" | Rounded yellow buttons | Filled | OBSERVED |
| TD-S07 | Cancel request | YT ~11:49 | Lime title bar "Cancel Request" + X; question; radio list (Not Interested in Services, Will Schedule again later, Others); yellow "Submit" bar | Radio list | One option selected | OBSERVED |
| TD-S08 | Navigation drawer | YT ~5:08, ~5:16 | Lime header (avatar, name, empty address block), 10 items, version footer | List with lime glyphs | Open | OBSERVED |
| TD-S09 | Orders tab | YT ~10:31 | App bar, lime tab strip PENDING / COMPLETED, 2x2 counter tiles (Orders 0, Processing 0, Due ₹0.00, Ready 0), list area, bottom tabs | Counter tiles | Empty: "No orders found" | OBSERVED |
| TD-S10 | Packages list | YT ~5:37-5:39 | App bar, tabs AVAILABLE / ACTIVE, 2x2 package cards (Smart2000 10%, Select3500 15%, Super5000 20%, Gold10000 30%; each "Price" and "Validity: Unlimited") | Package cards with ribbon | Active tab empty "No Active Packages"; Available filled | OBSERVED |
| TD-S11 | Package detail | YT ~5:42 | Large card art ("SMART, Recharge with ₹2000 & get ₹2200 worth of services, SAVE ₹200"), title "Smart2000: 10% Savings", terms, Price, Validity, bottom bar "Back / Buy Now" | Card art, split action bar | Filled | OBSERVED |
| TD-S12 | Payment gateway sheet | YT ~5:57 | Back arrow, merchant "TUMBLEDRY SOLUTIONS Pvt Ltd" + Paytm PG badge, "Select an option to pay ₹2,000", Credit/Debit Cards, UPI, Net Banking, EMI, footer "100% Secure Payments Powered by Paytm PG" | Third-party sheet | Filled | OBSERVED (seen for package purchase only) |
| TD-S13 | Price List | YT ~7:18, ~7:54, ~8:13, ~8:33-8:54 | Lime header: category dropdown (Dry Clean, Steam Iron, Shoe Cleaning, Laundry Service), search field, tab strip (MEN/WOMEN/HOUSEHOLD/OTHERS/KIDS/SHOES); rows of name + right-aligned price | List rows | Filled for several categories | OBSERVED |
| TD-S14 | Contact / feedback | YT ~9:12 | App bar, type dropdown ("Complaints"), textarea with prompt and 0/1000 counter, camera button, yellow bar "Call / Send" | Dropdown, textarea, photo attach | Empty | OBSERVED |
| TD-S15 | Settings | YT ~9:21 | List: My Profile, Contact Us, About Us, Call Us, Share, Delete Account | Icon list | Filled | OBSERVED |
| TD-S16 | First-open / onboarding | Not in listing screenshots or video sampled | - | - | - | not observed |
| TD-S17 | Login / OTP | S03 is the closest (+91, name, email); OTP screen | - | - | - | not observed |
| TD-S18 | Item selection / cart / basket | Booking flow shows services only; no item list before pickup | - | - | - | not observed (INFERRED: items are counted and priced by the store after pickup, from reviews) |
| TD-S19 | Checkout / order review | - | - | - | - | not observed (payment only seen for packages, S12) |
| TD-S20 | Order detail / tracking timeline | Only the counter tiles in S09 | - | - | - | not observed |
| TD-S21 | Promotion & Offers; refer-and-earn | Drawer label only; refer banner ("Refer and get Rs.100* off along with your friend") in older composite | - | - | - | CLAIMED (label and marketing only) |
| TD-S22 | Notifications; My Requests; My Profile; saved addresses | Bell icon, drawer labels only | - | - | - | not observed |
| TD-M01 | Marketing creatives (not UI): India map "1400+ stores 600+ cities", services tiles, quality icons, upholstery, ultra-hygienic laundry, luxury dry clean, shoe care | iOS listing screenshots 1, 2, 4, 5; Play screenshots 1, 2, 3, 5, 6, 7, 8 | Dark phone-frame art with headline above | - | - | OBSERVED |

## E. Core flow

Reconstructed happy path for a first-time booker (Android recording, see D). Steps 1-5 OBSERVED screens; order and tap counts are INFERRED where noted.

1. Install and open app. Home appears with banner and "Select Service" (OBSERVED, S01). Onboarding slides not observed.
2. Tap a service tile (Dry Clean / Wash And Steam Iron / Wash And Fold). 1 tap (OBSERVED tiles; selection behaviour INFERRED from the grey selected state and the disabled CTA).
3. Tap "Schedule Pickup". 1 tap (OBSERVED button; INFERRED that a Proceed step with the 5-service grid, S02, follows for multi-service selection).
4. First time only: "Please enter your information": phone, name, email, Submit. 1 tap + 3 fields (OBSERVED, S03). An OTP step was not observed; login is therefore demanded at the first pickup request, not at app open (INFERRED). A customer reports that you cannot browse services without logging in and cannot search nearby stores first (Play 1-2 star review, 14 Oct 2025; CLAIMED).
5. Pickup address: map pin pre-filled, type house/flat and street/landmark, tap Confirm. About 1 tap + 2 fields (OBSERVED, S04).
6. Choose date and slot. About 2 taps + the schedule button (creative only, S05; INFERRED).
7. Confirmation "Please keep your items ready" with a date and a time window such as 3:00 PM - 5:00 PM (OBSERVED, S06). Reschedule and Cancel are available here.

Tap count: about 8 taps + 5 text fields first time; about 6 taps returning (INFERRED). No payment step at booking (INFERRED: payment is only seen for packages and a "Pay Now" drawer item).

- **Serviceability / pin code:** No pin-code check seen. Address is a map pin + free text. Reviews say serviceability is decided after booking by the store: slot is changed "saying that it's not in our range" (Play, 10 May 2026; CLAIMED). Site pages route you to the nearest store card and say you can drop off at the nearest store if outside coverage (CLAIMED).
- **Item model:** services are chosen first, items later. Price list shows laundry per KG, dry clean per piece, steam iron per piece, shoes per shoe (left and right priced separately). Pickup person or store counts and prices items (CLAIMED by reviews: "pick up guy ... stated another price", iOS 07/02/2024; "invoice with the actual higher amount", Play 4 May 2026). Invoice is not viewable in app (Play 2-star, 15 Jun 2026; CLAIMED).
- **Ironing pricing:** In-app Price List (OBSERVED) has a "Steam Iron" category with per-piece prices and weight classes (Plain / Heavy / Very Heavy) and a "Wash and Steam Iron ₹130 per KG" laundry line; see F. Website gives no ironing numbers ("depend on the garment fabric, type"). Steam-press TAT 24 hours with 2-day delivery (CLAIMED, steam-ironing page).
- **Express vs standard:** Standard: laundry 48 h, dry clean 72 h, shoes 3-5 days (https://tumbledry.in/); Vanasthalipuram store page says 3 days; Saroornagar/LB Nagar/Kothapet say 48 h. Express: "1.5 times extra charges" (home page, steam-ironing page, Vanasthalipuram page) versus "Double charges" (pricing page, Saroornagar, LB Nagar, Dilsukhnagar, Kothapet). Same-day or next-day, "available for selected services". The two multipliers contradict each other (OBSERVED).
- **Slot model:** date strip + time windows (hourly in the creative; the confirmation shows a 2-hour window 3:00-5:00 PM). A customer says slots are re-assigned by the store (Play 10 Oct 2026, "why are you rescheduling every order"; CLAIMED).
- **Payment methods:** Paytm PG sheet with cards, UPI, net banking, EMI (OBSERVED, package purchase). "Pay Now" exists in the drawer. Customers say store owners may collect on a personal QR and the app keeps showing due (Play 26 Dec 2025; CLAIMED). Cash on delivery not observed.
- **Minimum order and delivery charge:** free pickup and delivery with minimum order value 350 after all discounts (OBSERVED, LB Nagar FAQ). A customer says returning clothes would cost ₹50 delivery (App Store, 17 Aug; CLAIMED).
- **Tracking granularity:** Orders tab shows only four counters (Orders, Processing, Due, Ready) split into Pending/Completed (OBSERVED). Reviews: status "not updated properly" (Play, 19 Jun 2026) and "still shows 'in progress'" after 6 days (App Store US feed, 28 Jan 2026). No rider map, no per-stage timeline seen.
- **Post-delivery:** feedback form with complaint type and photo (OBSERVED, S14); no star-rating prompt and no re-order button observed.
- **Support channels:** phone icon in the app bar, "Call Us", WhatsApp tab, Contact us form; website floating WhatsApp/call/app rail and numbers +91-7677250250, +91-9920506305 (store FAQ). Customers report hang-ups and unresolved escalations (reviews.csv).
- **In-store garment-care process:** communicated as a 6-stage process (Sorting & Inspection, Stain Treatment, Processing, Finishing, Quality Check, Packing; https://tumbledry.in/), a "Tumbledry vs Other" tick table, "live store" concept (CLAIMED), Hohenstein/Woolmark certified machinery (CLAIMED), and packing choice (folded, hanger, vacuum). One reviewer received garment photos on WhatsApp at pickup (App Store, 22/04/2023; CLAIMED).

## F. Pricing

Prices are city- and store-specific: "Our prices vary at city level" (Saroornagar page); "Laundry prices vary as per the actual service taken as well as the store location" (LB Nagar FAQ). The web only offers a downloadable per-city rate card (not downloaded here). No Hyderabad item price was publicly viewable on the web. The only item-level prices seen are the in-app Price List frames below, from a store in an unknown city (the same recording's address screen shows Jadavpur, Kolkata, so probably Kolkata; INFERRED, low confidence).

| Service / item | Price | Source and date | City |
|---|---|---|---|
| Wash and Fold | ₹90 per KG | YT ~8:54, 2026-11-07 (video ~Sep 2026) | not shown |
| Wash and Steam Iron | ₹130 per KG | YT ~8:54 | not shown |
| Steam iron: Kurta Plain / Kurta Very Heavy | ₹30 / ₹70 | YT ~8:34 | not shown |
| Steam iron: Salwar Plain / Salwar Heavy | ₹40 / ₹60 | YT ~8:34 | not shown |
| Steam iron: Dupatta / Heavy / Very Heavy | ₹20 / ₹30 / ₹50 | YT ~8:34 | not shown |
| Steam iron: Capri, Shorts, Jumper, Dangree | ₹40, ₹20, ₹50, ₹50 | YT ~8:33 | not shown |
| Steam iron: Frock Plain / Heavy / Very Heavy | ₹70 / ₹80 / ₹100 | YT ~8:33 | not shown |
| Steam iron: Handkerchief, Bath Robe, Muffler, Tie, Face Mask | ₹20, ₹60, ₹50, ₹20, ₹20 | YT ~8:40 | not shown |
| Steam iron: shirt, trouser, saree, bedsheet | not observed (list scrolled past) | - | - |
| Dry clean: Shirt / Shirt Silk / Shirt Woolen / T Shirt | ₹120 / ₹160 / ₹160 / ₹115 | YT ~7:18 | not shown |
| Dry clean: Pants / Jeans | ₹130 / ₹140 | YT ~7:18 | not shown |
| Dry clean: Blanket Single / Single 2 Ply / Double / Double 2 Ply | ₹400 / ₹500 / ₹500 / ₹630 | YT ~7:54 | not shown |
| Dry clean: Quilt Single / Double / Quilt Cover Single | ₹400 / ₹500 / ₹300 | YT ~7:54 | not shown |
| Dry clean: Soft Toy Small / Medium / Large / XL / Full Size | ₹200 / ₹330 / ₹460 / ₹600 / ₹780 | YT ~7:59 | not shown |
| Dry clean: Suit Case Small | ₹250 | YT ~7:59 | not shown |
| Shoe cleaning (per shoe): Suede Leather Shoes Left | ₹287.50 | YT ~8:13 | not shown |
| Shoe cleaning: Ankle / Mid / Knee length boot (each Left and Right) | ₹350 / ₹510 / ₹710 | YT ~8:13 | not shown |
| Dry clean, indicative nationwide ranges (blog, Jan 24, 2026): Shirt/Top ₹150-₹350 (regular cotton shirt ₹150-₹250); Trousers/Jeans ₹180-₹400; Blazer/Jacket ₹450-₹1,200; Suit 2-pc ₹700-₹1,500 (3-pc ₹1,200-₹2,000); Saree ₹800-₹3,000 (cotton ₹800-₹1,200, silk ₹1,500-₹3,000, designer ₹2,500+); Lehenga ₹2,000-₹8,000+; Woollen sweater ₹400-₹900; Curtains ₹500-₹1,500 per panel; Blanket/Comforter ₹800-₹2,500 | as listed | https://tumbledry.in/dry-cleaning-cost-in-india-what-affects-pricing/ , 2026-11-07 | none ("Prices may vary based on fabric type, city, stain condition, and service provider"); no ironing or bedsheet prices |
| Express surcharge | 1.5x (home, steam-ironing, Vanasthalipuram pages) or 2x (pricing page, Saroornagar, LB Nagar, Dilsukhnagar, Kothapet) | tumbledry.in pages, 2026-11-07 | all |
| Pickup and delivery | Free; minimum order 350 after all discounts | LB Nagar FAQ, 2026-11-07 | Hyderabad (page) |
| First order | Flat 20% off | tumbledry.in, 2026-11-07 | all |
| Website membership (https://tumbledry.in/dry-cleaning-prices-near-me/) | VALUE ₹2000 -> 10% off; PLUS ₹5000 -> 15% off; MAX ₹10000 -> 20% off; "Not Applicable On Laundry Services" in tiny print; no joining fee, no expiry, valid at all stores, cancel anytime for full balance refund (CLAIMED) | 2026-11-07 | all |
| In-app packages (YT ~5:39-5:42) | Smart2000: 10% (₹2000 for ₹2200 worth, high-res read); Select3500: 15% (card shows ₹3500 -> about ₹4100, low-res read); Super5000: 20% (₹5000 -> about ₹6250, low-res read); Gold10000: 30% (₹10000 -> about ₹14250, low-res read); validity "Unlimited" | 2026-11-07 | not shown |

Package schemes disagree across surfaces: the website says PLUS ₹5000 = 15%, the app says Super5000 = 20%, and a Trustpilot reviewer was sold a ₹3,500 package "with 25% discount" by customer care (https://www.trustpilot.com/reviews/6ab65277a058c5a35f28a65a). INFERRED: package terms are set per store or per campaign.

## G. Components list

- App bar: hamburger, centred wordmark, phone icon, bell with red numeric badge (S01).
- Bottom tab bar: 4 tabs with icon + label; active tab = lime bar + lime label.
- Navigation drawer: lime header (avatar, name), icon list, version footer.
- Banner carousel: full-bleed photo with overlay text and "FLAT 20% OFF" corner badge; 5 dash indicators.
- Service tile: bordered rounded rectangle with circular line icon; states: default, selected (grey fill). Horizontal scroller on home, 2-column grid on S02.
- Buttons: (a) pill "Schedule Pickup" (disabled pale yellow); (b) full-width square bottom bar (Proceed, Confirm, Submit, Buy Now); (c) split bar (Back / Buy Now, Call / Send); (d) yellow rounded buttons (Reschedule, Cancel, Go Back To Home); (e) green "Change" chip on address line.
- Lime header block holding a dropdown and search field (Price List); tab strips on lime (PENDING/COMPLETED, MEN/WOMEN/HOUSEHOLD/OTHERS/KIDS/SHOES, AVAILABLE/ACTIVE) with yellow underline on active.
- Counter tiles (Orders, Processing, Due, Ready): icon + label + value.
- List rows: bold name left, bold ₹ price right, hairline divider.
- Package card: pale-lime border, "SAVE ₹" ribbon, tier pill, large numerals; detail screen with terms.
- Radio list (cancel reasons). Textarea with counter. Icon-led inputs on lime (phone with flag, name, email). Map with address chip.
- Stepper (quantity +/-): not observed (no cart).
- Status pills: none; status is only the counter tiles. Empty states: plain centred text ("No orders found", "No Active Packages").
- Third-party payment sheet (Paytm PG).
- Web: floating left rail (WhatsApp green, call red, app-store blue), pill CTA pairs ("Chat On WhatsApp", "Schedule Free Pickup"), comparison table with tick/cross, FAQ accordion, review carousel, store card (rating, Get Directions, Check Pricing, Call Now, WhatsApp), city dropdown + "Download Price List", count-up stats.

## H. Strengths and weaknesses versus a new hyperlocal entrant

Strengths (evidence-backed):
1. Reach and recall: 1600+ stores claimed, Play 5L+ installs, 11.7K Play reviews (listing pages above); a new entrant cannot match walk-in fallback.
2. Category breadth and specialist care: dry clean, shoes, leather, curtains, carpets, bridal; shoe repair and leather colouring FAQs (https://tumbledry.in/). Positive Play reviews cite coats in 2 days via Express, 90% haldi stain removal, shoes cleaned well (reviews.csv).
3. Prepaid packages plus Paytm PG: 10-30% savings tiers in-app and an auto first-order 20% (OBSERVED, S10-S12).
4. Local SEO and multi-channel capture: a page per locality (Saroornagar, Dilsukhnagar, LB Nagar, Kothapet, plus ironing and shoe pages), floating WhatsApp/call rail, store cards with Google ratings and directions.
5. Process storytelling: 6-stage process, comparison table and certification badges give a concrete answer to "how do you care for my clothes" that a startup must also supply.

Weaknesses (evidence-backed):
1. Inconsistent franchise execution: Trustpilot 2.0 (13 of 14 one-star), iOS 3.1, 20 Play one-star reviews in five weeks (2 Oct-6 Nov 2026); late or missing delivery and "no control over their stores" (reviews.csv). Hyderabad store cards in the list range from 5.0 (small review counts) to 1.0 (one review).
2. Price opacity and inconsistency: no public item prices on the web (download only), express stated as 1.5x and 2x, rider quotes different from call-centre quotes, a Play review says ₹110 displayed as ₹11, invoice not visible in app (reviews.csv).
3. Thin app UX: one saved address, no wallet balance, no invoice, counters instead of a status timeline, call button reported broken, app not opening (Play, Oct-Nov 2025), login before browsing (reviews.csv); the app is a white-label product shared with other brands.
4. Serviceability and slot reliability: no pin-code check; slots "changed", "not in our range", pickups scheduled but nobody came (Play 15 Oct, 10 Oct, 26 May 2026).
5. Slow standard TAT for ironing/laundry (48 h laundry, 72 h dry clean, 24 h steam press + 2-day delivery) and a 350 minimum for free delivery; a hyperlocal ironing player can promise same-day windows and no minimum on a cheap per-piece menu. Support access is weak (hang-ups, unresolved escalations on Trustpilot and Play).

## I. Limits

- No logged-in states. Not seen: first-open onboarding, OTP, the date/slot screen in a live session, item/cart, order review, order detail/timeline, notifications, My Requests, My Profile, address book, offers, referral, Hindi/Telugu UI, dark mode.
- All real app UI comes from one third-party Android recording (version 16.0.8 (446), presenter likely in Kolkata, ~Sep 2026). iOS app (v10.0.6) UI is only known from marketing screenshots; Play screenshots are marketing creatives except the slot picker; the slot creative looks dated (INFERRED 2022). Differences between iOS/Android UI and between cities are possible.
- Video frames were sampled sparsely (about 40 frames); some intermediate screens (slot picker during a live flow, OTP) were not captured; the pickup confirmation's 2-hour window versus 1-hour slots is unexplained.
- Hex values, radii and dp values are eyeballed from compressed frames (low-med confidence); low-resolution package values for Select, Super and Gold tiers are approximate.
- Item prices are from an unknown-city store; no Hyderabad item price was visible. The downloadable rate card was deliberately not downloaded.
- Pages read through WebFetch text extraction (not visually): Kothapet page, steam-ironing page, Vanasthalipuram store page, Hyderabad store list (first 100k of 129k chars). The Dilsukhnagar card, Saroornagar card and LB Nagar FAQ were verified in the browser.
- Reviews: Apple India RSS returned 0 entries; US feed 9; India listing page 10. Star ratings for Play 1/2/3-star rows come from the filter used, 4/5 from the page's aria labels; one Play review (4 Nov 2026) is rated 5 stars but its text is negative (OBSERVED; cause unknown). Google Maps, MouthShut and Justdial were not collected.
- Counts of reviews and ratings are as of 2026-11-07 and change daily. The browser tab group was reset once mid-session, so my first tab was lost; the replacement tab was closed at the end.
