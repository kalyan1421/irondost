# IronDost customer app

Flutter app for iOS (`com.irondost.customer`) and Android (`com.cloudironingfactory.customer`,
updating the existing Play listing). Plan, screens and API mapping: [docs/customer-app-plan.md](../../docs/customer-app-plan.md).

## Run it locally

1. Start the API (`pnpm --filter @laundry/api dev`); it must run with `AUTH_DEV_BYPASS=true`.
2. Run the app with dev sign-in, which skips Firebase SMS: any 6-digit code works, and `000000`
   behaves like a wrong code.

```bash
flutter run --dart-define-from-file=env/dev.json
```

On the Android emulator the API is at `10.0.2.2`:

```bash
flutter run --dart-define-from-file=env/dev-android.json
```

Real SMS codes through the `irondost-app` Firebase project need Phone sign-in enabled in the
Firebase console, and an API started with that project's service account
(`FIREBASE_SERVICE_ACCOUNT_BASE64`):

```bash
flutter run --dart-define-from-file=env/dev-firebase.json
```

| Setting | Meaning |
|---|---|
| `API_BASE_URL` | IronDost API, no trailing slash |
| `AUTH_MODE` | `firebase` (real SMS) or `dev` (`dev:<phone>` tokens) |
| `FLAVOR` | `dev`, `staging` or `prod` |

## Maps and location

Pickup addresses are chosen on a map with a fixed centre pin (Google Maps SDK). Search and "use my
current location" use the phone's own geocoder, so they need no key.

The map needs a Google Maps Platform key with **Maps SDK for iOS** and **Maps SDK for Android** enabled.
The auto-created Firebase keys in `GoogleService-Info.plist` / `google-services.json` are not Maps keys.

1. Put the iOS key in `ios/Flutter/Secrets.xcconfig` (see the `.example`) and the Android key in
   `android/secrets.properties`. Both files are gitignored.
2. Run with `--dart-define-from-file=env/dev-maps.json` (`MAPS_ENABLED=true`).

Without `MAPS_ENABLED` the pin screen shows search and current location only, and everything else works.

On the iOS simulator set a location first: `xcrun simctl location booted set 17.4126,78.4482`.

## Booking

Home → catalogue (one tab per service, search) → basket (server quote, promo codes) → pickup and delivery
time → checkout → confirmation. The basket is saved on the phone (`shared_preferences`), prices and totals
always come from the API (`POST /v1/orders/quote`), and placing an order sends an `Idempotency-Key`, so a retry
after a timeout can never become a second order.

Orders are only taken from an address inside the service area; Home blocks the Book button otherwise.

## Online payments (Razorpay)

Choosing "Pay online" places the order, then opens Razorpay Checkout (`razorpay_flutter`). The server creates the
Razorpay order and checks the signature the SDK returns; the app never decides a payment succeeded. If the answer
to the check is lost, the app asks for the order until the webhook has marked it paid, and says "We're still
confirming" rather than asking the customer to pay twice. After a failed payment the customer can try again or
switch the order to cash on delivery (`POST /v1/orders/{id}/pay-on-delivery`).

Test mode needs `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` (a `rzp_test_` pair) in `apps/api/.env`. In Razorpay's
test window use card `4100 2800 0000 1007`, any CVV, expiry 12/26 (the demo bank page then lets you choose
Success or Failure), or UPI `test@razorpay`. The webhook (`RAZORPAY_WEBHOOK_SECRET`) needs a dashboard webhook
pointing at `/v1/webhooks/razorpay` on a public URL; without it, payments are still confirmed by the app's own check.

## Orders, tracking and notifications

- **Orders tab:** Active / Past, a page at a time. An order opens to its status, a five-step timeline, the partner (with a call button),
  what is owed and the bill. `order.updated` over Socket.IO (`/v1/realtime`, only while the app is on screen) refreshes the open order,
  the lists and the inbox, so a status change shows up without pulling to refresh.
- **Cancel** is offered until the clothes are picked up. **Pay what's due** opens the same Razorpay flow in "due" mode and ends on a
  receipt. Cancelling a paid order does not refund by itself: staff refund from the admin order page, and are notified (`refund_needed`).
- **Notifications:** the bell on Home opens the inbox (`GET /v1/me/notifications`). After the first booking the app explains why it wants
  to send notifications, then shows the system prompt. A push that arrives while the app is open is a banner; tapping one opens its order.
  Android channels (`order_updates`, `offers`) are created at start.

To try live updates locally, move an order along as staff with the dev admin token (`dev:+919000000000`):
`POST /v1/admin/orders/{id}/assign` (leg `PICKUP`, a driver id), then `POST /v1/admin/orders/{id}/status`
(`PICKED_UP`, `PROCESSING`, `READY_FOR_DELIVERY`, …).

On the iOS simulator a push can be tried with `xcrun simctl push booted com.irondost.customer payload.json`
(include `"gcm.message_id"` and `orderId`/`type` fields next to `aps`).

## Push notifications (iOS)

`ios/Runner/Runner.entitlements` enables push. For a device or App Store build you also need:

- an App ID `com.irondost.customer` with Push Notifications enabled (Xcode creates it with automatic signing),
- an APNs auth key (.p8) uploaded in Firebase console → Project settings → Cloud Messaging → `irondost-app`.

## Code layout

```
lib/
  app/       env, routes, redirect rules (pure, unit-tested), router, MaterialApp
  design/    tokens.g.dart (generated), theme.dart, widgets/ (IdButton, IdTextField, OtpInput, StateView, StatusChip, cards)
  data/      api/ (generated client), api_client.dart (Dio + auth), api_failure.dart
  core/      phone, money, version, order status copy
  features/  auth, startup, system screens, shell, home, addresses, catalogue, basket, schedule, checkout,
             payment, orders, notifications, realtime, offers, account, push, support
```

## Generated code

| What | Source | Command |
|---|---|---|
| API client `lib/data/api` | `packages/contracts/openapi.json` (run `pnpm openapi` in `apps/api` first) | `dart run swagger_parser && dart run build_runner build -d` |
| Design tokens `lib/design/tokens.g.dart` | `packages/design-tokens/tokens.json` | `dart run tool/gen_tokens.dart` |
| Launcher icons | `packages/brand/icons` | `dart run flutter_launcher_icons` |
| Firebase options | `irondost-app` project | `flutterfire configure --project=irondost-app` |

## Checks

```bash
flutter analyze
```

```bash
flutter test
```
