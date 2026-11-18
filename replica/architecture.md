# Architecture: closing IronDost's market gaps

replica-architect output. Date 2026-11-07. Reads [recon.md](recon.md), [features.csv](features.csv), [parity.md](parity.md), [fixes.md](fixes.md). This is **an extension plan for the existing platform**, not a rebuild: the skill's default stack is replaced by what IronDost already runs.

Scope: the 6 missing must-haves plus the should-haves that the evidence supports. Nothing here has been built.

## Stack (keep what exists)

| Layer | Today | Decision | Why |
|---|---|---|---|
| API | NestJS 12, Prisma 7, PostgreSQL | Keep | One API, one database, all rules on the server (README). The plan adds tables and routes, no new service. |
| Customer app | Flutter, Riverpod, go_router | Keep | New screens use the existing design system and component contracts. |
| Admin | Next.js 16 | Keep, add pages | Issue queue, adjustment requests, slot templates, wallet packs. |
| Website | Next.js 16, static pages | Keep, add pages | Public price list and neighbourhood pages. |
| Auth | Firebase phone OTP and Google | Keep | Riders sign in the same way (role DRIVER). |
| Payments | Razorpay, cash with admin | Keep | Wallet top-ups reuse the Razorpay order and webhook path. |
| Jobs | pg-boss (jobs in Postgres) | Keep | Four new jobs, no Redis. |
| Realtime and push | Socket.IO and FCM | Keep | Issue and adjustment updates ride the existing events. |
| Files | Supabase Storage via the upload pipeline (EXIF stripped, WebP) | Keep | Issue and pickup photos reuse it. |
| Messaging | none | **Add: WhatsApp Business Cloud API (official), later** | Needs a verified business and Meta-approved templates, which take time. Phase one is a plain click-to-chat link. |
| Hosting | Render (API), Supabase (database, images) | Keep | Nothing here changes capacity needs. |

## Schema

[schema.sql](schema.sql): **13 new tables, 4 altered** (`orders`, `business_settings`, `promotions`, `users`), 8 enums.

| Feature | New or changed | Key rule enforced by the database |
|---|---|---|
| Express and quick orders | `business_settings` (4 columns), `orders` (speed, fee, kind, estimates, reschedule count) | A fee only on EXPRESS orders; express turnaround cannot exceed standard; at most 3 reschedules |
| Pickup windows | `slot_templates`; `orders.pickup_slot_id`, `delivery_slot_id` | Window must end after it starts; valid days only; old orders backfilled |
| Problem reports | `order_issues`, `order_issue_messages` | A resolved report must carry a time; at most 5 photos; a small index for "no reply yet" |
| Price-change approval | `order_adjustments` | **At most one open request per order** (partial unique index) |
| Photos, rating | `order_photos`, `order_feedback` | Rating 1 to 5, one per order |
| Add-ons | `catalog_addons`, `order_addons` | Name and price copied onto the order |
| First-order offers | `promotions.first_order_only`, `promotion_free_items` | |
| Wallet | `wallet_packs`, `wallet_accounts`, `wallet_transactions` | **Append-only ledger; balance changed only by ledger inserts; cannot go below zero; replayed keys rejected** |
| Referrals | `referrals`, `users.referral_code`, `users.whatsapp_opt_in_at` | No self-referral; one referrer per person |

