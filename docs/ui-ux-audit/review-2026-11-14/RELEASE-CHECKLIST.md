# Release checklist: Trust core, customer UI refresh and phase 1 features

Written 15 November 2026. **Nothing here has been run against production.** Every step is for you (or a person you name) to run; the commands only read or deploy what you point them at. Untick a step and stop if its check fails.

What ships together: price approval and frozen quotes, order reports with photos and remedies, honest payment and refund states, safer admin order flow, the customer UI refresh (links, report form, price approval sheet, refund rows, order detail, welcome, checkout), and phase 1 features (reschedule a pickup, payments ledger, undelivered alerts). Later phases add their own migrations and notes at the end.

## 0. Know what production has

- [ ] Open the Render service logs for the API and the latest successful deploy, and read the current database state: `cd apps/api && DATABASE_URL='<production session-pooler string>' pnpm exec prisma migrate status`. It lists applied and pending migrations (read-only).
- [ ] Expect these to be pending unless a deploy already ran them: `20261103090000_customer_contact_phone`, `20261114090000_trust_core`, `20261115090000_issue_retry`, `20261115120000_payment_captured_at`, `20261115130000_issue_compensation`, `20261116100000_order_reschedule`, `20261116110000_push_deliveries`, `20261117100000_travel_charge`, `20261117110000_service_area_rules`, `20261117120000_care_notes`. All are additive (new tables and columns). Two contain data statements: `payment_captured_at` fills `captured_at` from `updated_at` for captured payments, and `trust_core` adds CHECK constraints on new tables only.
- [ ] Run the Tier 1 integrity checks below once **before** the release, so you have a baseline.

## 1. Back up and rehearse

- [ ] Take a database backup. A free Supabase project has no backups: dump it (`pg_dump` over the session pooler) or move to a paid plan first.
- [ ] Rehearse on a copy: restore the dump into a scratch database and run `DATABASE_URL=<scratch> pnpm exec prisma migrate deploy`. It must finish with no errors. Then start the API against the scratch database and open `/v1/health`.
- [ ] CI is green on the branch (`.github/workflows`), including the admin typecheck.

## 2. Deploy order

The API container runs `prisma migrate deploy` and then starts, so deploying the API applies the migrations. If a migration fails, the new instance does not start and Render keeps serving the old one. Deploy in this order, because the newer clients call endpoints the older API does not have:

1. [ ] **API** (Render: `autoDeploy` is off, deploy on purpose). Watch the deploy log for the migration lines, then the startup warnings (Razorpay test key, missing Firebase credentials, `TRUST_PROXY_HOPS`). Check `GET /v1/health` returns `status: ok`.
2. [ ] **Admin console** (Render). Sign in with the admin account and open Orders, Reports, Payments and Undelivered alerts.
3. [ ] **Customer app** build with production settings: `flutter build ipa --release --dart-define-from-file=env/prod.json` (and `appbundle` for Android). A release build refuses to start with a dev configuration. Raise the build number (currently `2.0.0+103`). Upload to TestFlight and Play internal testing first, not to review.

The currently released app (2.0.0) keeps working against the new API: new response fields are optional and the new endpoints are only called by the new build. A new build against the old API shows errors on the new screens, which is why the API goes first.

## 3. Smoke test on production (use a test customer and a small real order)

- [ ] Sign in (phone code) and place a cash order. Open tracking, the bill and the receipt.
- [ ] As admin, edit the items so the total goes up. The customer gets a price request; approve it on the phone; the bill updates. Decline another and confirm the original bill stands.
- [ ] Report a problem with a photo; reply from admin; resolve with a remedy; the customer sees it.
- [ ] Reschedule a pickup before it is picked up; the admin timeline shows it. (After phase 1.)
- [ ] Pay online with a real small amount, then refund it; check the Payments page shows both and the Razorpay refund status.
- [ ] Turn off notifications on a test phone, trigger an alert, and see it under Undelivered alerts.
- [ ] Open every changed customer screen in light and dark, at the largest text size, on one small and one large phone; use VoiceOver or TalkBack on checkout and the price approval sheet.

## 4. Configuration that must be right (see the existing docs)

[`api-deploy-render.md`](../../api-deploy-render.md) and [`customer-app-release.md`](../../customer-app-release.md) cover these; confirm each before pressing deploy: Razorpay live keys and webhook secret, Firebase service account and APNs key, `TRUST_PROXY_HOPS=1`, `CORS_ORIGINS`, Supabase storage bucket and service key, Render and Supabase plans (the API must not sleep), Google Maps keys and SHA-1s, Firebase test phone number for store review.

