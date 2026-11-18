# Backend plan: the Trust core

replica-backend, as a plan. Date 2026-11-07. Scope per [decisions.md](decisions.md): problem reports with a response clock, customer approval of price changes, and dependency hardening. Wallet, express, slots and referrals are out of this slice. Nothing is built.

## What the code does today (read, not run)

- **Price edits apply instantly.** `OrdersService.updateItems` (`apps/api/src/orders/orders.service.ts`, about line 540) replaces the lines, reprices, and emits `Events.OrderUpdated` with reason `items_changed`; the customer is told afterwards ("Your order total changed", `notifications/items-changed-copy.ts`). Two callers: the assigned rider at pickup (`PUT /driver/orders/:id/items`, only in `PICKUP_ASSIGNED`) and staff (`PUT /admin/orders/:id/items`, while `PENDING`, `PICKUP_ASSIGNED`, `PICKED_UP` or `PROCESSING`).
- **Every line is repriced at today's catalogue price,** not the price the customer was quoted (`pricingLines` reads `catalogItem` and takes `offerPricePaise ?? pricePaise`). If prices change between booking and pickup, an edit silently reprices the whole order, and an item deactivated since booking blocks the edit with `ITEM_UNAVAILABLE`. This matters now: the live catalogue still holds placeholder prices ([launch/pricing.md](../launch/pricing.md)), and correcting them would reprice any order that is edited afterwards.
- **No test covers `updateItems`** (no hit in `orders.service.spec.ts` or `test/app.e2e-spec.ts`).
- **Uploads are admin-only** (`POST /admin/uploads/images`, one file, size cap, EXIF stripped, WebP). Customers have no upload route.
- **Jobs** go through the `JobScheduler` port (`register`, `schedule` with `startAfter`), pg-boss in production, in-memory in tests. Dispatch already schedules one-off jobs at a future time, so a response clock can be a job scheduled for its due time instead of a poller.
- **Events** are a small `Events` map (`events.ts`) with listeners in `notifications/notifications.listener.ts`.
- **The OpenAPI contract is checked in CI** (`pnpm --filter @laundry/api openapi` then `git diff --exit-code packages/contracts/openapi.json`), and clients are generated from it (admin: `gen:api`; Flutter: `swagger_parser`).

## Design

### A. Price-change approval

1. **Freeze quoted prices.** `updateItems` keeps each existing line's recorded `unit_price_paise` and prices only newly added items at the current catalogue. This removes silent repricing before anything else changes.
2. **Increases need approval, decreases apply at once.** A new total above the current one creates an `order_adjustments` row (`PENDING_CUSTOMER`, before and after lines, both totals, reason, requester, `expires_at = now + adjustment_expiry_hours`) and leaves the order untouched. A decrease or no change applies as today, with the existing notice.
3. **Approve** applies the stored "after" lines in one transaction, the same one `updateItems` uses, guarded so it only works if the adjustment is still pending and the order status has not moved; the adjustment becomes `APPROVED` with `decided_at`.
4. **Decline** marks `DECLINED`, leaves items alone, and alerts staff, who either continue at the original count or cancel the pickup (existing cancel flow and refund path).
5. **Expiry** is a job scheduled for `expires_at`: still pending means `EXPIRED`, the original total stands, staff are alerted.
6. **One open request per order** is enforced by the database (partial unique index), so two staff cannot stack changes. A second attempt returns a clear conflict.
7. **While a request is open**, the order cannot be marked out for delivery or have payment collected at the new total; the existing payment routes return a conflict with the reason.
8. **Compatibility:** responses gain an optional `pendingAdjustment` field. A customer on an app version that does not show it falls back to the expiry rule; raise the minimum app version (existing `app_versions` gate) once the new screen ships.

### B. Problem reports

1. **Create** (`POST /orders/:id/issues`): the caller must own the order; any status except already-cancelled; category, description (1 to 2000 characters), up to 5 photo URLs. Sets `first_response_due_at = now + issue_first_response_hours` and schedules one job for that moment.
2. **Photos:** a new customer route `POST /me/uploads/images` reuses the existing upload pipeline (type check, EXIF and GPS removal, resize to WebP), stores under `issues/<userId>/<uuid>.webp`, applies a stricter rate limit, and **issue creation accepts only URLs under that user's own prefix**.
3. **Staff** (`GET /admin/issues`, `PATCH /admin/issues/:id`, messages): acknowledge, reply, resolve or reject. Resolving needs a note and sets `resolved_at` (the database refuses a resolved row without it). Every staff action is written to the audit log.
4. **Response clock:** the job at the due time raises a staff alert if the report is still `OPEN`. An acknowledge or reply before then makes the job a no-op.
5. **Customer view:** list and detail with the thread; a push on each staff reply or status change.
6. **Retention:** keep resolved reports and photos for a fixed period (owner and lawyer to set it), then delete the photos and keep a stub. Account deletion anonymises the user and keeps order and ledger records.

### Draft copy (fresh wording, in the product's voice; owner to approve)

