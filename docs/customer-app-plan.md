# IronDost customer app: plan

The Flutter app customers use to book ironing, wash and dry-cleaning pickups, pay, and track orders. It talks only to the NestJS API (`apps/api`). Firebase is used for phone OTP and push notifications, and nothing else.

- **Design system:** [IronDost design system](https://claude.ai/artifact/3TxmJdVqHnomwZHFxMu9bR) (tokens, components, copy rules, order-status vocabulary).
- **Screen designs:** [IronDost customer app canvas](https://claude.ai/artifact/Tt5QkcQxS1hRmbdsbAdWc7) (24 phone screens, clickable).
- **API contract:** `packages/contracts/openapi.json`.

## Scope of v1

**In:**
- Phone OTP sign-in, profile, addresses with a map pin.
- Catalogue (Ironing, Wash & iron, Dry cleaning), basket with server quote and promo codes.
- Pickup and delivery slots, checkout, and payment by Razorpay or cash on delivery.
- Order list, live tracking timeline, paying an amount that is due, and cancelling before pickup.
- Notification inbox and push, offers, account, legal pages, account deletion, force update.
- Light and dark themes; English.

**Out of v1:**
- Ratings and reviews, wallet or referrals, subscriptions, chat.
- Hindi and Telugu (the type system is ready for them).
- Tablet layouts.

## App identity

| | Value |
|---|---|
| Location | `apps/customer` (Dart package `irondost_customer`; pnpm and Turbo ignore it because it has no `package.json`) |
| Android applicationId | `com.cloudironingfactory.customer` (the existing Play listing, updated in place) |
| iOS bundle ID | `com.irondost.customer`, team `AQLMTLP6PD` |
| Firebase project | `irondost-app` (IronDost): phone OTP and FCM only |
| Display name | IronDost |
| Toolchain | Flutter 3.47 stable, Dart 3.13, Xcode 26.6 (as installed) |
| Flavours | `dev` (local API, `AUTH_DEV_BYPASS`), `staging`, `prod`; each with its own API base URL and its own Firebase app in `irondost-app` |

## Information architecture

Bottom navigation has four tabs, and each tab keeps its own back stack (`StatefulShellRoute`):

- **Home:** address switcher, book-a-pickup hero, active order, services, offer.
- **Orders:** active and past orders, then order details and tracking.
- **Offers:** promotions from `GET /v1/promotions`.
- **Account:** profile, addresses, notifications, help, legal, log out, delete account.

Full-screen flows sit above the tabs:
- Sign-in: welcome → phone → OTP → name → map pin → address.
- Booking: catalogue → basket → slot → checkout → confirmation.
- Pay-due sheet and the force-update gate.

**Deep links** (push taps and shared links), for example `irondost://orders/{id}`, plus https links once the web domain is chosen:
- `/orders/:id`
- `/offers`
- `/notifications`

## Screens and the API behind them

| Screen | Design artboard | API |
|---|---|---|
| Welcome | Welcome | none |
| Phone, OTP | Login, Otp | Firebase `verifyPhoneNumber`, then `POST /v1/auth/session {app: CUSTOMER}` |
| Name | Profile | `PATCH /v1/me` (shown while `isProfileComplete` is false) |
| Map pin, address details | MapPin, AddressForm, OutOfArea | Google Maps and Places on device, `GET /v1/service-area/check` as the pin moves, then `POST /v1/me/addresses` (the response's `serviceable` drives the not-in-your-area state) |
| Home | Main | `GET /v1/me/addresses`, `GET /v1/orders`, `GET /v1/catalog`, `GET /v1/banners`, `GET /v1/promotions` |
| Catalogue | Catalogue | `GET /v1/catalog` (cached; prices use `effectivePricePaise`) |
| Basket | Cart | `POST /v1/orders/quote` on every change (debounced 300 ms); shows `promoError`, `minOrderShortfallPaise` |
| Pickup time | Schedule | `GET /v1/schedule/pickup-slots`, `GET /v1/schedule/delivery-slots` |
| Checkout, confirmation | Checkout, Confirmed | `POST /v1/orders` with an `Idempotency-Key` (one UUID per checkout attempt, reused on retry); for online payment `POST /v1/orders/{id}/payments/razorpay`, then Razorpay Checkout, then `POST /v1/payments/razorpay/verify` |
| Orders | Orders, EmptyOrders, OrdersPast | `GET /v1/orders?scope=active` and `?scope=past` |
| Tracking | Track | `GET /v1/orders/{id}` plus the Socket.IO `order.updated` event at `/v1/realtime`; `POST /v1/orders/{id}/cancel` before pickup |
| Pay due | PayDue | same Razorpay calls as checkout, for `amountDuePaise` |
| Notifications | Notifications | `GET /v1/me/notifications`, `POST …/{id}/read`, `POST …/read-all` |
| Offers | Offers | `GET /v1/promotions` |
| Account, addresses | Account, Addresses | `GET/PATCH /v1/me`, address CRUD |
| Delete account | DeleteAccount | `DELETE /v1/me`, then Firebase sign-out |
| Force update | Update | `GET /v1/app-versions?app=CUSTOMER&platform=…` at launch |
| Push | none | `POST /v1/me/devices` after sign-in and on token refresh; `POST /v1/me/devices/remove` on log-out |

### States designed (64 artboards in all)

| Area | Screens |
|---|---|
| App-wide | Launch screen, home skeleton loading, no internet (full screen and as a banner over saved data), server unavailable (503), something went wrong (500), inline load failure, account paused (`CUSTOMER_INACTIVE`), notification permission, force update |
| Sign-in and addresses | Invalid number, wrong OTP, too many OTP tries, location permission off (search instead), outside service area (`serviceable: false`), address switcher |
| Booking | Search with no results, empty basket, expired code with a minimum-order shortfall, apply-a-code sheet, no pickup slots left today, delivery slot sheet, slot closed at checkout (`PICKUP_SLOT_CLOSED`), payment confirming, payment failed |
| Orders | Past orders, booked and finding a partner, pickup running late (`dispatchFailedAt`), cancel sheet, out for delivery, delivered, cancelled with refund, items and bill, payment received, no orders yet |
| Account | Edit profile, help and support, cancellation and refunds policy, log out, delete account, delete blocked by active orders (`ACTIVE_ORDERS`), no notifications, no offers |

## Architecture

```
apps/customer/lib/
  app/            router (go_router), app shell, flavour config, theme
  design/         tokens.g.dart (generated from tokens.json) + IronDost widgets
                  (Button, OtpInput, QuantityStepper, SlotPicker, StatusChip,
                   OrderTimeline, OrderCard, AddressCard, PromoCard, PriceSummary, CartBar…)
  data/           api client (generated from openapi.json), repositories, DTO mappers
  features/       auth, onboarding, home, catalogue, basket, checkout, orders,
                  tracking, notifications, offers, account   (screen + controller per folder)
  core/           money (paise ↔ "₹1,250"), IST date/slot formatting, errors, analytics
```

- **State:** Riverpod 3 (`flutter_riverpod`). Basket state is a notifier persisted to disk, so an app kill doesn't lose it.
- **Routing:** `go_router` with an auth redirect (no session → Welcome; profile incomplete → Name; no address → Map pin) and the force-update gate.
- **API client:** `dio` plus a client generated from `packages/contracts/openapi.json` (`swagger_parser` → `retrofit` + `freezed`), regenerated by one script after `pnpm openapi`. An interceptor adds the Firebase ID token and refreshes it once on a 401.
- **Auth:** `firebase_auth` phone sign-in (Android SMS auto-retrieval; iOS silent APNs verification, reCAPTCHA as fallback). Dev builds can sign in with `dev:<phone>` tokens against a local API.
- **Realtime:** `socket_io_client` with the ID token in `auth`, connected while the app is in the foreground; `order.updated` invalidates that order's provider.
- **Push:** `firebase_messaging` plus `flutter_local_notifications`, with an Android channel per type (order updates, offers). A tap opens the deep link.
- **Maps:** `google_maps_flutter`, `geolocator`, and Places Autocomplete (HTTP, key restricted to the app).
- **Payments:**
  - `razorpay_flutter`. The server creates the Razorpay order and verifies the signature; the app never decides that a payment succeeded.
  - If verification is still pending when the app returns, the order shows "Payment processing" until the webhook settles it.
- **Theme:**
  - `design/tokens.g.dart` is generated from the design system's `tokens.json`: light and dark `ColorScheme`s, plus a `ThemeExtension` for `success`, `warning`, `offer`, `surface-soft` and the rest.
  - Fonts (Outfit, Figtree, Geist Mono) are bundled as assets rather than fetched at runtime.
  - Icons come from `lucide_icons_flutter`.
- **Quality bar (from the design system):**
  - Touch targets of at least 48 dp; text contrast of at least 4.5:1 in both themes.
  - Dynamic type up to 200% without truncating prices or buttons.
  - `Semantics` on steppers, slots and the timeline; reduced-motion respected.
  - Skeletons instead of spinners for anything longer than 300 ms.
- **Errors and offline:**
  - Each screen has loading, empty, error and offline states.
  - Retries are idempotent: order placement sends an idempotency key so a double tap or retry never creates two orders. This needs a small API addition.
- **Testing:**
  - Widget tests for each design-system widget.
  - Golden tests for the key screens in both themes.
  - An `integration_test` of the full booking flow against the local API with dev auth.

## Build phases

Each phase ends with something runnable on a simulator and a device.

1. **Foundation** (built 2 Oct 2026; see `apps/customer/README.md`):
   - Project, flavours and Firebase apps.
   - Generated tokens and theme; IronDost widgets with golden tests.
   - Router shell with the four tabs; generated API client; OTP sign-in; session; device registration; force-update gate.
2. **Onboarding and addresses** (built 2 Oct 2026): name, map pin with Places search, address form, address book, and the Home header address switcher.
3. **Booking** (built 3 Oct 2026):
   - Catalogue tabs and search, persisted basket with live quote, and promo codes.
   - Pickup and delivery windows, checkout, placing the order (idempotent), Razorpay and cash on delivery, and the confirmation screen.
   - Payment states: confirming, failed (try again or cash at delivery), still confirming.
4. **Orders and tracking** (built 3 Oct 2026): order list (Active / Past, paged), details with the timeline and realtime updates,
   partner call, pay-due sheet and receipt, cancel before pickup, items and bill, "book the same again", notification inbox, the
   notification-permission prompt after the first booking, in-app push banners and tap-to-open deep links.
5. **Account and polish** (built 3 Oct 2026):
   - Offers (featured card, copy code, empty and error states), account, edit profile (mobile number locked), help and support,
     the three policies in the app, log out, and account deletion (blocked while orders are in progress).
   - Offline banner on the tabs (learned from real API calls) that reloads the data when the connection returns.
   - Accessibility pass: a test matrix draws every screen in light and dark at normal and 200% text and checks tap targets, labels and contrast.
     Still to do by hand before release: TalkBack on an Android phone and VoiceOver on an iPhone.
   - The policy text is drafted from the old app's policies and needs the business to review it before release.
6. **Release:**
   - Launcher icons and splash from `packages/brand`.
   - Store screenshots from the designs; App Privacy and Data safety forms.
   - Play internal testing as an update to the existing listing; TestFlight on team AQLMTLP6PD.

## Decisions and API status

**Decided:**
- iOS bundle ID `com.irondost.customer`; Android keeps `com.cloudironingfactory.customer`.
- Firebase project `irondost-app`.
- Support contact: +91 90632 90012 and kalyan91333@gmail.com. It's saved in settings, returned by `GET /v1/config`, and editable in the admin's Settings.

**Added to the API on 2 Oct 2026:**
- **Service area:**
  - A hub location plus radius, and/or a PIN-code allow-list, set in admin Settings.
  - `GET /v1/service-area/check` is public, so the website can use it too.
  - Addresses carry `serviceable` and `notServiceableReason`.
  - Customer orders to an unserved address fail with `ADDRESS_NOT_SERVICEABLE`. Staff phone orders are exempt.
- **Order list filter:** `GET /v1/orders?scope=active|past`.
- **Idempotent ordering:** the `Idempotency-Key` header on `POST /v1/orders`.
  - A retry returns the first order, with `Idempotent-Replayed: true`.
  - The same key with a different basket fails with `IDEMPOTENCY_KEY_REUSED`.
  - Two taps at once still create a single order.

- **Refunds (2 Oct 2026):**
  - Staff refund from the admin order page with a required note to the customer: Razorpay back to the original method, cash returned, or bank transfer/UPI sent manually.
  - Orders carry `refundedPaise` and `refunds[]` (amount, method, status, note).
  - The customer gets a notification when a refund starts, is processed or fails.
- **Service area:** Hyderabad, 25 km around 17.3850, 78.4867 (roughly inside the Outer Ring Road). Other cities can sign up and save addresses but can't book.

- **Pay on delivery (3 Oct 2026):** `POST /v1/orders/{id}/pay-on-delivery` turns an unpaid online order into cash on delivery after a failed or abandoned payment, so the partner collects it at the door. Refused once anything is paid.

- **Refund needed (3 Oct 2026):** when a paid order is cancelled, staff get a `refund_needed` notification. Nothing is refunded
  automatically; the admin Refund button does it, as decided earlier.

**Done since:** restricted Google Maps keys for iOS and Android; Razorpay test keys.

**Still needed:**
- The Android release SHA-1 on the Android Maps key, before a release build.
- Razorpay live keys, and the webhook secret (a dashboard webhook on a public URL).
- An APNs key for push on team AQLMTLP6PD.
- **Store listing:** keep the Play package `com.cloudironingfactory.customer`, so the IronDost update replaces the current app for existing installs. The listing name, description and screenshots change with it.
