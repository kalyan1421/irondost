# Customer app release (Phase 6)

Status as of 3 Oct 2026. Phases 1–5 are built and pushed. This is what is left to put the IronDost customer app in the stores,
what I can do in the repo, and what only you can do.

## Status

| Step | State | Who |
|---|---|---|
| Launcher icons (adaptive and monochrome on Android, 1024 on iOS) | Done in Phase 1, checked | n/a |
| Native splash screens, light and dark | Done, checked on the iOS simulator and an Android 16 emulator | n/a |
| Android release signing | Wired to `android/key.properties`; needs your upload keystore | you |
| Release builds | `flutter build appbundle --release` builds (debug-signed until the keystore is added) | n/a |
| iOS signing, App ID and APNs key | Needs you | you |
| Production config (API URL, Maps release key, Razorpay live) | Needs you | you |
| Store listing copy | Drafted below | you review |
| App Privacy and Data safety answers | Drafted below; iOS privacy manifest added | you review |
| Privacy policy and account-deletion web pages | Needs the marketing site | me, after the site |
| Store screenshots | Captured: 7 per platform in `apps/customer/store/` | you review |
| Play internal testing, TestFlight | Needs the steps above | you upload, I prepare builds |

## Done in Phase 6 so far

- **Native splash.** The IronDost logo with its tagline on the app's surface colour, white or dark navy to match the phone's
  setting, at the same size as the app's own launch screen so nothing jumps. iOS uses `LaunchBackground.colorset` and a
  light and dark `LaunchImage`; Android uses `launch_background.xml` plus a `values-v31` theme for Android 12 and later
  (those versions draw the app icon on the same colour instead of the logo, which is how Android's own splash works).
- **Android release.** Signing reads `android/key.properties` (template in `key.properties.example`; the real file and any
  `.jks` are already gitignored) and falls back to the debug key when it is missing. The manifest asks for
  `POST_NOTIFICATIONS` (Android 13+) and locks the phone to portrait. The merged release manifest has no cleartext traffic.
- **iOS release.** iPhone only and portrait only (no iPad build to review), `ITSAppUsesNonExemptEncryption` is false so uploads
  skip the export-compliance question, and `Runner/PrivacyInfo.xcprivacy` declares no tracking, the data the app collects and
  its use of `UserDefaults`.
- **Bug found while preparing screenshots:** a returning customer who signed in briefly saw the address-setup screen and the system
  location prompt before Home, because the address list still held its empty signed-out value while it reloaded. The redirect now
  waits for the real list (with a regression test).
- **Android emulator run.** The Android debug build was run end to end on a Pixel 9 emulator for the first time: sign-in, catalogue,
  basket, pickup time, order tracking and offers all work. Push and Razorpay on Android are still untested.

## Screenshots

`apps/customer/store/ios/` is 1320 × 2868 (iPhone 6.9"), `apps/customer/store/android/` is 1080 × 2424 (Pixel 9). Both are
01 Welcome, 02 Home, 03 Choose items, 04 Basket, 05 Pickup time, 06 Order tracking, 07 Offers. They are plain screenshots in light mode
with a 9:41 status bar and demo data (customer "Priya Sharma"; the order shows "Paid online" because a cash payment was recorded
on a dev order). The stores allow a caption and frame around each; that is a design decision for you.

## 1. Identity and versions

- Android application ID stays `com.cloudironingfactory.customer`, so this ships as an update to the live listing.
- iOS bundle ID is `com.irondost.customer`, Apple team `AQLMTLP6PD`.
- App version is `2.0.0+100` (versionName 2.0.0, versionCode 100). The versionCode must be higher than the highest code already
  uploaded for the live app. Check Play Console → App bundle explorer; if the live app is above 100, raise the `+100`.
- The app is called IronDost; the store listing for the live app will change its name when this update goes out.

## 2. Icons and splash

- Source art is in `packages/brand` (washer and iron mark, white icon background). The icons were generated in Phase 1 with
  `flutter_launcher_icons` and checked: iOS has the 1024 px opaque icon, Android has an adaptive icon with a monochrome layer.
- The splash screens are covered under "Done in Phase 6 so far".

## 3. Signing

**Android.** Release builds are signed with the upload key in `android/key.properties` when that file exists, and with the debug key
when it does not (fine for a local test, rejected by Play). I need from you one of:

- the existing upload keystore and its passwords for `com.cloudironingfactory.customer`, or
- if Play App Signing is on and the upload key is lost, a new upload key registered through Play Console → App integrity.

Do not paste keystore passwords into chat; put them in `android/key.properties` yourself.

**iOS.** Open `apps/customer/ios/Runner.xcworkspace`, set the team to `AQLMTLP6PD`, keep automatic signing, and let Xcode create the
App ID `com.irondost.customer` with Push Notifications. Then upload an APNs auth key (.p8) in Firebase console →
Project settings → Cloud Messaging for `irondost-app`. The team already has two keys (Apple's limit), so reuse an existing
`.p8` rather than creating a new one.

## 4. Production configuration

| Setting | Value / action |
|---|---|
| `API_BASE_URL`, `AUTH_MODE`, `FLAVOR` | Copy `env/prod.example.json` to `env/prod.json`, put the deployed API's HTTPS URL in it, and pass it with `--dart-define-from-file=env/prod.json` |
| Google Maps (Android) | Add the Play App Signing SHA-1 (Play Console → App integrity) to the Android Maps key |
| Google Maps (iOS) | Key is restricted to `com.irondost.customer`; nothing more to do |
| Firebase Phone sign-in (Android) | Add release SHA-1 and SHA-256 to the Android app in `irondost-app` |
| Razorpay | Swap the test key for the live key id in the API's environment, set `RAZORPAY_WEBHOOK_SECRET`, and add the webhook in the Razorpay dashboard |
| Test phone number for store review | Firebase console → Authentication → Phone → add a test number with a fixed code, and give it to Apple and Google reviewers |

The API has to be deployed and reachable on HTTPS before the first store build can be tested end to end. That is the main open
decision: where to host it (Postgres, the API process and the pg-boss worker).

## 5. Store listing draft

**Name:** IronDost: Laundry & Ironing
**Subtitle (iOS, 30):** Pickup and delivery in a day
**Short description (Play, 80):** Book ironing, wash and dry cleaning. We pick up and deliver to your door.
**Category:** Lifestyle (Play: Lifestyle; App Store primary: Lifestyle, secondary: Shopping).
**Keywords (iOS, 100):** laundry,ironing,dry clean,wash,pickup,delivery,clothes,Hyderabad,press,steam iron

**Full description:**

> IronDost collects your clothes, cleans or irons them, and brings them back to your door.
>
> • Choose ironing, wash and iron, or dry cleaning, with prices shown before you book.
> • Pick the pickup and delivery times that suit you.
> • Pay online with UPI, cards or netbanking, or pay cash when your clothes arrive.
> • Follow your order from pickup to delivery and get a notification at each step.
> • Apply offers and promo codes in your basket.
> • Cancel before pickup, or call us from the app if something is wrong.
>
> Available in Hyderabad. Sign in with your mobile number; we send a one-time code by SMS.

**What's new (2.0.0):** A new, faster IronDost: easier booking, live order tracking, online payment and offers.

Check that "Available in Hyderabad" is still true when you submit (service area is set in admin).

## 6. Privacy answers (draft, please review)

IronDost has no analytics, advertising or crash-reporting SDK in the app as far as I built it. Firebase is used only for phone sign-in and
push notifications. Payments are handled by Razorpay's checkout, so card and UPI details never reach IronDost.

| Data | Collected | Linked to the user | Purpose | Shared |
|---|---|---|---|---|
| Phone number | Yes | Yes | Account and sign-in, order updates | Firebase (SMS verification) |
| Name | Yes | Yes | Account, so the partner can address the customer | No |
| Email (optional) | Yes | Yes | Receipts | No |
| Physical address | Yes | Yes | Pickup and delivery | Delivery partner for that order |
| Precise location | Only while choosing a pickup address on the map | Saved with the address | Pickup address | No |
| Order history and amounts | Yes | Yes | Service, support, receipts | No |
| Purchases / payment info | Not collected by IronDost | n/a | Handled by Razorpay | Razorpay |
| Device or push token | Yes | Yes | Push notifications | Firebase (FCM, APNs) |
| Photos, contacts, health, browsing, search history, advertising ID | No | n/a | n/a | n/a |

- **Encrypted in transit:** yes (HTTPS only in production).
- **Account and data deletion:** in the app (Account → Delete account). Past orders stay without the customer's details.
  Play also asks for a web page where deletion can be requested, so the marketing site needs a `/delete-account` page.
- **Tracking (Apple):** no. **Data used to track you:** none.
- **Apple privacy manifest:** the iOS project must declare the required-reason APIs its plugins use (shared preferences uses
  `UserDefaults`). Check `ios/Runner/PrivacyInfo.xcprivacy` and the plugins' manifests before archiving.
- **Permissions in the Android manifest** that come from the Razorpay SDK rather than IronDost's own code: `NFC`,
  `READ_BASIC_PHONE_STATE`, `ACCESS_NETWORK_STATE`, `VIBRATE`, `WAKE_LOCK`. Razorpay's checkout also collects payment and device
  details itself, so check Razorpay's own data-safety guidance before submitting the Play Data safety form.
- **Permissions shown to the user:** location (when using the map pin or "use my location"), notifications (asked after the
  first booking, not at launch).
- **Privacy policy URL:** needed by both stores. The in-app text exists but both stores need a public web page, so this waits on the
  marketing site. The text is drafted from the old app's policy and needs the business to review it.

## 7. Store screenshots

| Store | Sizes | Count |
|---|---|---|
| App Store | 6.9" iPhone (1320×2868); 6.5" is optional if 6.9" is supplied | 3–10 |
| Play | Phone, 16:9 to 9:16, at least 1080 px on the short side | 2–8 |

Planned set, taken from the real app with dev data, light mode: Home, Choose items, Basket, Pickup time, Order tracking, Offers.
Each is captured from the iOS simulator and the Android emulator, with a one-line caption on a brand-colour background.

## 8. Test tracks

1. **Play internal testing:** `flutter build appbundle --release --dart-define-from-file=env/prod.json` (needs `android/key.properties`), upload the `.aab` in
   Play Console → Internal testing, add testers by email.
2. **TestFlight:** `flutter build ipa --release --dart-define-from-file=env/prod.json`, then upload with Xcode Organizer or Transporter.
   Add internal testers; external testers need a short Beta App Review.
3. Both need the production API and the steps in sections 3 and 4.

## 9. Before submitting

- [ ] TalkBack on an Android phone and VoiceOver on an iPhone, through booking, tracking and Account.
- [ ] Policy text reviewed by the business; privacy policy and deletion pages live on the web.
- [ ] A real push arrives on a physical iPhone (needs the APNs key) and on an Android phone.
- [ ] A live-mode Razorpay payment of a small amount, refunded afterwards.
- [ ] Release SHA-1 on the Android Maps key; map tiles show in the release build.
- [ ] Sign in works with the Firebase test phone number the reviewers will use.
- [ ] Fresh-install run on both platforms: sign in, add an address, book, pay, track, cancel, delete the account.
