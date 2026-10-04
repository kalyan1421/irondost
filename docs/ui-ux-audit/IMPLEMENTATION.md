# Customer UI/UX implementation

Implemented locally on 5 October 2026. Scope: `apps/customer`, its customer-specific token source, brand/font assets and customer documentation. All three approved phases have been applied to the customer interface. This report supersedes the baseline status, not the original findings, in `AUDIT.md`.

## Result

The app now uses a restrained version of the existing IronDost identity: outlined wordmark, neutral light/dark surfaces, bundled Outfit/Figtree typography, divided lists, smaller status icons, neutral quantity controls, flatter review sections and consistent 20 dp screen gutters. Repeated bubbles, decorative heroes, nested raised cards and navigation pills have been removed from the task flows.

Home displays actual active orders from the existing repository before service browsing, including a link to all active orders and a relevant next event. Home and catalogue now use three bundled transparent 3D service illustrations: steam iron, washer and hanging blazer. Admin category images take precedence, with the bundled artwork used during loading or failure. Catalogue and search share the same item rows. Basket retains editable quantities and server quotes. Scheduling explicitly names pickup and delivery; checkout has separate change controls for the address and both windows.

Policies open while signed out. Address search has retry; the maps-disabled flow has a useful scrollable form instead of a fake map. Default-address restrictions have a visible explanation. Profile prefill handles a session arriving after the screen, and support is a full-size action. Native account, service and support rows expose button roles. Empty active orders no longer claim that a returning customer has never ordered.

Tracking labels a missed delivery estimate without inventing another date; future timeline events say Estimated. Cancel/refund and payment-recovery copy no longer assumes an automatic refund or an unverified debit outcome. Update-link failure has a recovery message and support action. Notification permission copy describes both order updates and possible offers without promising a preference switch that does not exist.

Home also displays admin-managed images in a manual carousel with readable titles, Offers links and accessible next/previous controls. Promotion images come from the existing active-promotions endpoint, so their visibility follows the admin validity window when refreshed; standalone active banners remain supported. Duplicate image URLs appear once. There is no automatic rotation. Campaign changes reset the image, caption, link and page together. Booking links follow the same address/serviceability gate as the Home booking button.

