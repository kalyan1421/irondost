# IronDost customer app — UI and UX audit

Date: 5 October 2026. Scope: Flutter customer app only. This document records the original baseline and approved plan. Implementation is now complete for the customer UI pass; see [implementation evidence](IMPLEMENTATION.md) and [before-and-after review](implemented.html). The findings and measurements below remain the original audit evidence.

## Assessment

The application has a solid booking flow and reusable components. Its visual identity is weakened by repeated bubbles, oversized tinted blocks, nested cards, pill controls and repeated illustrative logo use. The result gives booking, discounts, reassurance and order status similar visual weight. Keep the recognizable IronDost logo colours and reduce the UI to clear task headings, divided lists, compact summaries and one primary action.

## Verified locally

- `flutter analyze` from `apps/customer`: no issues in the baseline or final audit-tooling check.
- `flutter test --reporter expanded`: 376 tests passed. Four missed-tap warnings occurred in account-deletion accessibility tests; these passes are not proof of the blocked interaction.
- The audit capture harness rendered 47 views in light and dark: 94 passing capture tests. Images use the application widgets and fake repositories, with loaded Outfit, Figtree, Geist Mono and icon fonts. They are not redesigned Flutter screens.
- The baseline capture viewport is 390 × 844 dp. Tab screens are captured in isolation, without AppShell navigation; native captures show the actual navigation and safe areas. Fixture catalogue, amounts and dates may differ from local API data.
- At 320 × 740 dp and 200% text, 68 of 78 stress cases passed and 10 failed: five variants in both themes. Failures are catalogue (+24 px right), map fallback (+136 px bottom), outside-area map (+136 and +140 px bottom), confirmation (+6.8 px right), and payment failure (+19 px right). These are real-widget layout checks with loaded fonts, not device certification.
- At 390 × 740 dp and 200% text, 74 of 78 cases passed. The map fallback and outside-area variants overflowed by 16 px in both themes.
- Native iPhone 17 Pro / iOS 26.5 walkthrough against `http://localhost:4000`: Home → catalogue → basket → schedule → checkout; Orders → tracking; Offers; Account → profile, saved address editing and Help. Native screenshots are in `screens/native-*.png`. No checkout order, charge, cancellation, deletion, profile edit or address edit was submitted.
- Native Home omitted two active orders visible in Orders. An in-progress order still displayed an expired delivery estimate without an overdue explanation. Account navigation rows appeared as text in the native accessibility tree.

## Limits and remaining checks

Google Maps rendering, real Firebase SMS, Razorpay native checkout, external call/email/store targets, live push and realtime delivery, Android hardware, VoiceOver/TalkBack operation and keyboard-open screen coverage have not been manually certified. Widget tests exercise important associated logic and states. Tablet and desktop layouts are outside the customer v1 scope; use a centred phone-width layout rather than inventing tablet navigation. Stress-tested forms must still be checked with the actual software keyboard.

## Design direction

Use white content surfaces, restrained brand-blue actions, dark ink text, consistent 20 dp gutters and flat divided lists. Keep the existing four-tab structure and all booking/payment/order rules. Use a brand symbol only where recognition is the task. Remove decorative bubbles from functional screens; remove repeated card shadows and icon tiles. Yellow marks savings or eligibility in a small area. Status colours communicate actual state and always have text.

## Critical findings and dependencies

| Priority | Finding | Implementation owner and scope |
|---|---|---|
| P1 | Five screen variants overflow at 320 dp / 200% | Flutter layout changes; no business-rule changes. |
| P1 | Policies are plain text at sign-in, and redirect rules block signed-out policy reading | Link styling plus router access change; preserve auth protection on every other route. |
| P1 | Home does not surface active orders | Add a presentation module using the existing order provider; a functional presentation change beyond visual token cleanup. |
| P1 | Expired ETA remains presented as future promise | Derive an overdue presentation from existing dates/status, require product-approved wording; do not change dispatch. |
| P1 | Account navigation lacks clear button semantics | Shared IdListRow semantic wrapper; verify actual screen reader behavior. |
| P1 | Refund and area-notification copy promise behavior the current workflow does not provide | Align copy with current capabilities; do not implement a waitlist or automatic refund as part of this audit. |
| P1 | Existing delete-blocked tests can miss the Delete tap | Make missed taps fatal, assert the API-fake call and blocked heading. |
| P2 | Fonts are fetched at runtime despite app-plan wording that says bundled | Bundle required font weights and licences, disable runtime font fetching; then recapture layouts. |

## Screen-by-screen changes

### S01 · Launch · Phase 2

Route: `/launch`. Source: [`apps/customer/lib/features/system/system_screens.dart`](../../apps/customer/lib/features/system/system_screens.dart).

**Finding:** The full signature and tagline shrink into a small centre lockup. The tagline carries no launch task.

**Change:** Use the primary wordmark on the surface colour; remove the tagline. Keep native and Flutter launch visually continuous.

**Acceptance:** No flash between launch screens; wordmark stays legible in both themes.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/launch-light.png) · [Dark capture](screens/launch-dark.png).

### S02 · Welcome · Phase 1

