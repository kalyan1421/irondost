# IronDost customer app and admin — consolidated UI/UX audit

Reviewed **14 November 2026 (IST)**. Repository: `ops/launch-gaps`, HEAD `ec96e54`, including the existing uncommitted work. This is the as-found audit; see [implementation status](FIXES.md) for the later local fixes and remaining release checks.

Downloads: [27 issue entries](issues.csv) · [39 feature entries](features.csv). Visual overviews: [light 1](overview-light-1.jpg), [2](overview-light-2.jpg), [3](overview-light-3.jpg), [4](overview-light-4.jpg); [dark 1](overview-dark-1.jpg), [2](overview-dark-2.jpg), [3](overview-dark-3.jpg), [4](overview-dark-4.jpg). These are fixture captures, not customer/production screenshots.

## Decision

**Finish the price and support trust workflows before another visual redesign.** The current customer interface has a consistent visual system and passes the existing automated layout checks. The largest remaining problems concern what happens after booking: changed prices, payment and refund truthfulness, support accountability, and staff recovery from failures.

This review records **27 open findings: 9 customer and 18 admin**, plus **39 feature gaps or partial capabilities: 21 customer and 18 admin**. Some feature gaps and findings describe the same underlying problem from different surfaces; do not add the two counts together. A gap is not automatically a requirement. Deferred features are explicitly separated from the previously selected Trust core.

There is no verified P0 outage in this review. P1 means material money, trust or operational risk to address first; P2 means a significant task or recovery problem; P3 means refinement or a capability whose need should be validated. Priorities are audit judgments, not observed incident rates.

## What “last audit” refers to

| Previous work | Actual status | Treatment in this report |
|---|---|---|
| [5 October customer audit](../AUDIT.md) and [implementation](../IMPLEMENTATION.md) | The original customer visual pass was implemented locally. The audit is historical evidence. | Do not reopen all 47 original findings as current defects. |
| [1 November mobile refresh](../../design/mobile-refresh/README.md) | Junction headings, clearer selections, estimate-first checkout, contact row and keyboard improvements are implemented locally. | This is the newer visual baseline. Fresh captures were generated for this review. |
| [7 November feature study](../../../replica/README.md) | Research and plans exist; the study did not implement the proposed features. | Rechecked the important gaps against current source. Competitor statistics were not refreshed. |
| [7 November owner decisions](../../../replica/plans/decisions.md) and [TASKS.md](../../../TASKS.md) | Trust core selected first; Flutter partner app follows; wallet/referrals parked. | Preserve this order. Do not turn a competitor checklist into a mandate to build everything. |

The current contact-number implementation differs from some older reports: Google customers can enter and correct a **contact number without SMS verification**. It is stored separately from the verified sign-in number. This is present functionality, not a missing OTP feature. See [customer README](../../../apps/customer/README.md) and [AddPhoneScreen](../../../apps/customer/lib/features/auth/add_phone_screen.dart).

## Requirement anchor

Users are local households booking ironing/laundry, operations staff handling orders, workshop staff, and delivery partners. The launch context in [.agents/product-marketing.md](../../../.agents/product-marketing.md) is LB Nagar/east Hyderabad.

The five essential jobs are:

1. Check coverage, choose clothes and understand the estimate.
2. Book a realistic pickup and return window using a reachable contact number.
3. Pay accurately and consent to any increase after collection.
4. Track progress and resolve late, missing or damaged garments and refunds.
5. Let staff dispatch, count, process, deliver and reconcile each order reliably.

Current constraints include Flutter on Android/iOS, an existing Next.js admin, one NestJS API/PostgreSQL database, Firebase authentication/push and Razorpay/COD. There is no partner client in the repository; the staff runbook describes manual administration. **Actual active-user count, daily order volume, support workload, team size and operating budget are not established by this repository.** No scale-based justification or maintenance estimate below should be mistaken for measured production data.

## Evidence and validation

| Check run for this review | Result | Evidence |
|---|---|---|
| Customer analysis | Passed, no issues | [Log](verification/customer-analyze.log) |
| Customer test suite | **467 passed** | [Log](verification/customer-tests.log) |
| Fresh real-widget customer captures | **94 passed: 47 representative views × light/dark**, 390 × 844 dp | [Log](verification/customer-captures.log), [images](customer/) |
| Small-screen large-text layout | **78/78 passed**, 320 × 740 dp, 200% text | [Log](verification/customer-stress320.log) |
| Admin ESLint | Passed | [Log](verification/admin-lint.log) |
| Admin TypeScript, `tsc --noEmit` | Passed | [Log](verification/admin-typecheck.log) |

Fresh visual inspection covered the customer contact sheets for all 47 view families in both themes, with full-resolution checks of checkout, scheduling, tracking and receipt. The fixtures contain sample people, amounts and October dates. A sample pickup appearing before a sample booking is a fixture-data inconsistency, not evidence of a production timeline defect. The receipt using the current wall clock is independently confirmed in source.

**Limits:** captures render actual Flutter widgets with fake repositories; they omit the tab shell and do not prove native provider behavior. The current base gallery does not include the separate `/phone/add` screen, although the normal accessibility suite does test it. Older November reports include additional widths and keyboard states; those historical results are not claimed as fresh results here. Admin findings are source-reviewed: browser automation failed to attach to the existing admin tab, so no current admin screenshots or responsive walkthrough were obtained. No production order, payment, refund, alert-read state, setting or customer record was changed. No API integration/e2e suite or new native build was run in this review.

Evidence labels below: **Code** = a directly visible implementation path; **Code risk** = a failure scenario inferred from source, not reproduced against a running service; **Visual** = fresh fixture inspection. Missing-feature conclusions are scoped to the routes, schema, clients and docs in this repository, not to tools staff might use elsewhere.

## Customer UI/UX findings

