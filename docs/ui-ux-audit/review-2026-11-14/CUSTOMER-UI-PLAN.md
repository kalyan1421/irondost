# Customer app UI audit and fix plan

Audited 15 November 2026 from the fixture captures in [customer/](customer/) and [fixed-customer/](fixed-customer/) (390 x 844 dp, light and dark) and from `apps/customer/lib`. Nothing here was checked on a device.

## Method and limits

The design-taste skill is written for web landing pages and lists native mobile apps as out of scope, so it was used only where it carries over: colour, shape and theme consistency, contrast, empty/loading/error states, copy, hierarchy and density. Its hero, eyebrow, marquee, motion and em-dash rules were not applied to a task-driven app.

**Design read:** native consumer app for households in Hyderabad, calm and trust-first, built on the existing IronDost tokens (royal, ink, sun, Junction headings). Dials: variance 3, motion 2, density 4. No new visual direction is proposed.

## What already holds up (do not redo)

- Tokens are respected: no hard-coded colours (one `Colors.black` shadow base), radii come from `IdRadius` (one literal `2` on a progress bar), two `fontSize: 18` overrides.
- Light and dark parity is good. Contrast reads fine in both themes in the captures.
- One icon family (Lucide), one shape scale, status colours used consistently (amber = needs attention, green = done, blue = action).
- Loading, empty, offline and error states exist for the main screens.

## Findings

| ID | Priority | Finding | Evidence |
|---|---|---|---|
| U01 | P1 | **New report screens bypass the design system.** The report form uses Material floating-label inputs and a default dropdown, while every other form uses the label-above `IdTextField`. Reply box, pagination and order link use raw `TextField`/`TextButton`. The app now has two input styles. | `fixed-customer/report-problem-light.png`; `features/issues/issue_screens.dart` lines 138, 142, 184, 220, 236, 240. `IdTextField` already supports `minLines`, `maxLines`, `maxLength`. |
| U02 | P1 | **Text links sit inside the page gutter.** The global `TextButton` theme adds 12 dp horizontal padding, so "Track order", "How it works", "View all" and every "Change" link start 12 dp right of the 20 dp text edge or end 12 dp short of it. It reads as misalignment. About 20 raw `TextButton`s in `features/`. | `customer/home-light.png`; `design/theme.dart` `textButtonTheme` (padding `IdSpace.s3`). |
| U03 | P1 | **Orphaned words.** "PM" alone on its own line in the home order card; "order" alone in "You cancelled this order". The time-range helper already uses no-break spaces around the dash but not before the meridiem. | `customer/home-light.png`, `fixed-customer/refund-pending-tracking-light.png`; `core/slots.dart` line 44. |
| U04 | P1 | **Refund amount stated three times** on a cancelled order: banner, refund row, and the "Amount" line. The refund row is four lines of equal weight. | `fixed-customer/refund-pending-tracking-light.png`; `order_detail_screen.dart` lines 328, 343; `refund_list.dart`. |
| U05 | P1 | **Price-approval sheet is a flat list.** Every line is body text; amounts are not right-aligned; the changed quantity (4 to 6) is not highlighted; "Accepted total" touches the divider. This is the highest-stakes money screen. | `fixed-customer/price-approval-review-light.png`; `price_approval.dart`. |
| U06 | P2 | **Cancelled hero chip stretches full width** instead of hugging its label. | `fixed-customer/refund-pending-tracking-light.png`. |
| U07 | P2 | **Order detail repeats itself.** The amber five-segment bar duplicates the blue timeline and uses a different colour meaning; "Call us" floats alone under it; the "Your partner ... once they accept" placeholder shows at step 3 when pickup is already done; the amber due banner repeats the sticky Pay button. | `customer/order-detail-light.png`. |
| U08 | P2 | **Welcome screen is the emptiest screen in the app**: wordmark, headline, one small card and a large void, while home carries the product renders. | `customer/welcome-light.png`. |
| U09 | P2 | **Checkout payment choices fall below the first screen.** Already flagged in the original audit. Test a compact payment summary with Change near the footer before compressing review rows. | `customer/checkout-light.png`. |
| U10 | P3 | **Placeholder and copy details.** Two literal "—" placeholders for an unknown total (`basket_screen.dart` 507, `order_detail_screen.dart` 250); "Your report will appear in Your reports" repeats a capitalised noun; large blank gap above "Items" on the bill screen. | `basket_screen.dart`, `report-problem-light.png`, `order-bill-light.png`. |
| U11 | P3 | **Two image styles at home**: raster product renders for services beside outline icons everywhere else. Acceptable if intentional; record it as the rule (renders for services only). | `customer/home-light.png`. |

## Fix plan

Order is by risk and reuse: shared components first so later screens inherit the fix.