Route: `/welcome`. Source: [`apps/customer/lib/features/auth/welcome_screen.dart`](../../apps/customer/lib/features/auth/welcome_screen.dart).

**Finding:** Logo, repeated washer illustration, bubbles and three icon tiles compete. The one-day return statement is not tied to the selected service or schedule.

**Change:** One wordmark, one short headline, a two-line service explanation and Get started. Replace the fixed return promise with “Choose your pickup and delivery times.” Make Terms and Privacy actual links.

**Acceptance:** Start is visible with the keyboard closed at 320 dp; policy links open while signed out; no duplicate brand illustration.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/welcome-light.png) · [Dark capture](screens/welcome-dark.png).

### S03 · Mobile number · Phase 1

Route: `/login`. Source: [`apps/customer/lib/features/auth/phone_screen.dart`](../../apps/customer/lib/features/auth/phone_screen.dart).

**Finding:** Terms and Privacy are plain text. An enabled submission button accepts an incomplete input and then reports an error.

**Change:** Make policy links independently accessible; use “Send code” as the action. Keep the country code fixed and the field persistent after errors; show validation below the field.

**Acceptance:** Both policies work without a session; invalid and network states preserve the number; action stays visible with the keyboard.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/phone-light.png) · [Dark capture](screens/phone-dark.png).

### S04 · Verify code · Phase 2

Route: `/login/code`. Source: [`apps/customer/lib/features/auth/otp_screen.dart`](../../apps/customer/lib/features/auth/otp_screen.dart).

**Finding:** Six outlined boxes, a blue reassurance panel and a bottom button add competing containers.

**Change:** Keep the six-box input and autofill. Replace the blue panel with a muted line; make Change number and resend countdown clear secondary actions.

**Acceptance:** Pasting six digits, SMS autofill, wrong code, expiry and resend are readable and do not reset the wrong field.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/otp-light.png) · [Dark capture](screens/otp-dark.png).

### S05 · Profile setup · Phase 2

Route: `/setup/name`. Source: [`apps/customer/lib/features/auth/name_screen.dart`](../../apps/customer/lib/features/auth/name_screen.dart).

**Finding:** The progress bar and Step 1 of 2 are useful, but form copy and optional email compete with the required name.

**Change:** Use a standard left-aligned form. Name first, optional email second, small receipt explanation; keep the existing two-step setup.

**Acceptance:** Required and optional fields are explicit; Continue remains reachable at 200% text and with a keyboard.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/name-light.png) · [Dark capture](screens/name-dark.png).

### S06 · Choose address: map fallback · Phase 1

Route: `/setup/pin and /address/pin`. Source: [`apps/customer/lib/features/addresses/map_pin_screen.dart`](../../apps/customer/lib/features/addresses/map_pin_screen.dart).

**Finding:** With maps disabled most of the screen is an empty tinted panel. At 320 dp and 200% text, the fallback Column overflows by 136 px.

**Change:** Replace the fake map area with a compact search and location page. Constrain the summary and put long content in a scrollable region. Use the real map layout only when the map is available.

**Acceptance:** Fallback works with denied location and no Maps key; no overflow at 320 × 740 dp / 200% text.

Evidence: Captured; overflow reproduced in both themes. Google Maps SDK rendering was not tested. [Light capture](screens/map-pin-fallback-light.png) · [Dark capture](screens/map-pin-fallback-dark.png).

### S07 · Address outside service area · Phase 1

Route: `/setup/pin and /address/pin`. Source: [`apps/customer/lib/features/addresses/map_pin_screen.dart`](../../apps/customer/lib/features/addresses/map_pin_screen.dart).

**Finding:** The outside-area summary can overflow by 140 px. Copy says the app will tell the customer when the area is served, but no area-alert signup exists.

**Change:** Use an inline warning with Change location first and Save for later second. Remove the unimplemented notification promise; keep the ability to save an unserviceable address.

**Acceptance:** Both actions stay reachable at 200%; saved unserviceable addresses continue to block booking.

Evidence: Captured; overflow reproduced in both themes; source confirms no area-alert registration. [Light capture](screens/map-outside-area-light.png) · [Dark capture](screens/map-outside-area-dark.png).

### S08 · Place search · Phase 2

Route: `/address/search`. Source: [`apps/customer/lib/features/addresses/place_search_screen.dart`](../../apps/customer/lib/features/addresses/place_search_screen.dart).

**Finding:** The idle screen is mostly empty. Failed search provides a message without an explicit retry control.

**Change:** Use a simple search list with a short instruction; give errors a Try again action using the current query. Keep street and area above city and PIN.

**Acceptance:** Three-character debounce, clear, no matches, denied location and retry all preserve the query.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/place-search-light.png) · [Dark capture](screens/place-search-dark.png).

### S09 · Address details: add and edit · Phase 2

Route: `/setup/pin/details and /address/details`. Source: [`apps/customer/lib/features/addresses/address_form_screen.dart`](../../apps/customer/lib/features/addresses/address_form_screen.dart).

**Finding:** A floating location card, large input gaps and a destructive action close to Save make the form heavy. The default switch may be disabled without explaining why.