## 5. Tier 1 integrity checks (read-only SQL; run before, right after, then daily for a week)

```sql
-- Price requests that expired but were never marked (should be 0 after a minute)
SELECT count(*) FROM order_adjustments WHERE status = 'PENDING_CUSTOMER' AND expires_at < now() - interval '5 minutes';
-- Orders with money paid beyond the total and no refund record (should be 0)
SELECT o.order_number FROM orders o WHERE o.paid_paise - o.refunded_paise > o.total_paise
  AND NOT EXISTS (SELECT 1 FROM refunds r WHERE r.order_id = o.id);
-- Same customer and idempotency key twice (the unique index makes this 0)
SELECT customer_id, idempotency_key, count(*) FROM orders WHERE idempotency_key IS NOT NULL GROUP BY 1,2 HAVING count(*) > 1;
-- Captured payments without a capture time (should be 0 after the migration)
SELECT count(*) FROM payments WHERE status = 'CAPTURED' AND captured_at IS NULL;
-- Reports overdue against the clock (only meaningful once a response clock is set; it is off)
SELECT count(*) FROM order_issues WHERE status = 'OPEN' AND acknowledged_at IS NULL AND first_response_due_at < now();
```

## 6. Rollback

- Redeploy the previous API image from Render. Migrations are additive, so the previous API runs fine against the new schema; **do not** roll the migrations back by hand.
- Admin: redeploy the previous build. Apps: pause the staged rollout in the store; the previous build keeps working against the new API.
- There are no feature switches for price approval, reports or rescheduling. If one misbehaves, the containment is an API redeploy plus a manual correction of the affected orders. The audit report's Tier 1 containment switches are a proposal and are **not built**.

## 7. Known gaps at release

- Report photos and care-note photos live at public, unguessable URLs (the care photos use the `care/` folder of the same public bucket). Move to signed or authenticated reads before the evidence is expected to be private.
- The first-reply promise for reports is **off** (no deadline shown); staffing is not confirmed.
- No delivery partner app: staff do every step by hand. Cash is recorded per order, with no per-partner daily settlement.
- Fixture captures and the local iPhone build are not a device pilot. Real-device VoiceOver/TalkBack, Razorpay success/pending/failure, push on a locked phone and the browser walkthrough of the admin are still open.
- The privacy policy and store data-safety answers need a line for each phase that collects something new (ratings, intake photos, funnel and crash counters).

## Settings to set after the API deploys (admin settings, super admin)

None of these are changed by a migration except the capacity default, so set them on purpose:

- **Service centre:** latitude **17.346688**, longitude **78.550438** (Plus Code 8HW2+M5, LB Nagar Circle), radius **6** km.
- **Allowed PIN codes:** 500074, 500060, 500035, 500068, 500070, 500079, 500059.
- **Travel charge:** 3000 paise (₹30). **Free travel from:** 20000 paise (₹200). **Minimum order:** 0 (a minimum above 0 blocks small orders instead of charging them).
- **Pickups per time window:** the migration sets **8** on the existing settings row, so the cap is **live the moment the API deploys**. Check it in settings before deploying if 8 is not what you want.
- Use the **Check an address** tool on a few known streets (LB Nagar, Dilsukhnagar, Nagole, Malakpet, Uppal) and on Sarada Nagar and Vaishali Nagar before opening bookings.
- Existing customers with saved addresses outside the area keep them; they see "not in your area yet" and can ask to be told.
- Existing orders are not repriced: orders booked before the travel rule have no frozen rule and keep the fee they were booked with.

## Smoke tests for the new rules (use a test customer)

- [ ] Book from an address inside the circle and one outside (outside is refused; "Tell me when you're here" adds a row on **Outside the area**).
- [ ] Book ₹150 of items: the bill shows a ₹30 travel charge and the basket says how much more makes it free; book ₹200: travel is free; use a coupon on ₹210 and confirm it stays free.
- [ ] Add a care note with a photo; the admin order shows it.
- [ ] Fill a window (9th booking): it shows Full for customers; a phone order can override with a reason.
- [ ] Count more items at pickup so the order crosses ₹200: the charge disappears inside the price request.
- [ ] Cancel with "Partner already travelled" ticked: the refund excludes the ₹30 and the order says why.

## Later phases

Add here as each ships: its migration name, any new endpoint the apps depend on, and its smoke test.