**Step 1. Shared fixes (U02, U03)** (done 15 Nov, local). Small, touches many screens.
- Change `textButtonTheme` so the visible label has no horizontal inset while the tap target stays 48 dp (use zero horizontal padding plus `tapTargetSize`/`minimumSize`, or add `IdButton.text` as the one link style and migrate raw `TextButton`s).
- Bind the meridiem to the time with no-break spaces in `slots.dart` and the home order-card string; use balanced wrapping (or a shorter headline) for "You cancelled this order".
- Done when: links align with the 20 dp gutter in the home, checkout, help and offers captures; no single-word last lines at 390 dp or at 200% text on 320 dp.

**Step 2. Bring the report screens onto the design system (U01)** (done 15 Nov, local).
- Replace the report form, reply box and category picker with `IdTextField` and one shared select pattern (a labelled field that opens the existing bottom-sheet style); give "Add photos" an icon and show picked photos as thumbnails with remove.
- Done when: `report-problem` and `report-conversation` captures match `edit-profile` field styling; analyzer and the issues tests pass.

**Step 3. Rebuild the price-approval sheet (U05)** (done 15 Nov, local).
- Before/after rows with right-aligned amounts, the changed quantity marked ("4 to 6"), a clear subtotal/discount/delivery block, the new total as the only large figure, and spacing fixed under the accepted total. Keep the existing Approve / Decline / Close order and wording.
- Done when: the 320 dp / 200% text stress test passes and the capture reads at a glance without scrolling to find the delta.

**Step 4. Cancelled and refund view (U04, U06)** (done 15 Nov, local).
- Keep one refund banner and one refund row (amount, status chip, method on one line, note below); drop the "Amount" repetition; make the status chip content-width.
- Done when: the refund amount appears once in the captures for pending, completed and failed refunds.

**Step 5. Order detail (U07)** (done 15 Nov, local).
- Remove the segmented bar (keep the timeline), put "Call us" in the header help row or beside the status, show the partner row only when a delivery partner is assigned, and fold the due message into the sticky Pay bar.
- Done when: tracking, paid and cancelled captures keep every existing fact with fewer repeated lines.

**Step 6. Welcome and checkout (U08, U09), then polish (U10, U11)** (done 15 Nov, local; see Status for what changed from the plan).
- Welcome: reuse the existing product renders with one headline and the same two buttons; no new copy claims.
- Checkout: compact payment summary row with Change near the footer, then re-check the fold at 390 dp.
- Replace the "—" placeholders with "Calculating..." or hide the row; fix the "Your reports" sentence.

## Status

Steps 1 to 6 are implemented locally. Steps 1 to 4 are committed (`e9b0741`); steps 5 and 6 are not yet committed.

- Steps 1 and 2: link theme without side padding, no-break spacing for time windows and the last two words of headlines, new `IdSelectField` (sheet picker) and `IdFieldError`, report form, reply box and report list links on `IdTextField`/`IdButton.text`.
- Step 3: the price-approval sheet is a before/after bill (changed items first, quantity change marked, new and removed items tagged, right-aligned amounts, one large new total).
- Step 4: each refund is one row (amount, content-width status chip, method and date, note) under a "Refund" heading; the refund sentence only appears when there are no rows or money no refund accounts for; the "Cancelled" chip hugs its label.
- Step 5: the five-segment bar is gone (the words and the timeline carry progress). A missed delivery estimate is one amber notice with Call us inside it. The "Your partner ... once they accept" placeholder only shows while the order is still pending. The due-amount notice moved into the pay bar as one line under the Pay button.
- Step 6: the welcome screen shows the same bundled iron and washer artwork as home. The bill's items line up with its totals. A delivered order with no pickup time has no "Picked up" row instead of a dash.

Changes from the plan:

- **Checkout (U09):** instead of a Change sheet, both payment options sit in the footer beside the Pay button ("Pay with": Pay online, Cash on delivery), so cash on delivery stays one tap away and nothing is below the fold. The footer shrinks to the button while the note keyboard is up.
- **Basket total (U10):** the "—" while a new price is on its way is kept. It is deliberate (the bar does not change width) and has an accessible label.
- The text-link padding change in step 1 broke the spacing between "Terms of service" and "Privacy policy"; it is fixed by setting the gap on the links row. No other adjacent links depended on the old padding.

493 tests pass, `flutter analyze` is clean, fixture captures render in light and dark, and the 200% text stress suites pass at 320, 390 and 430 dp (including keyboard layouts and the report and refund screens). Captures are fixtures, not a device.

## Verification for every step

`flutter analyze`, `flutter test` (currently 481 pass), regenerate the fixture gallery (`tool/audit/capture_test.dart`) and compare light and dark, and run the 320 dp / 200% text stress suite. Real-device checks (VoiceOver, TalkBack, Dynamic Type) remain open from the original report and are not closed by captures.

## Not in scope

New features from `features.csv`, a new visual direction, or any change to the token palette.