**Change:** Use a flat location summary, standard 20 dp form spacing and 8 dp label gaps. Keep delete separate at the end; explain an already-default address instead of relying on a disabled switch.

**Acceptance:** Partial geocoder results, Other label, edit prefill, default and delete confirmation remain intact.

Evidence: Rendered add form; native edit form, existing default and delete affordance reviewed. [Light capture](screens/address-form-light.png) · [Dark capture](screens/address-form-dark.png).

### S10 · Saved addresses · Phase 2

Route: `/account/addresses`. Source: [`apps/customer/lib/features/addresses/addresses_screen.dart`](../../apps/customer/lib/features/addresses/addresses_screen.dart).

**Finding:** Every address is a rounded panel; default and unavailable status can compete with the label.

**Change:** Use divided address rows with one default badge and a separate serviceability line; keep Edit explicit and Add address prominent. Retain the Account back stack.

**Acceptance:** Default, chosen and unavailable are distinguishable; long addresses wrap; management does not change the checkout address accidentally.

Evidence: Native screen and rendered fixtures reviewed. [Light capture](screens/addresses-light.png) · [Dark capture](screens/addresses-dark.png).

### S11 · Home · Phase 1

Route: `/home`. Source: [`apps/customer/lib/features/home/home_screen.dart`](../../apps/customer/lib/features/home/home_screen.dart).

**Finding:** A large promotional hero takes priority while two active orders exist elsewhere. Home has no active-order module despite the app plan. Bubbles and icon-in-card tiles repeat brand decoration.

**Change:** Use a compact booking introduction and royal CTA; put the current order and next date above services for returning customers. Convert services to clear price rows; use a small offer row. Keep the four tabs.

**Acceptance:** An active order is visible without scrolling at 390 dp; all three services are available; new customers see booking first.

Evidence: Native Home and Orders verified against local API; source confirms no Home order subscription. [Light capture](screens/home-light.png) · [Dark capture](screens/home-dark.png).

### S12 · Choose items · Phase 1

Route: `/book`. Source: [`apps/customer/lib/features/catalogue/catalogue_screen.dart`](../../apps/customer/lib/features/catalogue/catalogue_screen.dart).

**Finding:** The informational row overflows by 24 px at 320 dp / 200% text. Large icon thumbnails repeat a generic shirt for unrelated garments; blue pill steppers dominate the list.

**Change:** Use a divided price list, neutral quantity controls and a single-line helper that wraps naturally. Show real thumbnails only when supplied and reliable; use a consistent small fallback icon otherwise.

**Acceptance:** At 320 dp / 200%, helper and rows fit; plus/minus remain at least 48 dp; prices and quantities never truncate.

Evidence: Native catalogue reviewed; helper overflow reproduced in both themes. [Light capture](screens/catalogue-light.png) · [Dark capture](screens/catalogue-dark.png).

### S13 · Item search · Phase 2

Route: `/book/search`. Source: [`apps/customer/lib/features/catalogue/search_screen.dart`](../../apps/customer/lib/features/catalogue/search_screen.dart).

**Finding:** Results repeat the full card row and can make the same garment under two services hard to distinguish.

**Change:** Use the same divided ItemRow as catalogue; put service beside the price/unit and give the no-result state a clear Clear search action.

**Acceptance:** Shirt in Ironing and Wash and iron remain distinct; matching and empty results preserve the query.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/catalogue-search-light.png) · [Dark capture](screens/catalogue-search-dark.png).

### S14 · Basket · Phase 2

Route: `/basket`. Source: [`apps/customer/lib/features/basket/basket_screen.dart`](../../apps/customer/lib/features/basket/basket_screen.dart).

**Finding:** The item group, promo action and bill are all raised cards, giving a secondary discount action equal weight to the amount owed.

**Change:** Use three flat sections: items, compact promo row and bill. Retain quantities and service groups. Keep the server quote, minimum shortfall and final-count explanation.

**Acceptance:** Quote refresh is visible without shifting the footer; promo and minimum-order errors sit next to their cause; totals are server-derived.

Evidence: Native basket and rendered fixtures reviewed. [Light capture](screens/basket-light.png) · [Dark capture](screens/basket-dark.png).

### S15 · Empty basket · Phase 3

Route: `/basket`. Source: [`apps/customer/lib/features/basket/basket_screen.dart`](../../apps/customer/lib/features/basket/basket_screen.dart).

**Finding:** A large circular icon with bubbles looks like an illustration template and uses more space than the instruction.

**Change:** Use a small basket icon, one-line title, one sentence and Choose items.

**Acceptance:** One next action; no stale total or enabled Continue; readable at large text.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/basket-empty-light.png) · [Dark capture](screens/basket-empty-dark.png).

### S16 · Pickup and delivery · Phase 2

Route: `/basket/schedule`. Source: [`apps/customer/lib/features/schedule/schedule_screen.dart`](../../apps/customer/lib/features/schedule/schedule_screen.dart).

**Finding:** Date tiles, slot cards and a delivery card all compete. The current title says Pickup time although the page also chooses delivery.

**Change:** Title the screen “Pickup and delivery.” Use a date strip with weekday and date, divided radio rows for windows and a compact delivery summary with Change delivery time.