| Moment | Text |
|---|---|
| Customer: price change needs approval | Title "Your order total needs your OK". Body "We counted [n] items on order [no.] instead of [m]. The new total is [₹new] (it was [₹old]). Open the app to approve or decline." |
| Staff: declined | "The customer declined the new total on order [no.]. Choose: continue at the original count, or cancel the pickup." |
| Staff: expired | "No answer on the new total for order [no.]. The original total stands." |
| Customer: report received | "We have your report on order [no.]. We aim to reply by [time]." (use only if the owner commits to the clock) |
| Staff: overdue | "No reply yet on a report for order [no.], due [time]." |

## API (additive; paths under `/v1`)

| Method and path | Who | Input | Output |
|---|---|---|---|
| `PUT /admin/orders/:id/items`, `PUT /driver/orders/:id/items` (change) | Staff, assigned rider | items, note (as today) | order, plus `pendingAdjustment` when approval is needed |
| `GET /orders/:id` (extend) | Customer | | order plus `pendingAdjustment` |
| `POST /orders/:id/adjustments/:adjId/approve`, `/decline` | Order owner | | order |
| `POST /me/uploads/images` | Customer | one image | url |
| `POST /orders/:id/issues` | Order owner | category, description, photoUrls | issue |
| `GET /me/issues`, `GET /me/issues/:id`, `POST /me/issues/:id/messages` | Owner | | issues, thread |
| `GET /admin/issues`, `PATCH /admin/issues/:id`, `POST /admin/issues/:id/messages` | Staff | status, note, body | issue |
| `PATCH /admin/settings` (extend) | Admin | `issueFirstResponseHours`, `adjustmentExpiryHours` | settings |

New events: `adjustment.requested`, `adjustment.decided`, `adjustment.expired`, `issue.created`, `issue.overdue`, `issue.updated`. Jobs: `adjustments.expire` and `issues.sla` (both scheduled per record at their due time).

## Work items

| # | Work | Size | Depends on |
|---|---|---|---|
| B0 | **Characterisation tests first** for `updateItems` and pricing (including the repricing behaviour above), so changes are visible | S | none |
| B1 | Freeze quoted prices; Prisma models for the three tables and two settings; hand-written migration for the constraints Prisma cannot model | M | B0 |
| B2 | Adjustment create, approve, decline and expiry job; events and copy; payment and delivery guards | M | B1 |
| B3 | Customer image upload route with limits and prefix check | S | none |
| B4 | Issues API, SLA job, thread, audit | M | B1, B3 |
| B5 | Admin endpoints and settings; refresh the OpenAPI contract and both generated clients | S | B2, B4 |
| B6 | End-to-end tests, including the second-customer check on every new route | M | B2 to B5 |
| B7 | Dependency hardening (below) | S to M | independent |
| B8 | Security review of the new surfaces (checklist below) | S | B6 |

**Prisma and the partial indexes.** Prisma's migration tool may not model a partial unique index and might try to drop it on a later diff. Check how Prisma 7 treats partial indexes (there is a preview feature) before committing; otherwise keep these two indexes in the hand-written migration and review every generated migration for drops. Not verified here.

## Security checklist for the new surfaces

| Item | How it will be checked |
|---|---|
| Authorisation: only the order's customer sees or acts on its issues, adjustments and photos | A second-customer test per route (returns 404, never 403, so existence is not leaked) |
| Rate limits on issue creation, messages and uploads | Named throttle limits on the new routes; a test that the limit trips |
| Input validation | DTOs with length limits and the global whitelist pipe; photo URL prefix check |
| Uploads | Existing type check and EXIF strip; add a per-user daily cap; confirm the size cap |
| No personal data in URLs or logs | Message bodies and photo URLs never logged; review the log lines in the new code |
| Idempotency | Approve and decline are safe to repeat (second call returns the decided state) |
| Audit | Staff actions logged with actor, order and issue ids |
| Webhooks, secrets, new env vars | None added |

## B7: dependency hardening (16 high findings remain)

Order by exposure, each followed by the API unit and e2e tests and the admin build:

1. **`multer` (denial of service, fixed in 2.5.0)**: first, because B3 adds a customer-facing upload route.
2. **`body-parser` (denial of service, 2.4.0)** and **`follow-redirects` (1.16.2)**, **`deepmerge-ts` (8.0.0)**: API runtime.
3. **Admin:** `undici` (7.30.1), `zod` (4.6.6), `@grpc/grpc-js`, `re2js`, `systeminformation`. Check whether the `shadcn` code-generation CLI belongs in dev dependencies; several findings arrive through it.
4. **`mysql2` (3.22.0):** find out why a MySQL driver is in the API's tree before touching it.

Re-run `pnpm audit --prod` after each step and keep the count in [decisions.md](decisions.md).

## Partner-app API gaps (for the later slice)

The existing rider routes (`online`, `location`, `offers`, `accept`, `reject`, `tasks`, `orders/:id`, `items`, `picked-up`, `out-for-delivery`, `delivered`) cover the core. Missing: pickup and delivery photos (`POST /driver/orders/:id/photos`), recording cash collected at the door (today only staff record cash), a rider-visible "waiting for customer approval" state (needs `pendingAdjustment` on the rider's order view), and a way for the rider to reach the customer without exposing more of their number than needed.

## Done means

All of: tests in [test-plan.md](../test-plan.md) for ADJ and ISS pass; the second-customer tests pass; the OpenAPI contract and generated clients match (CI checks this); `pnpm --filter @laundry/api typecheck lint test test:e2e` green; audit shows no critical and fewer high findings; the migration was applied to a copy of production data before production.
