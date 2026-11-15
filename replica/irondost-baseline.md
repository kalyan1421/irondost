# IronDost baseline (the "clone" side of every comparison)

Date: 2026-11-07 · Branch `ops/launch-gaps` (working tree has uncommitted changes) · Evidence: the repo itself.
Every row below is something I read in code or in the repo's own docs, not something I ran. Where a fact comes from a doc rather than code, the doc is named.

## What IronDost is

Doorstep ironing and laundry for Hyderabad, launching around LB Nagar. A customer books a pickup, a delivery partner collects, the workshop processes, a partner delivers back. (`README.md`, `.agents/product-marketing.md`)

**Core loop (the thing a customer pays for):** pick items → see a server-calculated price → pick a pickup window and a return window → pay online or in cash → watch the order move to delivered.

## What exists today

| Area | Shipped (evidence) |
|---|---|
| Sign-in | Phone OTP via Firebase, plus Google sign-in. Customer is created on first sign-in. (`auth/phone_screen.dart`, `google_sign_in_button.dart`, README) |
| Contact number | Orders need a verified contact number; an "add number" screen blocks checkout when missing. (`add_phone_screen.dart`, `Routes.addPhone`) |
| Address and serviceability | Map pin, place search, saved addresses, address switcher. Service area = radius around a hub and/or a PIN-code allow-list, edited in admin. (`business_settings` in `schema.prisma`) |
| Catalogue | 3 categories (Ironing, Wash & Iron, Dry Cleaning) with per piece / pair / set / kg units, optional offer price, item search, admin-uploaded images, three bundled 3D service images. (`CatalogItem`, `ItemUnit`, `assets/services/`) |
| Pricing | Server-calculated quote; minimum order, delivery fee, free-delivery threshold, promo codes (percent or flat, caps, per-customer limits). (`BusinessSettings`, `Promotion`) |
| Scheduling | Separate pickup and delivery windows; 3 slots a day (Morning 7–11, Noon 11–16, Evening 16–20); minimum 20 h turnaround; booking cut-off 60 min before the slot ends; up to 30 days ahead. (`TimeSlot`, `BusinessSettings`) |
| Payment | Razorpay online, cash on delivery (staff record cash at delivery), pay-the-balance on an existing order, failed-payment recovery. (`payments/`, `Routes.orderPay`) |
| Tracking | 8-step status timeline, realtime over Socket.IO, FCM push, partner shown once assigned, overdue-estimate label instead of an invented ETA. (`OrderStatus`, `realtime.gateway.ts`) |
| After booking | Cancel until pickup, "Book again" on finished orders, items-and-bill screen, payment receipt, help/FAQ, notification inbox. |
| Offers | Offers tab, promo-code sheet, banner/promotion carousel from admin. |
| Operations | Admin console (orders, partners, catalogue, promotions, banners, settings, staff, app versions, audit log, refund-due list, staff alerts). Dispatch offers the leg to the nearest 3 available partners at once. (README, `staff-delivery-runbook.md`) |
| Platform | Flutter app, light and dark themes, bundled fonts, 200% text scaling tested at 320/390/430 dp, forced-update and paused-account screens. (`IMPLEMENTATION.md`) |

## What does not exist today (checked in code on 2026-11-07)

| Gap | How I checked |
|---|---|
| **Partner (driver) app** | README: `mobile/partner` "Not started"; `docs/staff-delivery-runbook.md`: "There is no partner (driver) app yet", staff move every order from the admin. No `mobile/` folder exists. |
| Express / same-day option | No express concept in `api/src` or `customer/lib` (only the Express web framework matches the word). |
| Rating or feedback after delivery | No rating UI or API; `grep` for rating/feedback in `customer/lib` finds only the word "review" in checkout. |
| Wallet, prepaid plans, subscriptions, referral, loyalty | No match in API; the "wallet" hits in the app are Razorpay wallet-app callbacks. |
| Telugu / Hindi | `supportedLocales` is `[Locale('en','IN')]` only (`app/app.dart`). |
| WhatsApp booking or support | Not in app or API. Only the marketing plans in `docs/marketing/` mention it as a fallback channel. |
| Recurring or scheduled-repeat pickups | No match. |
| Damage or missing-item claim flow | Help screen has an FAQ answer only; no claim object. |
| Garment-care options (starch, fold, hanger, fabric note) | No match. |
| Business / bulk accounts | No match; product-marketing lists B2B as "later". |
| Live partner location on a map | Partner location is stored for dispatch; the customer order screen shows partner name and contact, not a map. |
| First-order free garments | The "2 shirts + 2 pants free" campaign is a draft; existing coupons cannot express it (`IMPLEMENTATION.md`). |

## Visual system as shipped (source of truth: `docs/ui-ux-audit/DESIGN_SYSTEM.md`)

| Role | Light | Dark |
|---|---|---|
| bg | `#F7F8FA` | `#101820` |
| surface | `#FFFFFF` | `#18222F` |
| text | `#0E1E3D` | `#EEF3FA` |
| text-muted | `#526078` | `#AFBED1` |
| primary | `#1F4FD1` | `#7FA2FF` |
| primary-soft | `#E8EEFC` | `#1C2F63` |
| border / border-strong | `#DFE5ED` / `#7D8BA3` | `#344254` / `#6F82A6` |
| offer | `#FFC93C` on `#0E1E3D` | same |

Type: Junction Bold headings, Figtree body, Geist Mono for order IDs, Outfit in the logo. Spacing 4-based, 20 dp gutters. Radii 8/10/12/20. No resting shadows. Four tabs: Home, Orders, Offers, Account (Lucide icons). Three matte 3D service images (iron, washer, blazer).

## Screens (47 representative views, `docs/ui-ux-audit/IMPLEMENTATION.md`)

Prefix `ID-`. S01 Launch · S02 Welcome · S03 Mobile number · S04 Verify code · S05 Profile setup · S06 Map pin · S07 Outside service area · S08 Place search · S09 Address details · S10 Saved addresses · S11 Home · S12 Choose items · S13 Item search · S14 Basket · S15 Empty basket · S16 Pickup and delivery · S17 Checkout · S18 Payment failure · S19 Pickup confirmation · S20 Active orders · S21 No active orders · S22 Order tracking · S23 Items and bill · S24 Payment received · S25 Notifications · S26 Offers · S27 No offers · S28 Offers failed · S29 Account · S30 Edit profile · S31 Help · S32–S34 Terms, Privacy, Cancellation · S35 Notification permission · S36 Offline/unavailable · S37 Force update · S38 Account paused · S39 Offline banner · S40 Address switcher · S41 Promo sheet · S42 Change delivery time · S43 Pay amount due · S44 Cancel order · S45 Log out · S46 Delete account · S47 Deletion blocked.

## Data model (13 tables, `apps/api/prisma/schema.prisma`)

User, DriverProfile, Device, Address, CatalogCategory, CatalogItem, Promotion, Banner, Order (+ OrderItem, OrderEvent), DispatchOffer, Payment, Refund, Notification, BusinessSettings (single row), AppVersion, AuditLog, ServiceHeartbeat.

## Limits of this baseline

- Nothing here was run on a device in this session; "shipped" means present in code and documented as tested in `IMPLEMENTATION.md`.
- Real-device checks the repo itself lists as still open: Google Maps and denied location, Firebase SMS autofill, Razorpay native flows, push on hardware, VoiceOver/TalkBack.
- Catalogue prices in the repo are placeholders; real prices are loaded outside the repo.