**Acceptance:** Closed slots state why; selected pickup updates eligible delivery; complete dates and time windows remain visible.

Evidence: Native future slot selection and checkout transition verified. [Light capture](screens/schedule-light.png) · [Dark capture](screens/schedule-dark.png).

### S17 · Checkout · Phase 2

Route: `/basket/schedule/checkout`. Source: [`apps/customer/lib/features/checkout/checkout_screen.dart`](../../apps/customer/lib/features/checkout/checkout_screen.dart).

**Finding:** The full address, tinted schedule block, large payment cards and bill card create a long stack. Scheduling is not an explicit editable row.

**Change:** Use address, pickup, delivery, payment and bill as flat review sections. One footer action includes the amount and payment consequence. Keep changing an address and returning to the schedule possible.

**Acceptance:** Cash versus online is explicit; slot-closed recovery keeps the basket; keyboard or 200% text never hides the action.

Evidence: Native checkout reached with local server quote; no order was submitted. [Light capture](screens/checkout-light.png) · [Dark capture](screens/checkout-dark.png).

### S18 · Payment failure and recovery · Phase 1

Route: `/order/:id/pay`. Source: [`apps/customer/lib/features/payment/payment_screen.dart`](../../apps/customer/lib/features/payment/payment_screen.dart).

**Finding:** The amount/order row overflows by 19 px at 320 dp / 200%. Copy states bank-return outcomes with more certainty than the app can verify.

**Change:** Stack amount and order ID at large text. Keep the booked-pickup notice, retry, cash fallback and server verification; use payment copy approved against the actual provider outcome.

**Acceptance:** Failure, cancellation, offline, unavailable and pending verification stay distinct; pending verification never asks for another payment.

Evidence: Failure captured and overflow reproduced in both themes; provider-native checkout not executed. [Light capture](screens/payment-failed-light.png) · [Dark capture](screens/payment-failed-dark.png).

### S19 · Pickup confirmation · Phase 1

Route: `/order/:id/confirmed`. Source: [`apps/customer/lib/features/orders/order_confirmed_screen.dart`](../../apps/customer/lib/features/orders/order_confirmed_screen.dart).

**Finding:** The summary header overflows by 6.8 px at 320 dp / 200% text. Bubbles and a large success emblem add decoration.

**Change:** Use a small success icon, pickup date/window as the strongest detail, stacked ID and payment status, then delivery and address. Keep Track order primary.

**Acceptance:** Payment badge can move to a new line; no clipping at 200%; COD amount and online Paid remain unambiguous.

Evidence: Overflow reproduced in both themes; fixture dates are not live order dates. [Light capture](screens/confirmed-light.png) · [Dark capture](screens/confirmed-dark.png).

### S20 · Active orders · Phase 2

Route: `/orders`. Source: [`apps/customer/lib/features/orders/orders_screen.dart`](../../apps/customer/lib/features/orders/orders_screen.dart).

**Finding:** IDs and payment badges lead the card; the task is finding the next pickup or delivery. Every order nests another tinted date panel.

**Change:** Lead each row with status and the next event; keep ID secondary, price right-aligned and one Track or Pay action. Keep Active and Past filters.

**Acceptance:** The next date, status and amount are visible at a glance; paging, refresh, due payment and navigation remain intact.

Evidence: Native two active orders and rendered paid/unpaid fixtures reviewed. [Light capture](screens/orders-light.png) · [Dark capture](screens/orders-dark.png).

### S21 · No active orders · Phase 2

Route: `/orders`. Source: [`apps/customer/lib/features/orders/orders_screen.dart`](../../apps/customer/lib/features/orders/orders_screen.dart).

**Finding:** “No orders yet” can appear after all orders have moved into Past, so it can misdescribe a returning customer. The CTA goes to Home rather than opening booking.

**Change:** Use “No active orders” for returning customers and a first-order empty message only when appropriate. Retain Past; make the button label match the destination.

**Acceptance:** A customer with delivered orders is not told they have never ordered; first order guidance is still useful.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/orders-empty-light.png) · [Dark capture](screens/orders-empty-dark.png).

### S22 · Order tracking and terminal states · Phase 1

Route: `/order/:id`. Source: [`apps/customer/lib/features/orders/order_detail_screen.dart`](../../apps/customer/lib/features/orders/order_detail_screen.dart).

**Finding:** The dark hero repeats bubbles; delivery ETA remained “Back by Sun 4 Oct” on an in-progress local order viewed on Mon 5 Oct. In dark mode the inverse hero turns almost white.

**Change:** Use status heading, actual next event, a simple timeline and partner details. If an estimated window has passed, explain that the estimate is overdue and offer support; do not invent a new ETA. Keep the status surface dark-neutral in dark mode.

**Acceptance:** Booked, delayed, pickup assigned, processing, delivery, delivered and cancelled are truthful; actual timeline steps are distinct from future targets.

Evidence: Native overdue in-progress seed order verified; captured processing state in both themes. [Light capture](screens/order-detail-light.png) · [Dark capture](screens/order-detail-dark.png).

### S23 · Items and bill · Phase 2

