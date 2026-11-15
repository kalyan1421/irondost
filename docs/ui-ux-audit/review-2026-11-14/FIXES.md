# Audit fixes — implementation tracker

Updated 15 November 2026. The [audit report](REPORT.md), [27 original findings](issues.csv) and [39 feature entries](features.csv) remain the as-found record. All 27 finding IDs have local code changes; the checks below are not a production rollout or a real-device pilot. Existing unrelated worktree changes were preserved.

Decision: price requests expire after **12 hours**. The public support reply deadline stays **off** until staffing is confirmed.

## Phase status

| Phase | Findings addressed | Local result | Remaining work |
|---|---|---|---|
| 1. Money accuracy and safe staff actions | C02–C06, A03, A17, A18 | Payment and refund screens use transaction states; receipts require confirmed payment data; cash collection is explicit; phone-order drafts retain a retry key; concurrent item edits report a revision conflict. | Verify payment provider and actual cash handoff in a staffed pilot. |
| 2. Frozen quotes and price approval | C01, A01, A02; FC01, FA01 | Booked line rates stay frozen. Staff preview the full old/new bill. Increases wait for customer approval; decreases apply with notice. Approval expiry is 12 hours. | Exercise customer notification and expiry on native devices and a staffed pilot. |
| 3. Order-linked reports | C08, C09; FC02, FA02 | Customer reports include an order, category, evidence, case ID, status and two-way replies. Staff have a queue, ownership, resolution note and optional overdue filter. Submission retries reuse a durable key; cancelled orders can be reported. Support call/email failures have recovery. | Staff record a structured remedy amount when resolving a report and can link a refund made on the same order (15 November). The customer sees the agreed amount; refund status stays on the order. Keep public reply target off pending staffing. |
| 4. Visibility, recovery, units and accessibility | C07, A04–A16 | Admin KPIs link to matching filtered orders; query failures have recovery; alerts paginate; realtime reconnect refreshes; units, manual partner wording, dirty-form guards, chart data and full audit detail are visible. | Check keyboard, screen reader, narrow browser and partner handoff on real devices. |

Every selected Trust-core capability now has a local implementation. The other feature entries in [features.csv](features.csv) remain decisions for later phases, conditional on operating capacity and actual customer need; they are not implied by the 27 finding closures. The partner field client, wallet and rewards are not included in this UI/UX pass.

## Verification

- API: **153 [unit tests](verification/fixes-api-unit.log) and 57 [e2e cases](verification/fixes-api-e2e.log) passed**. The e2e run covers quote approval and conflicts, payment/refund states, report ownership and retry, a cancelled-order billing report, and the response-clock setting. TypeScript and lint passed.
- Customer: Flutter [analysis](verification/fixes-customer-analyze.log) and **481 [widget/unit tests](verification/fixes-customer-tests.log) passed**. Small-screen checks passed for **78 original views and 16 [new Trust-core views](verification/fixes-trust-stress.log)** at 320 dp and 200% text. Fixture gallery includes 94 original views and 16 additional Trust-core light/dark captures under [`fixed-customer/`](fixed-customer/).
- Admin: typecheck, ESLint and [production build](verification/fixes-admin-build.log) passed. Local browser checks covered dashboard, settings clock defaults and dirty guard, audit filters/detail, order draft restoration and customer switching. A local fault-proxy drill dropped the phone-order response after server commit; retry returned the same order with `Idempotent-Replayed: true`, and the order count increased by exactly one.
- No production database, customer order, provider payment/refund, or deployment was changed. The browser walkthrough used a synthetic local database. Flutter captures use fake repositories; they do not establish native provider or device behavior.

## Release checks

1. The new Prisma migrations (trust core, report retry key, contact phone, payment capture time, report remedy, and later ones) apply on their own when the API deploys: the container runs `prisma migrate deploy` before it starts. If a migration fails the new instance does not start and Render keeps serving the old one. Take a database backup first and rehearse the migrations on a copy; see [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md). Deploy the API before the admin and before the apps.
2. Verify Razorpay success, pending and failed refunds, mixed COD/online collection, deep-linked receipts, and order-linked report photos on test devices with test provider credentials.
3. Run staff/customer pilot tasks for changed-price approval, report response and compensation, one phone order with response loss, cash handoff and manual partner assignment. Confirm staffing before enabling any public reply deadline.

## Second review pass (15 November)

Code review of the uncommitted work found and fixed: elapsed price requests still blocking pickup and delivery; a stuck phone-order draft after a rejected retry; a saved draft redirecting to another customer; raw status names on the approval sheet; duplicate realtime refetch. Follow-ups also closed: receipts use a stored `capturedAt` (migration backfills from the last update); expiry and first-response jobs use a fixed job id so a restart cannot queue duplicates; payment guards use the injected clock and lock the order row; order lists read only the newest price request; the unused receipt `initial` argument is gone; new API files are formatted at 120 columns.

Open decision: report photos are stored at public, unguessable URLs. Move them to signed or authenticated reads before the evidence is expected to be private.
