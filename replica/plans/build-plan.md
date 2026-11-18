# Build plan: Trust core, then the partner app

replica-build, as a plan. Date 2026-11-07. Scope and choices: [decisions.md](decisions.md). Backend work: [backend-plan.md](backend-plan.md) (items B0 to B8). Nothing is built.

## Rules that apply to every screen (from the pack and the repo)

- **Clean room.** Write every label, empty state and message fresh. Take no markup, assets, copy or colours from the competitors ([design/design-teardown.md](../design/design-teardown.md) lists patterns to adapt, not to copy).
- **Tokens only.** No raw hex or pixel values in components; use the existing customer tokens and component contracts (`docs/ui-ux-audit/DESIGN_SYSTEM.md`: one primary action, divided rows, 52 dp buttons, 48 dp targets, AA contrast, 200% text).
- **Every state:** empty, loading (skeleton), filled, error, offline, long text (60-character names, long addresses), 200% text, and widths 320, 390 and 430 dp, light and dark.
- **Basics every time:** semantic labels, keyboard and screen-reader reachable, visible focus, no console errors.
- **Per screen:** update the matching row in [features.csv](../features.csv), save a capture to `replica/clone-screens/`, add a line to [build-log.md](../build-log.md), one commit `build: S48 report a problem`.
- **Test first for each fix**, and keep the repo's gates green: `flutter analyze`, `flutter test`, the capture harness in `apps/customer/tool/audit` for the real-font renders.

## Part A: customer app (`apps/customer`)

New IDs continue the repo's S01 to S47.

| ID | Screen | Contents | States to build |
|---|---|---|---|
| S48 | Report a problem | Order summary row, category as selectable rows, description with counter, up to 5 photos with remove, "Send report" in the bottom bar | empty; validation (category or text missing); uploading (progress, cancel); offline; send failed with retry; success hands off to S49 |
| S49 | Report detail | Status ("Open", "Seen by our team", "Resolved"), the reply-by line only if the owner commits to the clock, message thread, reply field, resolution note | loading skeleton; no replies yet; new reply arrives (push); closed; error |
| S50 | Your reports | List per account and a short list on the order page | empty ("No reports"); loading; error |
| S51 | Approve new total | Action sheet over the order: before and after lines, old and new total, reason, **Approve** (primary) and **Decline** | loading; deciding (button busy); already decided or expired (explain, no actions); error with retry; long item names; 200% text |
| S22 (change) | Order tracking | A "needs your OK" row when a request is open; a "Report a problem" action next to the existing call action (`_CallUs`) | open request; none; cancelled and delivered orders |
| Push routing | Notification deep links | Adjustment and issue pushes open S51 or S49 (extend `routeForPush` in `features/push/push_handler.dart`) | order not found; signed out |

Where the code goes: `lib/features/issues/` (repository, controller, screens), an adjustment sheet beside `lib/features/orders/`, new routes in `app/routes.dart` and `app/router.dart`, generated models after the contract refresh (`swagger_parser`, per `apps/customer/README.md`). Components to reuse, by their real files in `lib/design/widgets/` and `lib/features/`: `showIdSheet` (`id_sheet.dart`) and `alert_sheet.dart` for the approval sheet, `ReviewRow` (`review_row.dart`), `StateView` and `ListStateView` (`state_view.dart`), `StatusChip`, `order_card.dart`, `order_timeline.dart`, `id_button.dart` and `id_text_field.dart`, `CartBar` (`cart_bar.dart`, the docked action bar) and `QuoteBill` (`features/basket/quote_bill.dart`, the bill lines). The design-system document uses different names for these contracts (`ActionSheet`, `PriceSummary`, `BottomActionBar`); confirm each class before using it.

Definition of done for Part A: S48 to S51 and the S22 change built with all states above; widget tests for each state; the real-font capture harness run at 320, 390 and 430 dp, light and dark, and at 200% text; contrast pairs still 26 of 26; the offline and error paths exercised; analyze and tests green; `docs/ui-ux-audit/IMPLEMENTATION.md` updated.

## Part B: admin (`apps/admin`, now Next.js 16.4.5)

**Read the bundled docs in `apps/admin/node_modules/next/dist/docs/` before writing any admin code**, as `apps/admin/AGENTS.md` says: this Next.js differs from older versions.