Route: `/order/:id/bill`. Source: [`apps/customer/lib/features/orders/order_bill_screen.dart`](../../apps/customer/lib/features/orders/order_bill_screen.dart).

**Finding:** Order metadata, items and totals are separated into several raised boxes. A fixture has 17 × ₹15 but a ₹248 total, so fixtures cannot prove arithmetic fidelity.

**Change:** Use a clean receipt layout with item, quantity, unit price and amount aligned; one divider before the total. Keep subtotal, delivery, discount, paid and due from server data.

**Acceptance:** A consistent fixture reconciles every line and total; counted quantity changes and refunds remain visible.

Evidence: Rendered fixture and source reviewed; arithmetic mismatch is fixture data, not a confirmed API bug. [Light capture](screens/order-bill-light.png) · [Dark capture](screens/order-bill-dark.png).

### S24 · Payment received · Phase 3

Route: `/order/:id/paid`. Source: [`apps/customer/lib/features/payment/payment_receipt_screen.dart`](../../apps/customer/lib/features/payment/payment_receipt_screen.dart).

**Finding:** The success illustration repeats the same bubble composition. A full-screen receipt adds large empty space around simple facts.

**Change:** Keep a compact success mark, amount, order ID, payment time and Back to order; use the receipt typography rules.

**Acceptance:** Only server-confirmed payments show Paid; amount/time remain readable and repeat payment is not offered.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/payment-receipt-light.png) · [Dark capture](screens/payment-receipt-dark.png).

### S25 · Notification inbox · Phase 2

Route: `/notifications`. Source: [`apps/customer/lib/features/notifications/notifications_screen.dart`](../../apps/customer/lib/features/notifications/notifications_screen.dart).

**Finding:** Every message is a card with an icon tile, adding unnecessary scanning cost. Mark all read can crowd the header.

**Change:** Use divided messages grouped by date, one unread dot, title, body and timestamp; keep Mark all read as a secondary action that wraps at large text.

**Acceptance:** Read/unread is not colour-only; order notifications open their order; pagination and mark-read failures remain recoverable.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/notifications-light.png) · [Dark capture](screens/notifications-dark.png).

### S26 · Offers · Phase 2

Route: `/offers`. Source: [`apps/customer/lib/features/offers/offers_screen.dart`](../../apps/customer/lib/features/offers/offers_screen.dart).

**Finding:** A large yellow featured card and repeated bubbles lead with decoration. Coupon applicability and terms are split across repeated badges and paragraphs.

**Change:** Use white divided offer rows. Show benefit, minimum/cap/expiry, then code and Copy code. Use yellow only for a small benefit marker.

**Acceptance:** A customer can see eligibility before copying; Copy code is consistently labelled and announced.

Evidence: Native three promotions and rendered fixtures reviewed. [Light capture](screens/offers-light.png) · [Dark capture](screens/offers-dark.png).

### S27 · No offers · Phase 3

Route: `/offers`. Source: [`apps/customer/lib/features/offers/offers_screen.dart`](../../apps/customer/lib/features/offers/offers_screen.dart).

**Finding:** An oversized emblem and bubbles suggest a missing promotional feature rather than a normal empty list.

**Change:** A small tag icon and brief neutral message; no false countdown or invented future offer.

**Acceptance:** No coupon controls when the list is empty; page remains a normal tab.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/offers-empty-light.png) · [Dark capture](screens/offers-empty-dark.png).

### S28 · Offer load failure · Phase 3

Route: `/offers`. Source: [`apps/customer/lib/features/offers/offers_screen.dart`](../../apps/customer/lib/features/offers/offers_screen.dart).

**Finding:** The large red icon gives a recoverable content failure the weight of an account or payment error.

**Change:** Use a calm inline load message and Retry; retain previously loaded content when available with its offline status.

**Acceptance:** Retry works; cached offers are not represented as freshly validated checkout discounts.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/offers-offline-light.png) · [Dark capture](screens/offers-offline-dark.png).

### S29 · Account · Phase 1

Route: `/account`. Source: [`apps/customer/lib/features/account/account_screen.dart`](../../apps/customer/lib/features/account/account_screen.dart).

**Finding:** Grouped cards are reasonable but over-elevated. Native accessibility exposes Saved addresses, Notifications, Help and legal links as text rather than buttons.

**Change:** Keep profile then divided settings groups; add navigation semantics to IdListRow with button role, label and value. Keep Delete account separate and accessible.

**Acceptance:** Screen reader announces every tappable row as actionable; ordering and destination are correct; delete is not the primary screen action.

Evidence: Native accessibility tree verified; IdListRow lacks an explicit actionable Semantics wrapper. [Light capture](screens/account-light.png) · [Dark capture](screens/account-dark.png).

### S30 · Edit profile · Phase 2

Route: `/profile/edit`. Source: [`apps/customer/lib/features/account/edit_profile_screen.dart`](../../apps/customer/lib/features/account/edit_profile_screen.dart).

**Finding:** The initials avatar occupies space without an editing action; contact support is a small inline InkWell. Isolated cold-start fixtures can render before the session resolves.

