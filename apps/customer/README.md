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

## Sign in with Google, and the mobile number

The welcome and mobile-number screens offer **Continue with Google**. A Google customer is signed up on the first use, with the
name and email from Google, and has **no mobile number yet**. They can browse, build a basket and pick times. The first time they
book (or from Account → Add mobile number) the app asks for a number, sends an SMS code, and links that verified number to the
same Firebase account (`linkWithCredential`). The API reads the verified `phone_number` from the refreshed ID token and stores
it; `POST /v1/orders` answers `PHONE_REQUIRED` until it is there, and `PHONE_IN_USE` if another customer already has the number.
Accounts are never merged by email: a Google sign-in is a new account unless that Firebase user already exists.

In dev mode (`AUTH_MODE=dev`) the Google button signs in as `dev.customer@example.com` (token `dev-google:<email>`, with
`dev-google:<email>:<phone>` once a number is added), so the whole flow works against a local API with `AUTH_DEV_BYPASS=true`.

The Google button shows a friendly message instead of opening Google until sign-in is set up for the build. To set it up:

1. **Firebase console** → project `irondost-app` → Authentication → Sign-in method → **Google** → Enable (pick a support email) → Save.
2. **iOS.** Project settings → Your apps → the iOS app (`com.irondost.customer`) → download the new `GoogleService-Info.plist` and replace
   `ios/Runner/GoogleService-Info.plist`; it now contains `CLIENT_ID` and `REVERSED_CLIENT_ID`. Then:
   - put the `CLIENT_ID` into the `ios` options in `lib/firebase_options.dart` as `iosClientId` (or run `flutterfire configure`);
     the app does not call Google on iOS until it is there;
   - in `ios/Runner/Info.plist` add a **second** entry to `CFBundleURLTypes` (keep the existing Firebase one) whose
     `CFBundleURLSchemes` holds the `REVERSED_CLIENT_ID` value. Without this scheme the Google SDK ends the app when sign-in starts.
3. **Android** (`com.cloudironingfactory.customer`). Add the SHA-1 and SHA-256 fingerprints of the debug key
   (`cd android && ./gradlew signingReport`), the upload key, and the **Play App Signing** key (Play Console → App integrity)
   under Project settings → Your apps → Android; then download the new `google-services.json` into `android/app/`. Its
   `oauth_client` entries make the Google Services plugin generate `default_web_client_id`, which Google sign-in uses.
4. Rebuild the app. Nothing changes on the API: it already accepts Firebase ID tokens from this project.

Apple's App Store rule 4.8 requires **Sign in with Apple** to be offered on iOS next to any other third-party sign-in. Add it
before the iOS release that ships Google login.

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

## Account

The Account tab shows who is signed in, saved addresses, notifications, Help and support, the three policies (Terms, Privacy, Cancellation
and refunds, drafted from the old app and kept in `features/account/legal_content.dart`), Log out and Delete account.

- **Edit profile** changes name and email. The mobile number signs the customer in, so it is read only.
- **Log out** stops this phone getting push and signs out.
- **Delete account** calls `DELETE /v1/me`, then signs this phone out. The API refuses with `ACTIVE_ORDERS` while orders are in
  progress; the sheet then says how many and leads to Orders. A failed deletion never signs the customer out.

## Release

See `docs/customer-app-release.md`: signing, production settings, store listing, privacy answers and the pre-submit checklist.
Store screenshots are in `store/`. A production build is `flutter build appbundle --release --dart-define-from-file=env/prod.json`
(Android) or `flutter build ipa --release --dart-define-from-file=env/prod.json` (iOS); start from `env/prod.example.json`.

## Offline

`lib/data/reachability.dart` learns from real requests whether the API can be reached: a connection failure or timeout means no,
any answer (even an error) means yes. While no, the tabs show "You're offline" above the tab bar with a Retry button, and when
the API answers again the catalogue, offers, notifications and orders reload by themselves. Screens that never loaded keep their own
"Couldn't load" state with Try again.

## Accessibility

`test/a11y/accessibility_test.dart` draws every screen in light and dark, at normal text and at 200%. At normal size it checks tap
targets (Android and iOS), labels and text contrast; at 200% it fails on any overflow. Keep new screens in that file. Layouts that
would not fit at large text change shape (the cart bar stacks, long values wrap, short sheets scroll) rather than clip.

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