| ID | Page | Contents | States |
|---|---|---|---|
| A01 | Reports queue | Table with status filter, order number, category, age, due time; overdue rows highlighted and sorted first; keyboard-navigable | empty; loading; error; many rows (paging) |
| A02 | Report detail | Thread, photos (viewer with alt text), actions: acknowledge, reply, resolve with a note, reject; links to the order and to the refund page | not found; already resolved; saving; failure |
| A03 | Order page: items card (change) | When a staff edit would raise the total, say plainly that the customer must approve, show the pending request and its history; when the customer declines or the request expires, show the choice (continue at the original count, or cancel the pickup) | pending; approved; declined; expired |
| A04 | Settings (change) | Two new fields: first-response hours and approval window, each with a short "customers will see this" note | validation |
| A05 | Dashboard (change) | A tile for overdue reports and one for open price requests | zero; many |

Gates: `pnpm --filter @laundry/admin typecheck lint build` (CI runs these), plus Playwright with an axe scan for A01 and A02 (the repo has no browser tests today; adding them is part of this work). The typed client comes from `pnpm --filter @laundry/admin gen:api` and CI checks it matches the contract.

## Part C: partner app (new Flutter app, `apps/partner`)

You chose a native app for riders. The rider API exists; this is client work. Size **L**. Start after backend item B2, because a rider's item edit now creates an approval request, and the rider must see "waiting for the customer".

### C0. Confirm before starting
- **Android first.** Riders mostly use Android; iOS later. (Open question.)
- **Folder:** `apps/partner`, inside the workspace beside `apps/customer`. The README says `mobile/partner`; update whichever is not used.
- **Distribution:** Play internal testing or Firebase App Distribution, not a public listing, at least until the pilot ends.
- **Identity:** a new application ID (for example `com.irondost.partner`) in the existing Firebase project; sign-in by phone OTP; riders are added by an admin, matched by phone (as the README describes).
- **Location consent:** riders must be told what is collected and when (only while online), with a consent screen and a data-safety entry.

### C1. Scaffold
Flutter project with the same stack as the customer app (Riverpod, go_router, dio and retrofit generated from the same contract via `swagger_parser`, Firebase auth and messaging, secure storage). A partner token file and generator modelled on `tool/gen_tokens.dart`, tuned for use outdoors: larger type, 56 dp touch targets, AA contrast at minimum and higher where possible, one-handed layouts.

### C2. Screens

| ID | Screen | Notes |
|---|---|---|
| P01 | Sign in | Phone OTP; clear message if the phone is not registered as a rider |
| P02 | Today | Tasks grouped by pickup and delivery with the window; online toggle; empty state when nothing is assigned |
| P03 | Offer | Incoming offer with the 20-second countdown from the server's expiry, accept or reject; expired and "taken by someone else" states |
| P04 | Task detail | Address, call the customer, open maps, items so far, status actions |
| P05 | Count and edit items | Stepper per line; shows the new total; submitting an increase shows "waiting for the customer" until approved, declined or expired |
| P06 | Pickup | Condition photos, then "Picked up"; blocked with the reason while a price request is open |
| P07 | Delivery | "Out for delivery", then "Delivered"; cash collection once the API supports it ([backend-plan.md](backend-plan.md), partner gaps) |
| P08 | Permissions | Location and notification rationale before the system prompts; foreground-service explanation |
| P09 | Account | Name, phone, online status, sign out |
| P10 | System states | Offline, server unavailable, forced update, account paused (reuse the customer app's patterns) |

Background location while online, push for offers (FCM) and the socket events (`offer.created`, `order.updated`) are part of C2, not extras. Not in scope: earnings, in-app chat, route optimisation, iOS, an offline queue.

### C3. Quality gates and field test
Widget tests with a fake API (copy the customer app's `test/helpers.dart` and fixtures approach); analyze and tests green; large-text and contrast checks; then a field pilot with two or three riders on real orders in LB Nagar, with a written checklist (sign-in, offer accept, location updates, item edit, photo upload, mark picked up and delivered, poor signal, phone call and maps hand-off). Fix what the pilot finds before widening.

## Order of work

1. B0 characterisation tests, then B1 and B2 (price freeze, approval).
2. In parallel, once the contract is refreshed: S51 and A03 (approval), and B3 and B4 then S48 to S50 and A01 to A02 (reports).
3. B5 and B6, A04 and A05, S22 changes; run the whole Trust-core pilot with staff.
4. Partner app C1 onward.

Parallel work is safe when file sets are disjoint: backend (`apps/api`), customer (`apps/customer`), admin (`apps/admin`) and partner (`apps/partner`) do not overlap; the contract file `packages/contracts/openapi.json` is the one shared artefact, so only one person regenerates it at a time.

## Done means

Trust core: the tests for ADJ and ISS in [test-plan.md](../test-plan.md) pass, all four parts above are built with their states, and the pilot (staff plus a few customers) ran without an S1 or S2 bug. Partner app: the C3 field checklist passes with real riders.