**Change:** Keep a compact form and a plain read-only phone row. Use a separate 48 dp Contact support action. Handle loading profile data before prefill instead of showing blank loaded fields.

**Acceptance:** Native prefill works; direct navigation during session loading is checked separately; support and Save are reachable at 200%.

Evidence: Native prefilled name/phone confirmed; blank fixture is a loading-path risk, not the normal native result. [Light capture](screens/edit-profile-light.png) · [Dark capture](screens/edit-profile-dark.png).

### S31 · Help and support · Phase 2

Route: `/help`. Source: [`apps/customer/lib/features/account/help_screen.dart`](../../apps/customer/lib/features/account/help_screen.dart).

**Finding:** Call/email cards, FAQ cards and a policy group repeat visual containers.

**Change:** Use two clear contact actions, then divided FAQ disclosure rows and policy links. Order context should be carried into the displayed instructions when opened from tracking.

**Acceptance:** Call/email open intended targets; FAQ is keyboard and screen-reader operable; no new chat channel implied.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/help-light.png) · [Dark capture](screens/help-dark.png).

### S32 · Terms of service · Phase 2

Route: `/legal/terms`. Source: [`apps/customer/lib/features/account/legal_screen.dart`](../../apps/customer/lib/features/account/legal_screen.dart).

**Finding:** Long policy text has a useful plain layout but no short contents navigation; signed-out access is currently redirected by the router.

**Change:** Keep the readable document layout, 16/24 body, 24 dp section gaps and a short contents index where helpful. Allow the policy route to be read before login. Do not rewrite policy substance in this design pass.

**Acceptance:** Readable at 200% and reachable from Welcome/Phone without signing in; policy text remains synced from the legal package.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/legal-terms-light.png) · [Dark capture](screens/legal-terms-dark.png).

### S33 · Privacy policy · Phase 2

Route: `/legal/privacy`. Source: [`apps/customer/lib/features/account/legal_screen.dart`](../../apps/customer/lib/features/account/legal_screen.dart).

**Finding:** Long policy text has a useful plain layout but no short contents navigation; signed-out access is currently redirected by the router.

**Change:** Keep the readable document layout, 16/24 body, 24 dp section gaps and a short contents index where helpful. Allow the policy route to be read before login. Do not rewrite policy substance in this design pass.

**Acceptance:** Readable at 200% and reachable from Welcome/Phone without signing in; policy text remains synced from the legal package.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/legal-privacy-light.png) · [Dark capture](screens/legal-privacy-dark.png).

### S34 · Cancellation and refunds · Phase 2

Route: `/legal/cancellation`. Source: [`apps/customer/lib/features/account/legal_screen.dart`](../../apps/customer/lib/features/account/legal_screen.dart).

**Finding:** Long policy text has a useful plain layout but no short contents navigation; signed-out access is currently redirected by the router.

**Change:** Keep the readable document layout, 16/24 body, 24 dp section gaps and a short contents index where helpful. Allow the policy route to be read before login. Do not rewrite policy substance in this design pass.

**Acceptance:** Readable at 200% and reachable from Welcome/Phone without signing in; policy text remains synced from the legal package.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/legal-cancellation-light.png) · [Dark capture](screens/legal-cancellation-dark.png).

### S35 · Notification permission · Phase 2

Route: `/notifications/allow`. Source: [`apps/customer/lib/features/push/notification_permission_screen.dart`](../../apps/customer/lib/features/push/notification_permission_screen.dart).

**Finding:** The preview repeats bubbles and stacked cards. “Offers only if you want them” implies an offer preference that is not offered on this screen.

**Change:** Use one small example order notification, a short explanation and Enable notifications / Not now. Keep transactional and promotional consent copy tied to controls that actually exist.

**Acceptance:** Skipping does not block tracking; requesting permission occurs only after tapping Enable; no unsupported offers preference is promised.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/notification-permission-light.png) · [Dark capture](screens/notification-permission-dark.png).

### S36 · Offline and server unavailable · Phase 3

Route: `/unavailable`. Source: [`apps/customer/lib/features/system/system_screens.dart`](../../apps/customer/lib/features/system/system_screens.dart).

**Finding:** Server errors show a generic error number to the customer and make broad order/payment safety claims.

**Change:** Use separate offline and unavailable messages, Retry, and Contact support only when useful. Keep diagnostics in logs; use precise reassurance about existing orders and retry behavior.

**Acceptance:** Retry does not lose the session; distinguish no connection, timeout and server error; no duplicate payment instruction.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/unavailable-light.png) · [Dark capture](screens/unavailable-dark.png).

### S37 · Force update · Phase 3

Route: `/update`. Source: [`apps/customer/lib/features/system/system_screens.dart`](../../apps/customer/lib/features/system/system_screens.dart).

**Finding:** The message says updating takes a minute and keeps the customer signed in; neither is guaranteed by this screen. Missing version data produces a disabled Update button in the fixture.

**Change:** Use neutral “Update to continue” copy and a verified store action. Explain recovery if the configured store URL cannot open.

**Acceptance:** Real version configuration gives an actionable store link; no dead-end disabled primary action on a required update.

