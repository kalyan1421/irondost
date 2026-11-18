# Test plan

replica-test output, adapted to what IronDost already has. Date 2026-11-07. **No end-to-end or device tests were run in this pass.** What was run is stated in the Result column.

## Existing test assets (from the repo, not re-run here unless noted)

- API unit tests (`pnpm --filter @laundry/api test`: pricing, slots, order flow, signatures). Run today, result in [deploy.md](deploy.md).
- API e2e (`test:e2e`, throwaway database per run), `apps/api/test/app.e2e-spec.ts`.
- Flutter customer tests: 398 passed per `docs/ui-ux-audit/IMPLEMENTATION.md` (5 Oct 2026); layout, large-text, keyboard and contrast checks at 320, 390 and 430 dp.
- No browser tests exist for `apps/admin` or `apps/web`. New admin pages and the public price list should get Playwright specs with an axe scan.
- Real-device checks the repo itself lists as open: Maps and denied location, SMS autofill, Razorpay native flows, push and realtime, TalkBack and VoiceOver.

## Rules for the new work

Test IronDost, never the competitors' servers. Use test Razorpay keys and test cards only. Selectors by role and label. Every new customer route gets a second-customer test: it must return nothing of the first customer's data. Fail on console errors and any 5xx.

## Cases

Result: **DB** = proven in the schema test on a throwaway database (35 of 35 passed, [architecture.md](architecture.md)); **not run** otherwise.

| Case | Flow | Type | Steps | Expected | Auto | Result |
|---|---|---|---|---|---|---|
| F01-H1 | Book with a visible price | happy | Add 3 ironing items, schedule, pay by test card | Basket total equals quote equals bill; order confirmed | API e2e plus Flutter | not run |
| F01-E1 | | edge | Address outside the service area | Clear outside-area screen; no order | Flutter | not run |
| F01-E2 | | edge | Pick a slot inside the cut-off | Slot unavailable with a reason | API e2e | not run |
| F01-E3 | | edge | Basket below the minimum order | Shortfall shown; Pay disabled with a reason | Flutter | not run |
| F01-E4 | | edge | Double tap Place order | One order (idempotency key) | API e2e | not run |
| F01-N1 | | negative | Test card declined (`4000 0000 0000 0002`) | Recovery screen; no paid order | manual, test mode | not run |
| F01-N2 | | negative | Cancel after pickup | Blocked with the reason | API e2e | not run |
| EXP-H1 | Express | happy | Enable express in admin; choose it | Fee shown beside the option; total includes it | API e2e plus Flutter | not run |
| EXP-E1 | | edge | Express disabled | No express option shown | Flutter | not run |
| EXP-E2 | | edge | Old app version posts without a speed | Treated as STANDARD | API e2e | not run |
| EXP-E3 | | edge | Fee on a STANDARD order | Rejected | DB | **DB passed** |
| EXP-E4 | | edge | Express turnaround set longer than standard | Rejected | DB | **DB passed** |
| SLOT-E1 | Windows | edge | Window ends before it starts, no days, day 8 | Rejected | DB | **DB passed** |
| SLOT-E2 | | edge | Two customers book the last place at once | One succeeds, one gets "slot full" | API e2e with concurrency | not run |
| RES-H1 | Reschedule | happy | Move pickup before the rider is assigned | New slot; dispatch re-runs; event logged | API e2e | not run |
| RES-N1 | | negative | Reschedule after pickup, or a 4th time | Blocked | API e2e; DB for the 4th | **DB passed** (limit only) |
| ISS-H1 | Problem report | happy | Report damage with 2 photos | Issue OPEN; staff alert; customer sees status | API e2e plus Flutter | not run |
| ISS-E1 | | edge | 6 photos; resolved without a time | Rejected | DB | **DB passed** |
| ISS-E2 | | edge | No staff reply by the due time | Overdue alert raised by the job | API e2e with clock control | not run |
| ISS-N1 | | negative | Second customer opens the first customer's issue | Nothing returned (404) | API e2e | not run |
| ADJ-H1 | Price change | happy | Staff change the count; customer approves | New total applies; payment allowed | API e2e plus Flutter | not run |
| ADJ-E1 | | edge | Second open request on the same order | Blocked | DB | **DB passed** |
| ADJ-E2 | | edge | Customer does not answer in time | EXPIRED; old total stands (policy to confirm) | API e2e | not run |
| ADJ-E3 | | edge | Pay while a request is pending | Blocked with the reason | API e2e | not run |
| WAL-H1 | Wallet | happy | Top-up by test card, then spend at checkout | Ledger shows credit and debit; balance right | API e2e | not run |
| WAL-E1 | | edge | Same Razorpay webhook delivered twice | One credit | API e2e; DB for key replay | **DB passed** (replay) |
| WAL-E2 | | edge | Overspend; edit or delete a ledger row | Rejected; balance unchanged | DB | **DB passed** |
| WAL-E3 | | edge | Two spends at the same moment | Serialised; never negative | concurrency test | not run |
| WAL-N1 | | negative | Delete the account of a user with a balance | Policy: block or anonymise, ledger kept | API e2e | not run |
| REF-E1 | Referral | edge | Refer yourself; refer the same person twice | Rejected | DB | **DB passed** |
| REF-H1 | | happy | Referee's first delivered order | Both rewards written once | API e2e | not run |
| WEB-H1 | Public price list | happy | Open the page | Prices equal `GET /catalog`; no console errors; axe clean | Playwright | not run |
| A11Y-1 | New screens | edge | 200% text at 320, 390 and 430 dp, light and dark | No clipping; AA on every token pair | Flutter capture harness | tokens passed (26 of 26) |

## Bugs

None reproduced in this pass, so there is no `bugs.md`. Items that need checking, not bugs: whether the live catalogue holds placeholder prices ([pricing.md](launch/pricing.md)); and whether "Available in Hyderabad" matches the service-area setting. Competitor reviews also show an update that crashed an app on launch (LaundryMate, App Store), which is a reason to keep IronDost's forced-update gate and roll out in stages.

## Summary

Cases planned: 33. Run: the schema checks only (35 constraint tests on the full schema and 17 on the Trust-core migration, all passed). Open S1 or S2: not assessed. Next: building starts at step 2 of the build order in [architecture.md](architecture.md), and each fix gets a failing test first.