Conventions kept: snake_case plural tables, Postgres enums, `TIMESTAMP(3)` (the skill prefers `timestamptz`; the existing tables all use Prisma's UTC `TIMESTAMP(3)`, and a mixed schema would be worse), money as integer paise, UUID keys, `ON DELETE` chosen per table (child rows CASCADE with their order; people and money RESTRICT, because users are soft-deleted and ledger rows must outlive anything).

**Access rules:** data-layer checks, as today (role guards plus per-query ownership). RLS is not used. Every new customer route needs a test where a second customer must get nothing back.

### How this was tested

A throwaway PostgreSQL 14 cluster was created in a temporary folder, IronDost's seven existing migrations were applied, one order was inserted, then `schema.sql` was applied and **35 checks ran, 35 passed**. The first migration, [schema.trust-core.sql](schema.trust-core.sql) (generated from the full file), was also applied on its own to a fresh cluster and passed its **17 focused checks**. They cover the backfill of that pre-existing order, the one-open-request rule, the ledger (balance, overspend, replay, edit, delete), the express rules, issue and slot constraints, referrals and rating. The cluster was deleted afterwards. **Not tested:** concurrency under load, the Prisma schema (not written), any application code, a real database, or the existing e2e suite against the new schema.

## API

Existing conventions: `/v1` prefix; customer routes under `orders`, `me/...`, `schedule`; riders under `driver`; staff under `admin`; `@Public()` for open routes; role guards. "Extend" means additive fields only, so apps already in stores keep working (and the forced-update gate in `app_versions` stays a last resort).

| Method and path | Does | Who | Input | Output | Feature |
|---|---|---|---|---|---|
| POST `/orders/quote` (extend) | Adds speed and its fee | Customer | + `deliverySpeed` | + `expressFeePaise`, earliest delivery | Express |
| GET `/schedule/delivery-slots` (extend) | Honours express minimum turnaround | Customer | + `speed` | slots | Express |
| PATCH `/admin/settings` (extend) | Express rules, issue SLA hours | Admin | new fields | settings | Express, issues |
| GET, POST, PATCH `/admin/slot-templates` | Manage windows and capacity | Admin | code, label, times, days, capacity | template | Windows |
| GET `/schedule/pickup-slots` (extend) | Reads templates, hides full ones | Customer | date | slots | Windows |
| POST `/orders/:id/reschedule` | Move pickup or delivery | Customer | slot ids, dates | order | Reschedule |
| POST `/orders/:id/issues` | Open a problem report | Customer | category, text, up to 5 photos | issue | Reports |
| GET `/me/issues`, GET `/me/issues/:id`, POST `/me/issues/:id/messages` | Follow and reply | Customer | | issue, messages | Reports |
| GET `/admin/issues`, PATCH `/admin/issues/:id`, POST `/admin/issues/:id/messages` | Queue, acknowledge, resolve | Staff | status, note | issue | Reports |
| POST `/admin/orders/:id/adjustments` | Ask the customer to approve a new total | Staff | reason, new items | adjustment | Approval |
| POST `/orders/:id/adjustments/:adjId/approve` and `/decline` | Customer decides | Customer | | adjustment, order | Approval |
| POST `/admin/orders/:id/photos`, POST `/driver/orders/:id/photos` | Pickup or delivery photos | Staff, rider | file, kind | photo | Photos |
| GET `/me/wallet`, GET `/me/wallet/packs`, POST `/me/wallet/topups` | Balance, packs, start a top-up | Customer | pack id | balance, Razorpay order | Wallet |
| POST `/orders` (extend) | Spend wallet in the same transaction as the order | Customer | + `useWalletPaise` | order | Wallet |
| GET `/me/referral` | Code and status | Customer | | code, counts | Referral |
| POST `/auth/session` (extend) | Accept a referral code at first sign-in | Customer | + `referralCode` | session | Referral |
| GET `/catalog` (extend) | Add-ons and audience tag on items | Public | | catalogue | Add-ons, audience tabs |
| POST `/orders/:id/feedback` | One rating after delivery | Customer | 1 to 5, comment | feedback | Rating |

**Webhooks in:** Razorpay (exists; top-ups add `payment.captured` handling that writes ledger rows keyed by the provider payment id, so a retried webhook cannot credit twice); WhatsApp (phase two, signature-verified). **Webhooks out:** none.

**Jobs (pg-boss):**

| Job | Schedule | Does |
|---|---|---|
| `issues.sla-check` | every 5 min | Open reports past `first_response_due_at` raise a staff alert (existing alert path) |
| `adjustments.expire` | every 15 min | Open requests past `expires_at` become EXPIRED and the **old total stands** until staff re-contact (owner to confirm the policy) |
| `referrals.qualify` | hourly | First delivered order of a referee qualifies the referral and writes the two reward rows |
| `wallet.expire-bonus` | daily | Only if the owner chooses expiring bonus credit |

**Rider client** (prerequisite, see below): uses the existing `driver` routes and the new photo route.

**Website:** price list and neighbourhood pages are static pages in `apps/web` that read the public `GET /catalog` at build time with periodic revalidation. Neighbourhood pages must carry real, locally true content (areas from `service_pincodes`, real windows), not templated text; thin doorway pages hurt more than they help.

## The parts that bite

- **Riders have no app.** Today staff move every leg from the admin console (runbook). Photos at pickup, delivery proof, express promises and honest windows all depend on riders using a phone. The good news from the code: the `driver` routes (online, location, offers, tasks, items, picked-up, out-for-delivery, delivered) already exist; only a client is missing. **Build this before volume.** Options: a Flutter app (the README's planned `mobile/partner`) or a mobile-first rider page in the admin; the page is faster to ship.
- **Stored value is a legal and accounting question before it is a feature.** Competitors' packages carried inconsistent terms (observed at Tumbledry and DhobiLite). Decide expiry, refund-of-balance, tax treatment and what the minimum recharge is with an accountant first. The ledger is built so the money side is safe; the policy is not an engineering decision.
- **Express is a promise.** A surcharge for a speed the operation cannot hit becomes the next complaint. Gate it by capacity (`slot_templates.capacity`), turn it off per slot, and decide up front that a missed express refunds the fee automatically.
- **Price-change approval can deadlock.** If the customer does not answer, something must happen. Default proposed: the old total stands, staff call. Owner decision.
- **Slot oversell.** Capacity checks and order creation must share a lock (an advisory lock per date and slot); otherwise two customers take the last place.
- **Idempotency.** Wallet ledger keys come from provider ids or order ids, never random values, so retries are safe. Existing orders already use an idempotency key header; reuse it on new POSTs.
- **Time.** Windows are local India times (Asia/Kolkata, no daylight saving); store instants in UTC; convert at the edge.
- **Old apps.** All API changes are additive and default to today's behaviour (STANDARD speed, ITEMISED orders).
- **Privacy.** Issue photos and messages hold personal data. Keep them behind the owner's authorisation checks, strip EXIF (the pipeline already does), set a retention period, and keep account deletion anonymising users while the ledger and tax records stay. India's Digital Personal Data Protection Act applies; get advice on consent text for WhatsApp.
- **WhatsApp.** Business verification and template approval take time; consent must be recorded (`whatsapp_opt_in_at`); messages outside the 24-hour window need approved templates; use only the official API.
- **Telugu.** The bundled fonts (Junction, Figtree) do not cover Telugu script. A Telugu font with an open licence must be bundled and every screen retested at large text; catalogue names need translations (an `name_i18n` column, not in `schema.sql` yet).

## Build order

Each step lists screens (existing IDs from [irondost-baseline.md](irondost-baseline.md); **new** = not yet designed), tables and routes. Sizes: S small, M medium, L large.

1. **Quick wins (S).** WhatsApp click-to-chat link on Help (S31), order detail (S22) and the website, prefilled with the order number. Public price list and 3 to 5 real neighbourhood pages. Fix the store-listing subtitle that promises "in a day" (see [launch/launch-plan.md](launch/launch-plan.md)). No schema change.
2. **Vertical slice: trust core (M).** `order_issues`, `order_issue_messages`, `order_adjustments`. Screens: **Report a problem** (new), **Issue detail** (new), **Approve new total** sheet (new, on S22), admin queue and adjustment request. Routes: issues, adjustments. Job: `issues.sla-check`, `adjustments.expire`. Proves the stack end to end and answers the largest complaint themes.
3. **Speed and windows (M).** `business_settings` express fields, `orders` speed columns, `slot_templates`. Screens: speed rows in S16, express line in S14 and S23, **Reschedule** (new). Routes: quote, slots, reschedule, admin templates. Needs the rider client for honest capacity.
4. **Rider client (L).** The owner chose a Flutter partner app ([plans/decisions.md](plans/decisions.md)), built on the existing `driver` routes plus photo upload. Screens: task list, order detail, mark picked up with photos, mark delivered. Unlocks pickup photos and damage evidence.
5. **Offers and care options (M).** `first_order_only`, `promotion_free_items`, `catalog_addons`, audience tabs. Screens: S12, S14, S26, S41 changes.
6. **Wallet, then referral (M each).** After the accounting decision. Screens: **Wallet** (new, becomes a tab or an Account row), top-up sheet, spend toggle in S17. Jobs: `referrals.qualify`.
7. **Language (M).** Telugu first, Hindi after, through Flutter localisation.
8. **Later or never:** live rider map, membership, recurring pickups, business accounts, process-story screens.

## Size

13 new tables, 4 altered; about 28 routes (7 of them extensions of existing ones); 3 to 4 jobs; about 8 new Flutter screens or sheets; 4 admin pages; one rider client. **Size: L overall (a quarter of focused work), but steps 1 and 2 are M and ship value alone.**

**Three riskiest parts:** (1) the rider client, because reliability depends on riders using it; (2) the wallet, because it holds customers' money and needs a policy decision; (3) express, because it is a public promise on top of an operation that is still being proven.

**Next step in the pack:** `/replica-design` for the new screens (the design write-up is in [design/design-teardown.md](design/design-teardown.md)), then `/replica-build` starting at step 2.