Evidence: Rendered fallback has no version/store URL; valid store-link behavior remains a verification requirement. [Light capture](screens/update-light.png) · [Dark capture](screens/update-dark.png).

### S38 · Account paused · Phase 3

Route: `/paused`. Source: [`apps/customer/lib/features/system/system_screens.dart`](../../apps/customer/lib/features/system/system_screens.dart).

**Finding:** A very large state illustration and branded primary phone button obscure the short restriction explanation.

**Change:** Small warning icon, clear restriction, Call support and Email support; secondary Log out.

**Acceptance:** Support remains reachable; booking is blocked; Log out remains secondary and safe.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/paused-light.png) · [Dark capture](screens/paused-dark.png).

### S39 · Offline over saved content · Phase 3

Route: `Across tab screens`. Source: [`apps/customer/lib/features/shell/offline_banner.dart`](../../apps/customer/lib/features/shell/offline_banner.dart).

**Finding:** The dark banner is appropriate but competes with sticky controls on short screens.

**Change:** Keep a compact nonmodal status strip above navigation; use one Retry action and an accessibility announcement.

**Acceptance:** No action or tab is covered; cached data is identified; recovery refreshes data without repeated announcements.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/offline-banner-light.png) · [Dark capture](screens/offline-banner-dark.png).

### S40 · Address switcher · Phase 2

Route: `Modal from Home and checkout`. Source: [`apps/customer/lib/features/addresses/addresses_screen.dart`](../../apps/customer/lib/features/addresses/addresses_screen.dart).

**Finding:** Selected, default and serviceability each add their own visual status; edit and add controls can interrupt choosing.

**Change:** Use a radio list: label, address and availability. Keep default as secondary metadata; Add address last.

**Acceptance:** Selection changes the intended booking address; unavailable choice explains the consequence; long rows scroll.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/address-picker-light.png) · [Dark capture](screens/address-picker-dark.png).

### S41 · Apply promo code · Phase 2

Route: `Modal from Basket`. Source: [`apps/customer/lib/features/basket/promo_sheet.dart`](../../apps/customer/lib/features/basket/promo_sheet.dart).

**Finding:** Manual entry and available offers duplicate promotion copy; the input keyboard can shrink the sheet substantially.

**Change:** Code field and Apply first, inline validation, then eligible offer rows using the shared PromoRow. Keep the keyboard inset and scroll.

**Acceptance:** Empty, expired, used-up, minimum and offline responses remain distinct; a failed code never changes the accepted basket quote.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/promo-sheet-light.png) · [Dark capture](screens/promo-sheet-dark.png).

### S42 · Change delivery time · Phase 2

Route: `Modal from Schedule`. Source: [`apps/customer/lib/features/schedule/schedule_screen.dart`](../../apps/customer/lib/features/schedule/schedule_screen.dart).

**Finding:** The delivery sheet repeats date cards and multiple selectable surfaces from the pickup page.

**Change:** Reuse the same DateStrip and SlotRow with a clear “Delivery” title; keep unavailable windows disabled with reasons.

**Acceptance:** Earliest turnaround restriction is preserved; choosing a delivery date does not reset pickup.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/delivery-sheet-light.png) · [Dark capture](screens/delivery-sheet-dark.png).

### S43 · Pay amount due · Phase 2

Route: `Modal from Orders or tracking`. Source: [`apps/customer/lib/features/orders/pay_due.dart`](../../apps/customer/lib/features/orders/pay_due.dart).

**Finding:** The sheet repeats full checkout-style payment cards and a large amount/ID line.

**Change:** Amount first, order ID secondary, two neutral payment choices and an amount-specific CTA. Stack all metadata at large text.

**Acceptance:** COD and online continuation are distinct; existing booking is not duplicated; the entire sheet can scroll.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/pay-due-sheet-light.png) · [Dark capture](screens/pay-due-sheet-dark.png).

### S44 · Cancel order · Phase 1

Route: `Modal from tracking`. Source: [`apps/customer/lib/features/orders/cancel_order.dart`](../../apps/customer/lib/features/orders/cancel_order.dart).

**Finding:** Refund copy promises automatic full refund even though the app README says cancellation requires staff refund handling. Reasons and two actions form a long sheet.

**Change:** Keep optional reasons and consequences, but match refund wording to server/staff behavior. Use a bounded scrollable sheet and a clearly separated Keep order action.

**Acceptance:** Already-picked-up rejection is recoverable; no refund is represented as completed until it exists; cancel and keep are both reachable.

Evidence: Captured paid/unpaid-style sheet structure; refund workflow mismatch found by comparing source and customer README. [Light capture](screens/cancel-sheet-light.png) · [Dark capture](screens/cancel-sheet-dark.png).

### S45 · Log out confirmation · Phase 3

Route: `Modal from Account`. Source: [`apps/customer/lib/features/account/account_screen.dart`](../../apps/customer/lib/features/account/account_screen.dart).

**Finding:** The sheet is short and mostly useful; generic design spacing should not grow it into an illustration page.

**Change:** Use a concise consequence sentence and Log out / Stay signed in; reuse the standard sheet spacing.

**Acceptance:** Cancel preserves the session; confirmation explains this device will stop receiving updates.