| ID | Priority | Finding and customer consequence | Evidence | Required correction / acceptance |
|---|---|---|---|---|
| C01 | P1 | **A booked price can increase without consent.** Staff item edits replace the bill immediately; customers receive the changed total after the change. Unchanged garments also acquire today's catalogue rate. | Code: [updateItems](../../../apps/api/src/orders/orders.service.ts#L540), [Trust-core decision](../../../replica/plans/decisions.md). | Preserve existing quoted rates. Show old/new counts, rates, discount, fees, total, reason and delta. Require approval for an increase; apply decreases with a notice. No collection of an unapproved increase. |
| C02 | P1 | **A pending refund can be presented as sent.** Tracking compares aggregate `refundedPaise` with paid money, but that aggregate includes PENDING refunds. It also assumes the original account for refunds that may be recorded as cash/bank transfer. Partial refunds are described using the original paid amount. | Code: [tracking cancellation body](../../../apps/customer/lib/features/orders/order_detail_screen.dart#L312), [counted refund states](../../../apps/api/src/payments/refunds.service.ts#L40), [RefundDto](../../../apps/api/src/orders/order.dto.ts#L289). | Render each refund's method, amount and PENDING/PROCESSED/FAILED status from the refund records already returned. Show paid, completed refund, pending refund and remaining amount separately. Never label a pending request as completed. |
| C03 | P1 | **The receipt screen asserts success without validating the order state.** With no order, it says “Paid” and “Your payment is done”; with any order, it says fully paid. A direct receipt route, failed fetch or stale order can therefore give false reassurance. The normal payment path does wait for confirmation, which reduces exposure but does not make this screen safe independently. | Code risk: [receipt](../../../apps/customer/lib/features/payment/payment_receipt_screen.dart#L26), [unguarded route builder](../../../apps/customer/lib/app/router.dart#L131). | Loading, retry/error, outstanding-balance and confirmed-paid states must be explicit. Require a confirmed paid state before showing the success message, including on direct navigation and refresh. |
| C04 | P2 | **Receipt details are not a transaction receipt.** “When” uses `DateTime.now()` on render; the amount is cumulative order payment, not necessarily the just-completed balance payment. Reopening changes the apparent transaction time. | Code + Visual: [receipt time/amount](../../../apps/customer/lib/features/payment/payment_receipt_screen.dart#L100), [fresh receipt](customer/payment-receipt-light.png). | Display the payment record's confirmed time, provider reference and transaction amount; label cumulative order payment separately. Reopening must preserve the same transaction details. Requires a customer-safe payment DTO if no existing customer endpoint provides it. |
| C05 | P2 | **Items and bill has no fetch-error recovery.** With no initial order, a failed request remains a spinner; with an initial order, stale content has no refresh-failed indication. Its header maps a fully refunded, zero-due order to “Unpaid.” | Code: [bill loading](../../../apps/customer/lib/features/orders/order_bill_screen.dart#L24), [payment badge](../../../apps/customer/lib/features/orders/order_bill_screen.dart#L131). | Handle loading/error/retry/stale explicitly. Render PAID, PARTIALLY_PAID, UNPAID and REFUNDED accurately. A failed direct bill load must offer Retry and Back. |
| C06 | P2 | **The displayed payment method is guessed from order choice and delivery status.** A COD order paid online before delivery can later say “Paid in cash”; a split cash/online order cannot be represented accurately. Payment capture does not rewrite the original order method. | Code: [paidHow](../../../apps/customer/lib/core/order_text.dart#L29), [capture/addPaid](../../../apps/api/src/payments/payments.service.ts#L135). | Use actual captured payment records or a server-computed payment summary. Correctly distinguish online, cash and mixed payment after delivery. |
| C07 | P2 | **Units become misleading outside the catalogue.** The catalogue supports piece/pair/set/kg, but basket prices say “each,” summary quantities are added as item counts, and quantities are integer-only. An order of kilograms is presented like a garment count and 2.5 kg cannot be entered. | Code: [basket row](../../../apps/customer/lib/features/basket/basket_screen.dart#L207), [quantity DTO](../../../apps/api/src/orders/order.dto.ts#L40), [order text](../../../apps/customer/lib/core/order_text.dart#L6). | Carry units through basket/bill/receipt/admin. For launch, either explicitly sell whole-kg increments or hide KG until measured-weight billing is implemented. Do not sum kilograms and garment pieces into one physical count. |
| C08 | P2 | **Call/email actions lack launch-failure recovery.** The shared support helper discards `launchUrl`'s boolean result and screens do not provide a useful fallback. A device without an email/phone handler can leave the customer with no next step. | Code risk: [Support.dial/mail](../../../apps/customer/lib/features/support/support.dart#L23), [order help callers](../../../apps/customer/lib/features/orders/order_detail_screen.dart#L436). | Catch failure, show the contact in selectable/copyable form and offer the other available channel. Denied/unavailable handlers must not silently fail or surface an unhandled exception. |
| C09 | P3 | **Order help does not carry order context into email.** The sheet tells customers to mention the order number, but the email link contains only the recipient. Customers must retype an ID already known to the app. | Code: [showOrderHelp](../../../apps/customer/lib/features/orders/order_detail_screen.dart#L436), [mailto helper](../../../apps/customer/lib/features/support/support.dart#L25). | Prefill a subject/body with order number and issue prompt; retain a manual contact fallback. Do not include more personal data than needed. |

### Customer design refinements, not confirmed breakages

- **Checkout density:** in the fresh [390 dp capture](customer/checkout-light.png), payment choices are below the initial fold while the online Pay CTA is already visible. The estimate-first change is useful. Test a compact payment-method summary/change action near the footer before compressing all review rows.
- **Delivery-time discoverability:** the current [schedule](customer/schedule-light.png) presents the earliest return with a Change link. Compare “Use earliest” and “Choose another window” in a small task test; the current link is functional and is not a missing feature.
- **Catalogue whitespace:** a short category leaves open space. Keep the count helper; do not fill it with another offer hero or an unsupported turnaround claim.
- **Contact changes:** the current checkout/profile paths already let customers correct their contact number. Do not build a duplicate phone-management flow based on the older critique or archived profile screenshot.

## Admin UI/UX findings

| ID | Priority | Finding and operational consequence | Evidence | Required correction / acceptance |
|---|---|---|---|---|
| A01 | P1 | **Edit items previews only subtotal before discount.** Staff cannot review the old versus proposed final payable total, fee/discount changes or the additional/refundable amount before Save. This amplifies C01. | Code: [items dialog](../../../apps/admin/src/app/(app)/orders/[id]/_components/items-card.tsx#L110). | Reuse a server quote for the proposed edit; show before/after/delta and approval state. Saving a higher amount must request consent rather than silently replace the accepted bill. |
| A02 | P1 | **Price-preservation copy contradicts item editing.** Catalogue and settings say existing orders retain prices, while `updateItems` reprices all submitted lines at current rates. Staff may change the rate card believing old orders are protected. | Code: [catalogue notice](../../../apps/admin/src/app/(app)/catalog/page.tsx#L56), [settings Pricing section](../../../apps/admin/src/app/(app)/settings/_components/settings-form.tsx), [repricing](../../../apps/api/src/orders/orders.service.ts#L547). | Freeze booked line rates; until fixed, make the edit consequence explicit. Acceptance: changing today's catalogue must not alter an unchanged line on an existing order. |
| A03 | P1 | **Cash collection is preconfirmed for COD orders.** The delivered dialog starts with the cash-collected box checked, so a routine confirmation can record money staff did not actually receive. It also retains component state between dialog openings. | Code risk: [OrderActions](../../../apps/admin/src/app/(app)/orders/[id]/_components/order-actions.tsx#L34). | Start each delivery confirmation unanswered. Require an explicit Paid in cash / Not collected choice when money is due, show the amount, and preserve a deliberate unpaid-delivery path. |
| A04 | P2 | **“Today” KPI links do not show the counted records.** Orders placed today opens all orders; pickup/delivery cards select workflow tabs without today's date. Pickup-date filtering alone cannot reproduce the delivery-date KPI. Partners online opens all partners. | Code: [Kpi hrefs](../../../apps/admin/src/app/(app)/page.tsx#L128), [orders filters](../../../apps/admin/src/app/(app)/orders/page.tsx#L29), [dashboard counting](../../../apps/api/src/admin/admin.service.ts#L235). | Each KPI must open a list using the identical date/status definition, including completed pickups/deliveries if the count includes them. Implement the missing created/delivery-date filters. |
| A05 | P1 | **The no-partner queue can disappear on error.** Its query is independent of the main dashboard; only successful nonempty data renders a panel. A healthy KPI response plus a failed attention query can look like no work needs attention. | Code risk: [attention query and conditional panel](../../../apps/admin/src/app/(app)/page.tsx#L28). | Always show an explicit loading/current/failed/stale state for the exception queue and a Retry action. A fetch error must never look like zero exceptions. |
| A06 | P2 | **Alerts say “All caught up” before successful loading and on fetch failure.** Missing data defaults unread to zero; the sheet has no loading, error or retry branch. | Code: [NotificationsMenu](../../../apps/admin/src/components/notifications-menu.tsx#L34). | Show loading/error separately from a confirmed empty inbox; retain stale alerts visibly when refresh fails. |
| A07 | P2 | **Only the latest 30 staff alerts are reachable.** There is no next page/load-more control even though the unread count can exceed that window. Mark all read can acknowledge alerts that the operator could not inspect in this UI. | Code: [fixed first page](../../../apps/admin/src/components/notifications-menu.tsx#L24). | Add pagination/load more and distinguish “mark visible read” from “mark all read,” with clear scope. Verify an older unread refund alert is reachable. |
| A08 | P2 | **Item editing and partner assignment have no query-error branch.** Their dialogs show a skeleton whenever data is absent, including a rejected request. Staff have to close and reopen without knowing why it failed. | Code risk: [items dialog](../../../apps/admin/src/app/(app)/orders/[id]/_components/items-card.tsx#L125), [assignment dialog](../../../apps/admin/src/app/(app)/orders/[id]/_components/partners-card.tsx#L133). | Add local error/retry states and preserve entered quantities/selection. Submission must require successfully loaded source data. |
| A09 | P2 | **Realtime recovery is not visible or explicitly refreshed.** The bridge handles `order.updated` only. There is no reconnect invalidation or connection-status indicator; order lists/details have no periodic refetch of their own. Focus refetch may eventually repair stale data, but a continuously open disconnected tab has no such guarantee. | Code risk: [RealtimeBridge](../../../apps/admin/src/lib/realtime.tsx#L26), [orders query](../../../apps/admin/src/app/(app)/orders/page.tsx). | On reconnect, invalidate visible operational queries; expose connection/last-refresh status and manual Refresh. Test a missed update during disconnect. |
| A10 | P2 | **Order editing labels every rate “each” and totals all units as pieces.** The new-order item chooser does respect units, so two admin flows describe the same service differently. | Code: [items card](../../../apps/admin/src/app/(app)/orders/[id]/_components/items-card.tsx#L30), [edit rate label](../../../apps/admin/src/app/(app)/orders/[id]/_components/items-card.tsx#L138), [new-order units](../../../apps/admin/src/app/(app)/orders/new/_components/items-step.tsx). | Share unit formatting and unit-aware summaries with C07; verify a piece, pair, set and KG item in both admin flows. |
| A11 | P2 | **Partner onboarding instructs staff to use an app that is not built.** Empty states say partners sign in/go online in the partner app; assignment copy says it is looking automatically. The runbook says staff currently do every transition. | Code: [drivers empty states](../../../apps/admin/src/app/(app)/drivers/page.tsx), [partners card](../../../apps/admin/src/app/(app)/orders/[id]/_components/partners-card.tsx), [runbook](../../staff-delivery-runbook.md). | Describe the current manual workflow and show an explicit dispatch mode. Keep the selected Flutter partner-app plan, but do not imply it works before field validation. |
| A12 | P2 | **Unsaved work can be dismissed without a warning.** Settings has a dirty-state message and Discard, but no navigation guard; item/promotion/banner dialogs close on ordinary dismissal without a dirty-state check. | Code risk: [settings form](../../../apps/admin/src/app/(app)/settings/_components/settings-form.tsx#L332), [promotion dialog](../../../apps/admin/src/app/(app)/promotions/_components/promotion-dialog.tsx), [banner dialog](../../../apps/admin/src/app/(app)/banners/_components/banner-dialog.tsx). | Warn on leaving a dirty form or provide a recoverable local draft. Do not add confirmations when nothing changed. Preserve work after a failed save. |
| A13 | P2 | **Switching the phone-order customer silently carries the previous draft.** `selectCustomer` clears only address selection; items, notes, promo and schedule remain. A different customer's instructions can be submitted with a newly selected customer. | Code risk: [NewOrderForm/selectCustomer](../../../apps/admin/src/app/(app)/orders/new/page.tsx#L58). | On a nonempty draft, offer “Start a new order” or explicitly retain a clearly labeled draft; clear customer-specific notes/promo/address by default. Show customer and contact in the final review. |
| A14 | P3 | **Every confirmation uses “Keep it” as its cancel action.** That wording is ambiguous for Mark delivered, refunds and other actions that are not retaining an object. | Code: [ConfirmDialog](../../../apps/admin/src/components/confirm-dialog.tsx#L50). | Allow context-specific cancel labels, such as “Go back” or “Don't mark delivered”; keep “Keep order” where appropriate. |
| A15 | P2 | **The dashboard chart has no equivalent accessible per-day data.** Counts are revealed on mouse hover; the graphic's accessible label gives only a generic description. Exact dates/values are not available in a keyboard-operable detail view. | Code: [DailyChart](../../../apps/admin/src/app/(app)/page.tsx#L189). | Add an accessible date/count/value table or keyboard-operable details. Keep the simple chart; a charting framework is unnecessary. |
| A16 | P2 | **Audit details are abbreviated raw JSON without an accessible detail view.** The table truncates at 140 characters and relies on a title tooltip for the full payload; no search/actor/entity/date filters exist. This makes resolving a changed bill unnecessarily difficult. | Code: [AuditPage summary/table](../../../apps/admin/src/app/(app)/audit/page.tsx#L27). | Add a readable expandable record with before/after fields and basic filters. Keep pagination. A keyboard or touch user must be able to inspect the full relevant event. |
| A17 | P1 | **Phone-order retries can create duplicates.** The customer endpoint supports an idempotency key, but the admin endpoint does not accept/pass one and the new-order client does not send one. A server commit followed by a lost response leaves staff with an unsafe retry. | Code risk: [admin place](../../../apps/api/src/orders/admin-orders.controller.ts#L55), [customer protected place](../../../apps/api/src/orders/orders.controller.ts#L30), [new-order submit](../../../apps/admin/src/app/(app)/orders/new/page.tsx). | Use one persistent key per admin draft/attempt and return the original result on retry. Verify a committed request with a deliberately lost response produces exactly one order. |
| A18 | P1 | **Concurrent item edits have no revision-conflict protection.** The replacement checks only the current status. Two staff editing an order in the same status can overwrite each other's quantities without a conflict; the UI has no revision warning. | Code risk: [updateMany guard/replacement](../../../apps/api/src/orders/orders.service.ts#L554), [items request](../../../apps/admin/src/app/(app)/orders/[id]/_components/items-card.tsx#L100). | Add an expected revision/updated-at check or equivalent atomic conflict guard. On conflict, show fresh versus draft items and let staff reconcile; never blindly replay the replacement. |

## Missing and partial customer features

“Selected” means already chosen in the 7 November decisions. “Next” is this review's recommendation. “Conditional” means prove operating capacity or demand first. “Deferred” means deliberately not part of the first build.

| ID | Feature | Current status / evidence | Priority and decision | Smallest useful completion |
|---|---|---|---|---|
| FC01 | Customer approval of increased totals | Missing; C01, no approval model/route in current schema or route inventory. | P1 · Selected | Old/new itemised bill, reason, accept/decline, expiry handling and server payment/delivery guards. |
| FC02 | Order-linked problem report, photos and visible progress | Missing; Help offers call/email/FAQ, no issue model or customer upload route. | P1 · Selected | Report type, order/item, description, evidence, ticket ID, status, response due time and resolution history. |
| FC03 | Refund status and accurate payment history | Partial; refund records already reach customer DTOs, but customer views rely on aggregates. | P1 · Next | Reuse refund records; add a customer-safe transaction summary only where needed for C04/C06. |
| FC04 | Reschedule an existing pickup/return | Missing; Help explicitly instructs cancel and book again. | P2 · Next | Choose new valid windows without losing order identity; communicate cutoff and any supported price consequence. |
| FC05 | WhatsApp support entry | Missing in app; marketing context assumes a fallback. | P2 · Next, confirm supported business number | Click-to-chat with order context and fallback. Do not build an official messaging platform first. |
| FC06 | Faster/express turnaround with explicit surcharge | Missing; scheduling uses one minimum-turnaround rule. | P2 · Conditional | Expose only when staff can fulfill it; quote the surcharge server-side before confirmation. |
| FC07 | Narrower capacity-backed pickup/return windows | Partial; current fixed windows are 07–11, 11–16, 16–20. | P2 · Conditional | Configured windows, closed dates and capacity limits; do not merely relabel the broad slots. |
| FC08 | Telugu/Hindi UI and translated catalogue | Missing; `supportedLocales` contains only en-IN. | P2 · Next after core trust | Translate core booking/support and validate script fonts and large text; choose rollout order using actual customer language needs. |
| FC09 | Structured garment-care preferences | Missing; one general checkout instruction field exists. | P3 · Conditional | Only operationally supported choices such as fold/hanger/starch plus item notes, visible to workshop staff. |
| FC10 | Post-delivery rating with problem-report path | Missing UI/API. | P3 · Conditional | One rating, optional note and direct escalation for a problem; no points economy. |
| FC11 | Notification preferences and permission recovery | Partial; permission explainer and inbox exist, no preference controls. | P2 · Next | Distinguish promotional preference from essential order updates; link to OS settings when appropriate. |
| FC12 | Different return address | Backend `deliveryAddressId` exists; checkout sends only pickup address and admin form explicitly returns to the same address. | P3 · Conditional | Separate return address only if the business supports it, with coverage and quote validation. |
| FC13 | Share/download bill or transaction receipt | Partial; views exist, no share/export action found. | P3 · Conditional | Shareable accurate receipt/bill; establish tax/business requirements before promising a tax invoice. |
| FC14 | Coverage and prices before sign-in | Public API exists; normal app onboarding requires sign-in/address setup. | P3 · Conditional | Read-only PIN-code coverage/rate preview before asking for authentication. |
| FC15 | Recurring/repeat-scheduled pickups | Missing; Book again already exists. | P3 · Deferred until repeat demand measured | Start with reminders or rebooking; automate recurring jobs only after capacity/cancellation rules are defined. |
| FC16 | First-order free-garment campaign | Missing eligibility/pricing; draft artwork exists for two shirts and two pants. Percent/flat coupons cannot express that promise. | P2 · Required before campaign activation | Server-enforced first-order and eligible-garment quantities, accurate quote and admin preview. |
| FC17 | Live partner map | Missing customer map; location data exists for dispatch, partner client missing. | P3 · Deferred | Validate need and location consent/freshness first. Reliable status and a contact path come first. |
| FC18 | Wallet/prepaid balances | Missing implementation; schema proposal only. | P3 · Deferred by owner | Do not implement until accounting, refunds, expiry and reconciliation rules are settled. |
| FC19 | Referral/loyalty rewards | Missing implementation. | P3 · Deferred by owner for referrals; validate loyalty | Prove acquisition/repeat value before adding financial reward state. |
| FC20 | Subscription/prepaid service plans | Missing implementation. | P3 · Deferred | Validate recurring demand and service economics before selling commitments. |
| FC21 | Business/bulk customer mode | Missing implementation; product context says later. | P3 · Deferred | Start with an assisted account/invoice workflow when actual business customers need it. |

Sources for the inventory: [customer routes](../../../apps/customer/lib/app/routes.dart), [Help](../../../apps/customer/lib/features/account/help_screen.dart), [app locale](../../../apps/customer/lib/app/app.dart), [schema](../../../apps/api/prisma/schema.prisma), [checkout request](../../../apps/customer/lib/features/checkout/checkout.dart), [prior baseline](../../../replica/irondost-baseline.md), [campaign implementation note](../IMPLEMENTATION.md). The prior claim that a damage/loss **policy** is absent is too broad: [shared terms](../../../packages/legal/legal.json) already contain a 48-hour reporting rule, repair/replacement/refund wording and a liability basis. The missing product capability is a trackable claim and its operating workflow. Legal adequacy was not assessed here.

## Missing and partial admin features

| ID | Feature | Current status / evidence | Priority and decision | Smallest useful completion |
|---|---|---|---|---|
| FA01 | Price-change request workflow | Missing; direct items replacement exists. | P1 · Selected | Proposed/accepted bills, delta/reason, pending/accepted/declined/expired states and action guards. |
| FA02 | Issue queue, ownership and response clock | Missing route/model; no support case workspace. | P1 · Selected | Queue by due/overdue, assignee, customer evidence, staff response, resolution and auditable history. |
| FA03 | Usable partner field client | Not started; partner API/dispatch exist, runbook requires staff transitions. | P1 operational dependency · Selected after Trust core | The selected Flutter partner app: jobs, accept/decline, online/location state, collection/handover, cash confirmation; field-test it. Do not substitute a new client stack. |
| FA04 | Capacity, holidays, configurable slots and express controls | Missing operating model; current settings configure cutoffs/turnaround, not per-window capacity. | P2 · Conditional | One service calendar and capacity rule feeding both clients. |
| FA05 | Delivery-date and overdue exception queues | Partial; order board has pickup date, status, partner-needed and refund-due filters. | P2 · Next | Exact KPI destinations, overdue pickup/return views and status age. |
| FA06 | Partner cash settlement/reconciliation | Partial; individual cash records exist, no partner/day closeout workflow found. | P2 · Next | Due versus collected versus handed-over by partner/day with an auditable discrepancy note. |
| FA07 | Searchable payment/refund ledger and export | Partial; per-order payment/refund tools and refund-due list already exist. | P2 · Next | Cross-order reconciliation, pending/failed provider exceptions and a simple export. Do not rebuild working refunds. |
| FA08 | Intake count acknowledgment and garment/bag evidence | Partial; items/events exist, no photo/evidence or bag/handover record. | P2 · Conditional | A count receipt and small evidence record; barcode/RFID infrastructure is not justified yet. |
| FA09 | Claim-resolution and compensation workflow | Missing issue-linked resolution; manual refunds already supported. | P2 · After FA02 | Record agreed remedy/amount and link to existing refund/payment records; keep policy wording consistent. |
| FA10 | Recoverable order drafts and safe retry | Missing persisted draft; A12/A13/A17. | P1 for idempotent retry; P2 for draft UX | One saved draft and attempt key, explicit customer reset, safe response-loss recovery. |
| FA11 | First-order/eligible-garment promotion rules | Missing; current promotion types are percent/flat and usage-limited. | P2 · Before advertising FC16 | Eligible items/quantities/first-order check plus a test-customer quote preview. |
| FA12 | Translated customer content management | Missing locale-specific catalogue/campaign fields. | P2 · With FC08 | Manage supported translated names/copy; avoid an elaborate CMS. |
| FA13 | Notification delivery/recovery visibility | Partial; stored inbox exists, no staff delivery-failure/retry view or customer marketing preference workflow found. | P2 · Conditional | Expose actionable failed-delivery state for critical messages and a manual support fallback. |
| FA14 | Investigable audit log | Partial; paginated truncated payloads, no filters/detail view. | P2 · Next | A16's filterable, expandable before/after record. |
| FA15 | Funnel, crash and service-quality measurements | Missing customer analytics/crash reporting dependencies; dashboard measures order/payment totals only. | P2 · Next, keep small | Booking attempts/completions, price approvals, issue response, on-time pickup/return and crash signals. No general analytics platform rebuild. |
| FA16 | Task-specific staff permissions | Partial; ADMIN/SUPER_ADMIN boundaries exist, no separate workshop/finance role found. | P3 · Conditional on staff duties | Add only permissions a real staff role needs; current server authorization is not being declared absent. |
| FA17 | Catalogue import and guarded bulk operations | Missing import/bulk tools; normal CRUD exists. | P3 · Conditional on measured workload | CSV preview and validation or one justified bulk action; preserve undo/audit where needed. |
| FA18 | Wallet, rewards, subscription and B2B administration | Missing implementation; corresponding customer features are deferred. | P3 · Deferred | Build only with the approved customer capability and accounting/operations rules. |

Sources: [admin route inventory/sidebar](../../../apps/admin/src/components/app-sidebar.tsx), [order board](../../../apps/admin/src/app/(app)/orders/page.tsx), [business settings](../../../apps/admin/src/app/(app)/settings/_components/settings-form.tsx), [schema](../../../apps/api/prisma/schema.prisma), [staff runbook](../../staff-delivery-runbook.md), [existing build plan](../../../replica/plans/build-plan.md). “No screen found” is limited to this repository. Volume-dependent recommendations are not first-build commitments.

## Vanity Engineering Assessment

### Summary

The core stack is proportionate: one API/database, ordinary CRUD boundaries, server-owned prices, a shared contract and reusable Flutter components. Reliable payments, ownership checks, background dispatch jobs and accessibility checks solve real problems; do not remove them to reduce a file count. The avoidable complexity is concentrated in dispatch operating before its field client exists, duplicated unit/payment interpretation, and dormant presentation assets. The proposal documents contain more future systems than the current launch needs, but draft SQL is not deployed architecture.

### Requirement-to-Complexity Ratio

**RCR: 4/10, provisional.** This is a qualitative source-review judgment, not a measured production benchmark. There is no evidence supporting a microservice rewrite, a new frontend framework or a generalized workflow/plugin engine. The missing Trust core warrants a small extension to the existing domain.

### Top findings

| Pattern | Where | Severity | Why current requirements do not justify it | Simpler alternative | Estimated simplification effort |
|---|---|---|---|---|---|
| Automatic dispatch without an operating partner client | [dispatch](../../../apps/api/src/dispatch/dispatch.service.ts), [runbook](../../staff-delivery-runbook.md), A11 | V2 · Structural, conditional on the documented manual operating mode still being current | Retries, online/location eligibility and failure alerts cannot create an online rider when no client exists. Staff carry the operational burden while the UI implies automation. | Expose an honest manual mode and clear assignment queue until the selected Flutter client is field-tested. Preserve the API/dispatch capability for that rollout. | 1–2 developer days for explicit mode/copy/queue behavior; field client is separate work. |
| Domain meaning reimplemented in screens | [paidHow](../../../apps/customer/lib/core/order_text.dart), [items card](../../../apps/admin/src/app/(app)/orders/[id]/_components/items-card.tsx), C02/C06/C07/A10 | V1 · Drag | Each surface invents what paid/refunded/pieces means, creating inconsistent customer outcomes and repeated fixes. | One server payment/refund summary and small shared unit formatters in each client. No generic state-machine framework. | 1–3 days, depending on customer payment-contract changes. |
| Dormant bundled heading fonts after the typography decision | [pubspec fonts](../../../apps/customer/pubspec.yaml), [current tokens](../../../packages/design-tokens/customer.tokens.json), [capture harness](../../../apps/customer/tool/audit/capture_test.dart) | V1 · Drag, small | Current production display tokens use Junction; source search found Outfit font references in the audit harness, not production text styles. Three Outfit weights remain declared/bundled, about 168 KiB of filesystem blocks before compression. The raster logo does not require those font files. | Confirm release/custom-font use, then retain historical assets outside the shipped bundle and remove unused production declarations. | 1–2 hours plus one build/capture check. |
| Full future wallet/reward schema before the first trust workflow | [broad schema proposal](../../../replica/schema.sql), [decisions](../../../replica/plans/decisions.md) | V1 · Proposal risk only; **not deployed debt** | Building parked financial systems would create reconciliation obligations before evidence of demand. This is not an allegation that those tables are live. | Follow the existing Trust-core-only migration plan. Keep wallet/rewards parked until accounting rules and a measurable customer need exist. | No removal required; keep them out of implementation scope. |

**Vanity debt estimate:** planning range **4–10 person-hours/month**, low confidence, for investigating duplicate presentation rules and manual/automatic-dispatch confusion if these paths are changed or operated regularly. No timesheets, traffic data or incident data establish an actual monthly cost; actual cost may be lower, including near zero for dormant paths. Proposed wallet systems contribute **zero current runtime maintenance hours**. Do not use this estimate as a financial forecast.

**The hard question:** If the next development cycle shipped no new typography, wallet or loyalty features, but every changed price required consent and every problem had an accountable response, what customer value would be lost?

## Project-specific continuation and kill criteria

This is a **proposed operating framework**, not an enabled automation or authority to shut down services. Named feature owners, an independent named enforcement owner and business acceptance of thresholds are not recorded in the repository. The owner must supply them before adopting this framework; the reviewer has not fabricated names or approval. The baseline user volume, existing hosting bill and support availability are also unknown.

### Day-0 setup and scope

Project: IronDost Trust core and operational reliability. Preparation date: 14 November 2026. Evaluation window: first **30 days after pilot rollout**, with a review after the first seven days. Execution owner: the engineering lead to be named by the business. Enforcement owner: a different operations/product lead to be named by the business. Those assignments are **not yet established**.

Proposed incremental recurring-vendor budget: **₹0/month** for the initial Trust-core slice, reusing existing API/database/storage. This is a scope proposal, not a statement about current hosting costs. Any new recurring vendor cost requires an explicit business budget decision before enabling it. SMS, storage and existing infrastructure usage must be baselined in Day 0; a total-spend kill threshold cannot responsibly be invented from the repository.

| Reviewed system / feature group | Primary success test | Measurement and evidence needed before rollout |
|---|---|---|
| FC01/FA01 price approval, C01/A01/A02/A18 | 100% of increases require valid customer consent; 100% of unchanged lines retain their accepted rate. | Stored original/proposed bill and revision, request/decision events; query for any increased collectible amount without approval. |
| FC02/FA02/FA09 problem reports | 100% of successful submissions create a durable case ID and visible status; pilot target of at least 95% first responses within the **business-approved** clock. | Case-created, first-response and due timestamps; overdue queue. The old 4-hour clock remains a proposal, not customer copy. |
| C02–C06, FA06/FA07 money presentation and reconciliation | Zero false paid/completed-refund messages; every captured payment/refund traces to its real method, amount and time. | Provider/payment/refund records compared with customer/admin views; pending/failed/partial/cash/mixed fixtures and reconciliation query. |
| A03/FA03 delivery and partner operations | Every recorded cash collection has explicit staff/partner confirmation; manual assignments and handovers remain possible. | Actor/time/amount on collection and handover; field task log. Automatic offers earn continuation only after a field-tested client exists. |
| A04–A09/A16, FA05/FA13/FA14 exception visibility | Failures never appear as empty/success; KPI destinations reproduce their counts; missed realtime updates recover. | Browser failure injection, reconnect check, paginated old-alert check and count/list comparison. |
| A12/A13/A17/FA10 admin draft and retry | Exactly one order per attempt despite response loss; customer context changes are explicit; dirty work is recoverable. | Idempotency integration scenario, two-customer draft scenario and dismissal/recovery check. |
| Customer visual system, C07–C09/A10/A14/A15, FC08 | Existing booking/recovery tasks remain operable at 200% text; accurate units and accessible alternatives; no new visual system without task evidence. | Current widget checks plus real-device task/keyboard/screen-reader checks; translated scripts when enabled. |
| FC04/FC06/FC07/FA04 rescheduling, speed and capacity | No invalid window is accepted; every advertised speed/fee is backed by capacity and quote rules. | Calendar/capacity and server quote checks; on-time outcomes in a staffed pilot. |
| FC05/FC09–FC14/FC16, FA08/FA11/FA12 small support/retention capabilities | A real workflow owner can demonstrate fulfillment; advertised offer eligibility matches the charged quote. | One end-to-end support/garment/campaign scenario per enabled feature; usage baseline set before a larger build. |
| Deferred FC15/FC17–FC21, FA16–FA18 | No implementation proceeds on parity alone. A specific paying-user/staff need and cost owner must first be documented. | Product decision and operating/accounting rules; inactive draft schemas are excluded from runtime usage metrics. |

### Tier 1 — hard containment triggers

The smallest affected mutation/optional feature is paused or rolled back; tracking, existing cases, audit history, balances and normal support must remain available. Never delete financial or garment evidence as a kill action.

| Trigger | Detection | Proposed action and enforcement |
|---|---|---|
| Any collectible increase without valid approval, or a frozen rate unexpectedly changes | Approval/bill audit query and incident report | Disable new item-increase mutations; preserve original accepted bills and manually reconcile. Switch/runbook must be tested before pilot. |
| Any duplicate order from replaying the same attempt | Unique attempt key/query and response-loss drill | Disable unsafe retry entry point; recover the original attempt result. Do not silently cancel/refund real orders. |
| Any payment/refund view asserts success for an unconfirmed/failed transaction | State comparison and support incident | Roll back the misleading presentation or show neutral confirmation-pending state; preserve reconciliation/support access. |
| Security incident or P0/P1 incident attributable to a newly enabled optional path | Incident record | Contain that path using a tested rollback; incident owner validates restoration. No automatic deletion or unreviewed database reversal. |
| A new recurring paid integration is enabled outside the agreed budget | Billing/config review | Disable the optional integration and retain the existing fallback. Existing essential hosting is excluded. |

For each enabled switch: record its scope, alert on a suspicious state before collection, test the rollback in a nonproduction drill, and keep a short incident template containing impact, affected orders, containment, reconciliation and prevention. These mechanisms are requirements for future rollout, **not implemented by this report**.

Automatic zero-usage decommissioning is deliberately omitted for core booking, support, accessibility, payment/refund and audit paths: rare use can still be essential. Dependency vulnerability triage is a security-maintenance process; this review does not assert a fresh CVE count or prescribe blind service shutdown.

### Tier 2 — mandatory review within 48 hours

- Pilot response-clock performance below the approved target for seven operating days: stop advertising the unmet promise; simplify staffing/scope before continuing.
- More than eight unplanned engineering hours in a month on an optional component, or repeated unplanned work across three delivery cycles: require measured customer value and a simpler alternative before expansion. The eight-hour threshold is proposed and must be accepted by the team.
- Repeated reconciliation discrepancies, invisible exception queues or lost drafts: pause feature expansion until the affected workflow is reliable.
- A second engineer/operator cannot complete the documented task without the author after one working day: simplify the workflow/runbook. If the team has only one maintainer, name a backup plan instead of claiming a nonexistent second person.
- An optional feature has zero use for 30 operating days: review whether to hide or remove it. Never apply this criterion to emergency recovery, legal access, accessibility or essential records.

Continuation requires a named owner, an explanation supported by data, and a correction within 14 days; otherwise stop expanding or disable the optional path with the fallback retained.

### Tier 3 — earn continuation in the 30-day pilot

All relevant deterministic integrity checks above must pass; no unresolved attributable P1 money/consent issue may remain. Response and fulfillment targets must be approved using actual staffing/capacity, not copied from competitor promises. Measure endpoint and task latency in the pilot; set an agreed P95 target from that baseline before claiming performance success. A rollback drill, non-author runbook review and operating-cost review must be recorded. Missing measurements mean the feature has not yet earned expansion; they do not justify erasing core customer records or shutting down support.

Anti-vanity controls:

1. Every new abstraction needs at least two actual consumers or a concrete test/boundary justification. Existing repository interfaces used for deterministic fixtures are not automatically waste.
2. Every new dependency/vendor needs a specific problem, simpler alternative and accepted maintenance/cost owner.
3. Every feature proposal must name the user task and what could be simpler; visual similarity and competitor presence are insufficient acceptance criteria.
4. No speculative wallet/reward/B2B schema enters the Trust-core migration. No generic workflow engine or additional service is needed for the two selected workflows.
5. Ninety days without code changes is only a review signal; stable working code is not a deletion candidate merely because it is quiet.

Enforcement calendar: Day 0 assign owners/approve thresholds/baseline costs/test switches; Day 1 start a limited staffed pilot; Days 7, 14 and 21 review evidence; Day 30 graduate only with complete evidence; Day 90 recheck value; Day 180 reconsider optional complexity. Dates are relative to the actual rollout, which has not been scheduled in this audit.

## Build order and closure criteria

| Order | Deliverable | Findings / features | Done when |
|---|---|---|---|
| 1 | Correct money truth and safe staff actions | C02–C06, A03/A17/A18 | Pending/failed/partial/mixed payment/refund states are accurate; receipt uses transaction truth; retries create one order; concurrent edits conflict; cash is explicitly confirmed. |
| 2 | Complete the already-selected price-consent workflow | C01/A01/A02, FC01/FA01 | Frozen rates, a before/after quote, approval/decline/expiry and payment/delivery guards are implemented across API, customer and admin. Reuse existing backend/build plans; update them where current phone semantics differ. |
| 3 | Complete the already-selected issue workflow | FC02/FA02/FA09, C08/C09 | Customer submits a durable case with evidence, staff own a due/overdue queue, and customer sees responses/resolution. Choose the response clock with operations before exposing it. |
| 4 | Repair admin visibility and recovery | A04–A16, FA05/FA10/FA14 | Exceptions cannot silently disappear; alerts paginate; reconnect refreshes; customer draft changes and dismissals are safe; audit/chart details are accessible. |
| 5 | Deliver the selected partner client and validate field operations | FA03, A11, FA06 | Actual partners can receive/complete jobs and explicitly record collections; staff can reconcile and fall back to manual work. |
| 6 | Add evidence-backed convenience | FC04–FC14/FC16, applicable admin counterparts | Capacity, language demand, support ownership and campaign eligibility justify each enabled feature. Wallet/rewards/subscriptions/B2B stay parked. |

No reliable total delivery estimate is possible without team capacity and the unresolved operating decisions. The existing size estimates in [TASKS.md](../../../TASKS.md) are planning inputs, not a release-date commitment.

## Remaining verification work

1. Admin desktop and narrow-screen walkthrough against a controlled API, including keyboard navigation, screen reader, long data and error states. The failed browser attachment leaves this explicitly open.
2. Real Android/iOS checks for Maps/denied location, SMS/Google auth, contact editing, Razorpay success/cancel/webhook delay, push/realtime and phone/email/store handlers.
3. Real-device VoiceOver/TalkBack, OS keyboards and 200% text across complete journeys, including shell navigation and Add number. Automated assertions do not certify those interactions.
4. Business validation of live catalogue, minimums, fees, support hours, damage remedies and actual service area. The 7 November placeholder-price observation is historical and was not rechecked against production here.
5. A small observed usability session: first booking, change delivery window, recover an uncertain payment, find a refund and report a missing garment. Record task completion/errors before claiming conversion gains.

## What is already present and should not be rebuilt

Phone and Google sign-in; editable contact number; saved addresses and coverage checks; item search and quantity steppers; server quotes and promo validation; separate pickup/return selection; online/COD and existing-order balance payment; payment recovery; tracking and honest overdue labels; cancellation before pickup; Book again; offers and inbox; help and public legal routes; logout/deletion restrictions; light/dark design and existing accessibility checks. Admin already has orders, phone orders, customers, manual assignment, per-order cash/refunds, refund-due filters, alerts, catalogue/promotions/banners, settings, staff, app versions and audit pagination.

Passing checks establish a useful baseline. They do not close the source-reviewed defects or the unbuilt Trust core.