The new Dasara and Diwali artworks are saved in [campaigns](campaigns/index.html) and scheduled in the **local** admin Promotions data: DASARA15 runs 10–22 October 2026; DIWALI10 runs 29 October–10 November 2026. Both require a ₹100 minimum order and cap discounts at ₹100. These dates apply the requested minus-10/plus-2-day rule to the [IIRS government calendar](https://www.iirs.gov.in/holidaycalender). The new-customer artwork is uploaded as an inactive local banner draft: the confirmed service is **Wash & iron for 2 shirts and 2 pants on the first order**. Existing percentage/flat coupons do not implement those free garments or first-order eligibility, so server-side pricing and eligibility are required before activation. The old local “Diwail 50%” logo board was preserved and deactivated because it conflicts with the requested offer. See the [configuration manifest](campaigns/manifest.json). No production data was changed.

Catalogue and search now distinguish loading, offline failure, no services and no query matches, with retry that keeps the query and saved basket. Orders, offers and notifications share a plain, scrollable list-state component; skeletons match the final divided rows. Notifications use compact status icons and dividers. Large-text review also found clipping in the search toolbar and a squeezed address summary: the input toolbar now grows with text and the pickup summary uses the shared reflowing review row.

## Installed identity and system

- Final logo assets: [manifest](logo/manifest.json). The selected existing outlined wordmark is used for welcome and Flutter/native iOS launch. The full illustrated signature remains a secondary brand asset. Launcher identity is retained.
- Token master: `packages/design-tokens/customer.tokens.json`; generate with `dart run tool/gen_tokens.dart` from `apps/customer`. The original shared token file is unchanged.
- Fonts: Outfit 500/600/700; Figtree 400/500/600/700; Geist Mono 500. All are bundled with OFL licences; production has no runtime Google Fonts dependency.
- Components: [design system](DESIGN_SYSTEM.md). `ReviewRow` handles labelled values/actions and reflow; existing buttons, sheets, date/slot controls, quantity controls, settings rows, cards and state views implement the same contracts.
- Native launch assets: run `node apps/customer/tool/gen_launch.mjs` from the repository root. iOS wordmark height is 32 pt; native dark launch backgrounds match the customer surface token. A successful local iOS rebuild includes these assets; frame-by-frame splash continuity still requires device release review.

## Verification

| Check | Result | Evidence |
|---|---|---|
| Flutter static analysis | No issues | [log](verification/implemented-analyze.log) |
| Customer test suite | 398 passed; no failed tests | [log](verification/implemented-tests.log) |
| Real-font screen captures, 390 × 844 dp | 94 passed: 47 representative views × two themes | [log](verification/implemented-captures.log), `after/` |
| 320 × 740 dp, 200% text | 78/78 passed | [log](verification/implemented-stress320.log) |
| 390 × 740 dp, 200% text | 78/78 passed | [log](verification/implemented-stress390.log) |
| 430 × 740 dp, 200% text | 78/78 passed | [log](verification/implemented-stress430.log) |
| Supplemental lifecycle states | 24 captures: 12 states × two themes; 24/24 stress checks at each of 320, 390 and 430 dp | [review](states.html), [capture log](verification/implemented-states.log) |
| Seven forms with a 300 dp keyboard inset | 14 normal-size and 14 large-text captures; 14/14 stress checks at each width above | [review](states.html), [large-text log](verification/implemented-keyboard-large.log) |
| Declared token contrast pairs | 28/28 passed | [ratios](contrast.json) |
| Diff whitespace | `git diff --check` clean | Local repository check |
| Android build and launch | Debug APK built and launched on Pixel 9 emulator; native UI automation could not bind its window | [final APK build](verification/implemented-android-build.log) · [launch](verification/implemented-android.log) |
| iOS build | Debug build succeeded and launched on iPhone 17 Pro / iOS 26.5 | Local Xcode/Flutter run |

Tests cover catalogue/search loading and recovery, campaign removal/reordering, campaign booking address checks, large-text input borders/address reflow, existing booking/payment/cancellation logic, public policy routing, active-order navigation, estimate boundaries, actual blocked deletion interactions, admin banner loading/paging/links, scheduled promotion artwork and image deduplication, and bundled 3D service assets. Account deletion accessibility tests now scroll to the real control, finish transitions and assert the repository rejection instead of allowing missed taps. The capture harness remains opt-in under `tool/audit/` and does not call real providers.

Native iOS walkthrough: Home → catalogue → basket → pickup/delivery → checkout; Orders → overdue tracking → contextual support; Offers; notification inbox and item search/clear; Account → profile and software keyboard → saved addresses → edit address → Help. Native safe areas, tabs, data and accessibility labels were inspected. No order, payment, cancellation, deletion, profile change or address save was submitted. Existing local basket selections were retained.

## Coverage of the original 47 views

These are representative screen/state families and overlays, not every permutation of data or provider state. Each row has an implemented Flutter capture in both themes. Existing readable legal layouts and operational restrictions were retained where appropriate.

| ID | Screen/state | Implemented captures |
|---|---|---|
| S01 | Launch | [Light](after/launch-light.png) · [Dark](after/launch-dark.png) |
| S02 | Welcome | [Light](after/welcome-light.png) · [Dark](after/welcome-dark.png) |
| S03 | Mobile number | [Light](after/phone-light.png) · [Dark](after/phone-dark.png) |
| S04 | Verify code | [Light](after/otp-light.png) · [Dark](after/otp-dark.png) |
| S05 | Profile setup | [Light](after/name-light.png) · [Dark](after/name-dark.png) |
| S06 | Choose address: map fallback | [Light](after/map-pin-fallback-light.png) · [Dark](after/map-pin-fallback-dark.png) |
| S07 | Address outside service area | [Light](after/map-outside-area-light.png) · [Dark](after/map-outside-area-dark.png) |
| S08 | Place search | [Light](after/place-search-light.png) · [Dark](after/place-search-dark.png) |
| S09 | Address details: add and edit | [Light](after/address-form-light.png) · [Dark](after/address-form-dark.png) |
| S10 | Saved addresses | [Light](after/addresses-light.png) · [Dark](after/addresses-dark.png) |
| S11 | Home | [Light](after/home-light.png) · [Dark](after/home-dark.png) |
| S12 | Choose items | [Light](after/catalogue-light.png) · [Dark](after/catalogue-dark.png) |
| S13 | Item search | [Light](after/catalogue-search-light.png) · [Dark](after/catalogue-search-dark.png) |
| S14 | Basket | [Light](after/basket-light.png) · [Dark](after/basket-dark.png) |
| S15 | Empty basket | [Light](after/basket-empty-light.png) · [Dark](after/basket-empty-dark.png) |
| S16 | Pickup and delivery | [Light](after/schedule-light.png) · [Dark](after/schedule-dark.png) |
| S17 | Checkout | [Light](after/checkout-light.png) · [Dark](after/checkout-dark.png) |
| S18 | Payment failure and recovery | [Light](after/payment-failed-light.png) · [Dark](after/payment-failed-dark.png) |
| S19 | Pickup confirmation | [Light](after/confirmed-light.png) · [Dark](after/confirmed-dark.png) |
| S20 | Active orders | [Light](after/orders-light.png) · [Dark](after/orders-dark.png) |
| S21 | No active orders | [Light](after/orders-empty-light.png) · [Dark](after/orders-empty-dark.png) |
| S22 | Order tracking and terminal states | [Light](after/order-detail-light.png) · [Dark](after/order-detail-dark.png) |
| S23 | Items and bill | [Light](after/order-bill-light.png) · [Dark](after/order-bill-dark.png) |
| S24 | Payment received | [Light](after/payment-receipt-light.png) · [Dark](after/payment-receipt-dark.png) |
| S25 | Notification inbox | [Light](after/notifications-light.png) · [Dark](after/notifications-dark.png) |
| S26 | Offers | [Light](after/offers-light.png) · [Dark](after/offers-dark.png) |
| S27 | No offers | [Light](after/offers-empty-light.png) · [Dark](after/offers-empty-dark.png) |
| S28 | Offer load failure | [Light](after/offers-offline-light.png) · [Dark](after/offers-offline-dark.png) |
| S29 | Account | [Light](after/account-light.png) · [Dark](after/account-dark.png) |
| S30 | Edit profile | [Light](after/edit-profile-light.png) · [Dark](after/edit-profile-dark.png) |
| S31 | Help and support | [Light](after/help-light.png) · [Dark](after/help-dark.png) |
| S32 | Terms of service | [Light](after/legal-terms-light.png) · [Dark](after/legal-terms-dark.png) |
| S33 | Privacy policy | [Light](after/legal-privacy-light.png) · [Dark](after/legal-privacy-dark.png) |
| S34 | Cancellation and refunds | [Light](after/legal-cancellation-light.png) · [Dark](after/legal-cancellation-dark.png) |
| S35 | Notification permission | [Light](after/notification-permission-light.png) · [Dark](after/notification-permission-dark.png) |
| S36 | Offline and server unavailable | [Light](after/unavailable-light.png) · [Dark](after/unavailable-dark.png) |
| S37 | Force update | [Light](after/update-light.png) · [Dark](after/update-dark.png) |
| S38 | Account paused | [Light](after/paused-light.png) · [Dark](after/paused-dark.png) |
| S39 | Offline over saved content | [Light](after/offline-banner-light.png) · [Dark](after/offline-banner-dark.png) |
| S40 | Address switcher | [Light](after/address-picker-light.png) · [Dark](after/address-picker-dark.png) |
| S41 | Apply promo code | [Light](after/promo-sheet-light.png) · [Dark](after/promo-sheet-dark.png) |
| S42 | Change delivery time | [Light](after/delivery-sheet-light.png) · [Dark](after/delivery-sheet-dark.png) |
| S43 | Pay amount due | [Light](after/pay-due-sheet-light.png) · [Dark](after/pay-due-sheet-dark.png) |
| S44 | Cancel order | [Light](after/cancel-sheet-light.png) · [Dark](after/cancel-sheet-dark.png) |
| S45 | Log out confirmation | [Light](after/log-out-sheet-light.png) · [Dark](after/log-out-sheet-dark.png) |
| S46 | Delete account confirmation | [Light](after/delete-account-sheet-light.png) · [Dark](after/delete-account-sheet-dark.png) |
| S47 | Deletion blocked by active orders | [Light](after/delete-blocked-sheet-light.png) · [Dark](after/delete-blocked-sheet-dark.png) |

## Remaining release checks

Real Google Maps rendering and denied location on hardware; Firebase SMS/autofill; Razorpay native checkout and provider recovery; push/realtime delivery; external phone/email/store actions; Android native walkthrough/hardware; VoiceOver/TalkBack operation; actual OS keyboards on all forms at large text. Maps are disabled locally, so the fallback was verified. Profile and item-search keyboard invocation were inspected on iOS; all seven form families additionally pass simulated 300 dp keyboard-inset checks in both themes at 200% text. These layout, semantics and contrast checks do not certify native assistive-technology operation. The Android APK built and ran, but the computer-use tool could not bind the emulator window, so no Android visual walkthrough is claimed.

The customer v1 scope remains a phone app. No tablet navigation, admin redesign, website redesign, automatic refunds, new notification preferences or area-alert signup was introduced.