Evidence: Rendered in light and dark; source reviewed. [Light capture](screens/log-out-sheet-light.png) · [Dark capture](screens/log-out-sheet-dark.png).

### S46 · Delete account confirmation · Phase 1

Route: `Modal from Account`. Source: [`apps/customer/lib/features/account/delete_account.dart`](../../apps/customer/lib/features/account/delete_account.dart).

**Finding:** Existing a11y tests warn that the Delete tap misses its target, including normal-size runs. This undermines the stated blocked-flow coverage.

**Change:** Keep a scrollable confirmation and plain consequences; target the button in tests, wait for scroll/transition completion, and assert the repository call and resulting state.

**Acceptance:** Both buttons are reachable at 200%; tests fail on missed taps; opening the sheet never deletes the account.

Evidence: New rendered sheet; existing suite produced four missed-tap warnings. [Light capture](screens/delete-account-sheet-light.png) · [Dark capture](screens/delete-account-sheet-dark.png).

### S47 · Deletion blocked by active orders · Phase 1

Route: `Modal after refused deletion`. Source: [`apps/customer/lib/features/account/delete_account.dart`](../../apps/customer/lib/features/account/delete_account.dart).

**Finding:** The existing test name says blocked, but its missed tap can leave the ordinary deletion confirmation on screen.

**Change:** Keep the short active-order explanation with View orders and Close. Test the actual rejection response and assert “Finish your orders first.”

**Acceptance:** Blocked deletion preserves the session; View orders works; test asserts the blocked message after a real hit-tested tap.

Evidence: New fixture interaction reached the real blocked state in both themes without changing local account data. [Light capture](screens/delete-blocked-sheet-light.png) · [Dark capture](screens/delete-blocked-sheet-dark.png).

## Phased implementation plan

### Phase 1 — usability and truthfulness

1. Fix flexible layouts in catalogue helper, fallback address page, outside-area summary, confirmation header and payment metadata. Use Wrap or vertical composition for the two metadata rows; replace the oversized fallback map with a scrollable search/location layout. Preserve all controls and data.
2. Correct shared navigation semantics, touch areas for support/policy links and sheet test hit targets. Make Terms/Privacy readable while signed out through a narrowly scoped router allowlist.
3. Replace fixed return, area-alert and automatic-refund promises with capability-accurate copy. Add overdue presentation and Home active-order visibility using existing API/provider data. These require small presentation/routing changes and must be reviewed as functional scope, not hidden in styling.
4. Repeat the 320 and 390 dp / 200% matrix with production fonts; assert blocked deletion behavior and all new navigation destinations. Verify policies before login.

**Exit:** zero overflows, all existing booking tests pass, real controls announce actionable roles, no unsupported promises, no expired ETA presented as a future guarantee.

### Phase 2 — shared system and screen refinement

1. Adopt the proposed token file through the existing generator. Bundle fonts. Define FlatSection, ItemRow, SlotRow, ReviewRow, PromoRow, OrderSummary, AppHeader and BottomActionBar in the design widget layer before styling screens.
2. Roll out to Home → catalogue/search → basket → schedule → checkout. Follow the screen entries above, keep server-quoted prices, quantities, slot constraints, idempotency and payment behavior.
3. Roll out to Orders/tracking/bill → addresses/account/help → offers/notifications → onboarding and system gates. Keep navigation and state ownership unchanged except the explicit Phase 1 changes.
4. Update README descriptions that contradict actual fonts, brand status and the implemented system. Replace obsolete external-artifact authority with the local system document and shared token package.

**Exit:** shared component states are consistent; routine lists have no raised-card nesting; prices, dates and long names wrap correctly; light/dark screenshot review passes.

### Phase 3 — states, motion and release evidence

1. Use content-shaped skeletons for initial catalogue, inbox, offers and order loading. Keep loading placeholders non-actionable and announce recovery once. Reserve spinners for immediate submitted actions.
2. Unify empty, offline, unavailable, paused, update, permission, cancellation and payment recovery views. Keep cached data where safe and explain quote revalidation.
3. Use 120–180 ms selection transitions and platform sheet motion; honour reduced motion. Avoid looping decorative animation.
4. Manually verify iOS/Android, screen readers, keyboard-open forms, small phones, denied location, map rendering, SDK checkout failure/success, stale estimates, external support actions and actual push/realtime. Refresh store screenshots only after the app redesign is implemented.

**Exit:** device-level state and accessibility checklist completed; store images and website app screenshots reflect the shipped app.

## Deliverables

- `index.html`: visual review board, before captures, screen findings and six proposed layout examples.
- `DESIGN_SYSTEM.md`: logo decision, tokens, component contracts and usage rules.
- `tokens.proposed.json`: version 2 token proposal in the current generator schema; not installed.
- `logo/manifest.json` and SVG files: final logo selection using existing master artwork.
- Proposed tokens were parsed by the existing generator with its output redirected to `/tmp`; no application token files were changed.
- `contrast.json`: measured semantic colour pairs for the proposal.
- `verification/`: baseline/capture/stress logs.
- `apps/customer/tool/audit/`: opt-in capture and stress harness; fixture-only, outside the normal test directory.
