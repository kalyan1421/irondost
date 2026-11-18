# Missing features: scope and phased plan

Chosen 15 November 2026 from [features.csv](features.csv) and the customer UI plan. Reply deadline for reports stays **off**. The delivery partner app is **not started** (staff keep doing deliveries by hand). Going live is a **checklist only** ([RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md)); nothing here touches production.

| Phase | Features | Where |
|---|---|---|
| 1 | FC04 reschedule a pickup · FA07 payments and refunds ledger · FA13 failed notification view | API + customer app + admin |
| 2 | FC10 rate after delivery · FA08 intake count receipt and garment photos · FC14 prices and coverage before sign-in | API + customer app + admin |
| 3 | FC16 + FA11 first-order free-garment offer · FA15 funnel and crash measurements | API + customer app + admin |
| 4 | Release checklist, real-device pass | docs |

Rules for every feature: server owns prices and eligibility; customer screens use the design-system widgets (`IdButton`, `IdTextField`, `IdSelectField`, `ChoiceCard`, tokens); every new screen has loading, error and empty states and passes the 320 dp / 200% text stress suite; every money or status claim comes from a record, not a guess; no new recurring paid vendor.

## Phase 1

### FC04 Reschedule a pickup

- **Who and when:** the customer, while the order is `PENDING` or `PICKUP_ASSIGNED` (before pickup). Cancel stays as is.
- **What changes:** pickup date and slot, and the delivery date and slot (delivery must still satisfy the existing turnaround rule; the customer keeps the delivery window if it is still valid, otherwise picks a new one). Prices do not change.
- **Rules:** new windows validated with the same `checkPickup` / `checkDelivery` rules and slot availability as booking. At most **2 reschedules per order** (`orders.reschedule_count`). If a partner is already assigned, the assignment is cleared and the order returns to `PENDING` so dispatch offers the new window; the previously assigned partner is told the pickup moved. The new dates must be written before dispatch reads them.
- **API:** `POST /v1/orders/:id/reschedule` with `{pickupDate, pickupSlot, deliveryDate, deliverySlot}` and an `Idempotency-Key`; response is the updated order. Errors: `RESCHEDULE_NOT_ALLOWED` (status), `RESCHEDULE_LIMIT`, schedule errors as in booking. An order event ("Rescheduled by customer: Sat 3 Oct 4-8 PM to Sun 4 Oct 7-11 AM") and an audit entry; realtime and staff alert so the admin board updates.
- **Customer app:** "Change pickup time" row on order detail while allowed (replaces "cancel and book again" in Help). Reuses the schedule picker; shows remaining reschedules; clear failure messages; the tracking card shows the new window.
- **Admin:** the timeline shows the event; nothing else needed.
- **Done when:** unit tests for the rules, e2e for success, limit, wrong status, assigned-partner reset and idempotent retry; customer widget tests and captures; stress passes.

### FA07 Payments and refunds ledger

- **API:** `GET /v1/admin/ledger` returns payments and refunds as one list of entries (`kind` PAYMENT or REFUND, `status`, `method`/provider, amount, order number and id, customer name and phone, reference, timestamp, note). Filters: kind, status (including `problem` = pending or failed), provider/method, date range (IST), search by order number or customer phone, pagination, plus totals for the filtered set. `GET /v1/admin/ledger/export` returns the same filter as CSV (cap 10,000 rows; cells that start with `=`, `+`, `-`, `@` are prefixed with a quote to stop spreadsheet formulas). Read-only; ADMIN and SUPER_ADMIN.
- **Admin:** new "Payments" page in the sidebar: filter bar, table with order link, status badges, a "Needs attention" shortcut (pending or failed), totals row, Export CSV. Export is downloaded through the authenticated client, not a bare link.
- **Done when:** unit tests for CSV escaping and filters, e2e for access control, filters, totals and export, admin typecheck/lint, browser check of the page.

### FA13 Failed notification view

- **Data:** new table `push_deliveries` (notification id, user id, app, type, title, status `SENT` | `PARTIAL` | `FAILED` | `NO_DEVICE`, device count, failed count, error code, order id, created at, handled at, handled by). Written by the push service for every attempt; `NO_DEVICE` means the person has no registered device (never allowed notifications). When push is not configured (local dev) nothing is recorded as a failure.
- **API:** `GET /v1/admin/notification-deliveries` (default: problems only, filter by status, app, date, order number), `POST .../:id/retry` (one more send, recorded as a new delivery), `POST .../:id/handled` (mark followed up). Dashboard gets an `undeliveredAlerts` count.
- **Admin:** new "Undelivered alerts" page: who (name and phone with a call link), what was not delivered, why in plain words, order link, Retry and Mark followed up. Dashboard KPI links to it.
- **Done when:** unit tests for status derivation, e2e with a fake push gateway for sent, partial, failed, no device, retry and handled; admin checks.

## Phase 2

### FC10 Rate after delivery

One rating (1 to 5) and an optional note per delivered order (`order_ratings`). Customer sees a card on the delivered order; a rating of 3 or below offers "Report a problem" directly. Admin sees the rating on the order and an average on the dashboard. No points or rewards.

### FA08 Intake count receipt and garment photos

At pickup, staff or the assigned partner record the counted items (already possible) and may attach up to 5 photos and a bag or tag note (`order_intake_photos`, same storage and processing as report photos). The customer sees a "Counted at pickup" receipt (count, time, optional photos) on tracking. Admin sees the same on the order. Photos are private to the order's customer and staff.

### FC14 Prices and coverage before sign-in

A signed-out entry on the welcome screen: enter a PIN code, see whether it is served and the public price list (read-only, from existing public endpoints), then "Sign in to book". No order or address is created before sign-in.

## Phase 3

### FC16 + FA11 First-order free-garment offer

A promotion type "first order, N free of eligible items" enforced by the server: first non-cancelled order of the customer, eligible catalogue items and quantities, discount equal to the cheapest N eligible garments at the booked rate. The quote shows it as a discount line; admin gets a rule editor and a "quote for a test customer" preview. Percent and flat coupons keep working.

### FA15 Funnel and crash measurements

Privacy-light counters: booking started, address chosen, slot chosen, order placed, price approval decided, report sent, plus app crash reports. Stored by us (no third-party analytics SDK); a small admin page shows booking completion rate and crash counts per version. Needs a short note in the privacy policy before release.

## Out of scope this round

Reply-time promise (stays off), partner field app, live map, wallet, referrals, subscriptions, business accounts, express turnaround, care preferences, a different return address, repeat pickups, Telugu and Hindi, WhatsApp, notification preferences, capacity and holiday slots, partner cash settlement, staff roles, catalogue import.

## Open decisions to confirm later

- Reschedule limit (2) and whether delivery may be changed independently.
- Rating prompt timing (on opening the delivered order vs a push).
- First-order offer wording and eligible garments, which need your marketing decision before the campaign.
